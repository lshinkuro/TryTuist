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
}

struct MenuContent: Equatable {
    let categories: [MenuCategory]
    let products: [Product]
}

/// Beranda: banner, kategori, best seller (terlaris), dan rekomendasi (rating tertinggi).
struct GetHomeContentUseCase {
    let repository: CatalogRepository

    func execute() async throws -> HomeContent {
        async let banners = repository.fetchBanners()
        async let categories = repository.fetchCategories()
        async let products = repository.fetchProducts()

        let available = try await products.filter(\.isAvailable)
        return try await HomeContent(
            banners: banners,
            categories: categories,
            bestSellers: Array(available.sorted { $0.soldCount > $1.soldCount }.prefix(6)),
            recommended: Array(available.sorted { $0.rating > $1.rating }.prefix(5)),
            deals: Array(available.filter(\.isOnDeal).sorted { $0.discountPercent > $1.discountPercent }.prefix(6))
        )
    }
}

/// Popup promo Beranda. Tidak ditampilkan bila sudah ditutup hari ini, produknya habis,
/// atau promonya sudah lewat. Gagal memuat = tidak ada popup (bukan error di layar).
struct GetPromoPopupUseCase {
    let repository: CatalogRepository
    let dismissals: PromoPopupDismissalStore
    var now: () -> Date = Date.init

    func execute() async -> PromoPopup? {
        guard let popup = try? await repository.fetchPromoPopup() else { return nil }
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

/// Tab Menu: semua kategori & produk.
struct GetMenuUseCase {
    let repository: CatalogRepository

    func execute() async throws -> MenuContent {
        async let categories = repository.fetchCategories()
        async let products = repository.fetchProducts()
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
