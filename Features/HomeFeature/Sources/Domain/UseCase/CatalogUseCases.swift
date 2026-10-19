//
//  CatalogUseCases.swift
//  HomeFeature · Domain
//
import Foundation

struct HomeContent: Equatable {
    let banners: [Banner]
    let categories: [MenuCategory]
    let bestSellers: [Product]
    let recommended: [Product]
    /// Produk yang sedang promo, potongan terbesar dulu.
    var deals: [Product] = []
    /// Outlet asal pesanan + daftar pilihan untuk picker "Dari: …".
    var outlet: OutletChoice = .empty
    /// "Antar ke": alamat tersimpan / lokasi saat ini.
    var delivery: DeliveryChoice = .empty
}

struct MenuContent: Equatable {
    let categories: [MenuCategory]
    let products: [Product]
}

/// Beranda: banner, kategori, best seller (terlaris), dan rekomendasi (rating tertinggi),
/// dengan stok mengikuti outlet yang dipilih.
struct GetHomeContentUseCase {
    let repository: CatalogRepository
    let resolveDelivery: ResolveDeliveryLocationUseCase
    let resolveOutlet: ResolveOutletUseCase

    func execute() async throws -> HomeContent {
        let delivery = await resolveDelivery.execute()
        let outlet = await resolveOutlet.execute(near: delivery.selected?.point)
        async let banners = repository.fetchBanners()
        async let categories = repository.fetchCategories()
        async let products = repository.fetchProducts(storeID: outlet.selected?.id)

        let available = try await products.filter(\.isAvailable)
        return try await HomeContent(
            banners: banners,
            categories: categories,
            bestSellers: Array(available.sorted { $0.soldCount > $1.soldCount }.prefix(6)),
            recommended: Array(available.sorted { $0.rating > $1.rating }.prefix(5)),
            deals: Array(available.filter(\.isOnDeal).sorted { $0.discountPercent > $1.discountPercent }.prefix(6)),
            outlet: outlet,
            delivery: delivery
        )
    }
}

/// Menentukan outlet yang dipakai: pilihan terakhir user bila masih aktif, selain itu
/// urutan teratas server (buka sekarang → menjangkau titik antar → terdekat).
/// Gagal memuat outlet bukan error: katalog tetap tampil dengan stok pusat.
@MainActor
struct ResolveOutletUseCase {
    let repository: CatalogRepository
    let selection: OutletSelectionRepository

    /// - Parameter point: titik "Antar ke" (alamat / lokasi saat ini). nil = urut jam buka saja.
    func execute(near point: GeoPoint?) async -> OutletChoice {
        guard let outlets = try? await repository.fetchOutlets(near: point), let first = outlets.first else {
            return OutletChoice(outlets: [], selected: selection.selected)
        }
        let chosen = outlets.first { $0.id == selection.savedOutletID } ?? first
        selection.select(chosen)
        return OutletChoice(outlets: outlets, selected: chosen)
    }
}

/// Ganti outlet. Harga sama di semua outlet, jadi keranjang dipertahankan —
/// kecuali menu yang habis di outlet baru, yang dikeluarkan (namanya dikembalikan untuk toast).
@MainActor
struct ChangeOutletUseCase {
    let repository: CatalogRepository
    let cart: CartRepository
    let selection: OutletSelectionRepository

    func execute(_ outlet: Outlet) async throws -> [String] {
        // Ambil stok dulu: bila gagal, outlet lama tetap dipakai.
        let products = try await repository.fetchProducts(storeID: outlet.id)
        selection.select(outlet)
        let available = Set(products.filter(\.isAvailable).map(\.id))
        let removed = await cart.removeProducts(notIn: available)
        var seen = Set<String>()
        return removed.map(\.product.name).filter { seen.insert($0).inserted }
    }
}

/// Satu produk di outlet yang sedang dipilih (mis. tujuan banner).
@MainActor
struct GetProductUseCase {
    let repository: CatalogRepository
    let outlets: OutletSelectionRepository

    func execute(id: String) async throws -> Product {
        try await repository.fetchProduct(id: id, storeID: outlets.selected?.id ?? outlets.savedOutletID)
    }
}

/// Popup promo Beranda. Tidak ditampilkan bila sudah ditutup hari ini, produknya habis,
/// atau promonya sudah lewat. Gagal memuat = tidak ada popup (bukan error di layar).
@MainActor
struct GetPromoPopupUseCase {
    let repository: CatalogRepository
    let dismissals: PromoPopupDismissalStore
    /// Promo bisa khusus outlet (§5.29).
    let outlets: OutletSelectionRepository
    var now: () -> Date = Date.init

    func execute() async -> PromoPopup? {
        let storeID = outlets.selected?.id ?? outlets.savedOutletID
        guard let popup = try? await repository.fetchPromoPopup(storeID: storeID) else { return nil }
        let today = now()
        guard popup.product.isAvailable, popup.product.isOnDeal,
              popup.endsAt.map({ $0 > today }) ?? true,
              !dismissals.isDismissed(promoID: popup.id, on: today) else {
            return nil
        }
        return popup
    }
}

/// Dipanggil saat popup ditutup ATAU di-tap: popup yang sama baru muncul lagi besok.
struct DismissPromoPopupUseCase {
    let dismissals: PromoPopupDismissalStore
    var now: () -> Date = Date.init

    func execute(_ popup: PromoPopup) {
        dismissals.markDismissed(promoID: popup.id, on: now())
    }
}

/// Tab Menu: semua kategori & produk, stok mengikuti outlet `storeID`.
struct GetMenuUseCase {
    let repository: CatalogRepository

    func execute(storeID: String?) async throws -> MenuContent {
        async let categories = repository.fetchCategories()
        async let products = repository.fetchProducts(storeID: storeID)
        return try await MenuContent(categories: categories, products: products)
    }
}

/// Aturan bisnis tambah ke keranjang.
struct AddToCartUseCase {
    let cart: CartRepository
    static let quantityRange = 1...20

    func execute(product: Product, option: ProductOption?, quantity: Int, note: String = "") async throws {
        guard product.isAvailable else { throw CartError.productUnavailable }
        guard Self.quantityRange.contains(quantity) else { throw CartError.invalidQuantity }
        let item = CartItem(product: product,
                            option: option ?? product.defaultOption,
                            quantity: quantity,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        try await cart.add(item)
    }
}

/// "Pesan Lagi": item pesanan lama masuk keranjang dengan harga & stok outlet yang dipilih sekarang.
/// Menu yang habis / sudah tidak dijual dilewati dan namanya dikembalikan untuk toast.
@MainActor
struct ReorderUseCase {
    let repository: CatalogRepository
    let selection: OutletSelectionRepository
    let addToCart: AddToCartUseCase

    func execute(_ items: [CatalogReorderItem]) async throws -> (added: Int, skipped: [String]) {
        let products = try await repository.fetchProducts(storeID: selection.selected?.id ?? selection.savedOutletID)
        var added = 0
        var skipped: [String] = []
        for item in items {
            guard let product = products.first(where: { $0.id == item.productID }), product.isAvailable else {
                skipped.append(item.name)
                continue
            }
            let option = product.options.first { $0.id == item.optionID }
            let quantity = min(max(item.quantity, 1), AddToCartUseCase.quantityRange.upperBound)
            try await addToCart.execute(product: product, option: option, quantity: quantity, note: item.note)
            added += 1
        }
        return (added, skipped)
    }
}

/// Menu Favorit (`/v1/me/favorites`) dengan harga & stok outlet yang dipilih. Butuh login.
@MainActor
struct GetFavoritesUseCase {
    let repository: CatalogRepository
    let outlets: OutletSelectionRepository

    func execute() async throws -> [Product] {
        try await repository.fetchFavorites(storeID: outlets.selected?.id ?? outlets.savedOutletID)
    }
}

struct SetFavoriteUseCase {
    let repository: CatalogRepository

    func execute(productID: String, isFavorite: Bool) async throws {
        try await repository.setFavorite(productID: productID, isFavorite: isFavorite)
    }
}
