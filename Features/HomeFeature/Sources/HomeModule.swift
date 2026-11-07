//
//  HomeModule.swift
//  HomeFeature
//
//  Feature katalog F&B punya dua pintu masuk (tab): Beranda & Menu.
//  Keduanya berbagi CatalogContainer (repository + keranjang) dan CatalogFlow (routing).
//
import SwiftUI
import Navigation

@MainActor
public final class HomeModule: TabFeature {
    public let tabItem = TabItem(title: String(localized: "Beranda"), systemImage: "house", selectedSystemImage: "house.fill")
    private var flow: CatalogFlow?
    private let onExternalRoute: (CatalogExternalRoute) -> Void

    /// - Parameter onExternalRoute: dari Keranjang ke fitur lain (mis. tambah alamat di tab Profil).
    public init(onExternalRoute: @escaping (CatalogExternalRoute) -> Void = { _ in }) {
        self.onExternalRoute = onExternalRoute
    }

    public func start(router: Router) {
        let flow = CatalogFlow(router: router, onExternalRoute: onExternalRoute)
        self.flow = flow
        router.setRoot(flow.makeHome(), hidesNavigationBar: true, lightStatusBar: true)
    }

    /// Buka Keranjang dari luar feature (shortcut Debugger).
    public func openCart() {
        flow?.openCart()
    }

    /// "Pesan Lagi" dari tab Pesanan: isi keranjang lalu buka Keranjang.
    public func reorder(_ items: [CatalogReorderItem]) {
        flow?.reorder(items)
    }

    /// Siri / Shortcuts: tambah produk ke keranjang lalu buka Keranjang.
    public func addToCart(productID: String, name: String, quantity: Int) {
        flow?.reorder([CatalogReorderItem(productID: productID, optionID: nil, name: name, quantity: quantity, note: "")])
    }

    /// Visual Intelligence / Shortcuts: buka detail produk.
    public func openProduct(id: String) {
        flow?.openProduct(id: id)
    }
}

/// Kunci `userInfo` notifikasi lokal katalog, dibaca AppDelegate saat notifikasi di-tap.
public enum CatalogNotifications {
    /// Pengingat beli ulang → buka detail produk ini.
    public static let restockProductIDKey = "restockProductID"
}

/// Produk ringkas untuk App Intents (Siri, Shortcuts, Visual Intelligence) di target App.
public struct CatalogProductSummary {
    public let id: String
    public let name: String
    public let price: Decimal
    public let imageURL: URL?
}

/// Pencarian katalog untuk App Intents. Stok & harga mengikuti outlet terakhir yang dipilih.
@MainActor
public enum CatalogIntents {
    /// Produk yang namanya memuat salah satu `terms`; bila tidak ada dan Apple Intelligence
    /// tersedia, pakai pencarian AI (mis. label Visual Intelligence berbahasa Inggris: "rice").
    public static func search(_ terms: [String], limit: Int = 10) async -> [CatalogProductSummary] {
        let terms = terms.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !terms.isEmpty else { return [] }
        let products = await catalog()
        var matches = products.filter { product in terms.contains { product.name.localizedStandardContains($0) } }
        let smartSearch = CatalogContainer.shared.smartSearch
        if matches.isEmpty, smartSearch.isAvailable,
           let ids = await smartSearch.search(terms.joined(separator: ", "), in: products) {
            matches = ids.compactMap { id in products.first { $0.id == id } }
        }
        return matches.prefix(limit).map(summary)
    }

    public static func products(ids: [String]) async -> [CatalogProductSummary] {
        let products = await catalog()
        return ids.compactMap { id in products.first { $0.id == id } }.map(summary)
    }

    /// Produk terlaris, untuk saran Siri ("Tambah <produk> ke keranjang").
    public static func suggested(limit: Int = 50) async -> [CatalogProductSummary] {
        await catalog().filter(\.isAvailable).sorted { $0.soldCount > $1.soldCount }.prefix(limit).map(summary)
    }

    private static func catalog() async -> [Product] {
        let container = CatalogContainer.shared
        let storeID = container.outletSelection.selected?.id ?? container.outletSelection.savedOutletID
        return (try? await container.catalogRepository.fetchProducts(storeID: storeID)) ?? []
    }

    private static func summary(_ product: Product) -> CatalogProductSummary {
        CatalogProductSummary(id: product.id, name: product.name, price: product.price, imageURL: product.imageURL)
    }
}

@MainActor
public final class MenuModule: TabFeature {
    public let tabItem = TabItem(title: String(localized: "Belanja"), systemImage: "basket", selectedSystemImage: "basket.fill")
    private var flow: CatalogFlow?
    private let onExternalRoute: (CatalogExternalRoute) -> Void

    public init(onExternalRoute: @escaping (CatalogExternalRoute) -> Void = { _ in }) {
        self.onExternalRoute = onExternalRoute
    }

    public func start(router: Router) {
        let flow = CatalogFlow(router: router, onExternalRoute: onExternalRoute)
        self.flow = flow
        router.setRoot(flow.makeMenu(isRootScreen: true), hidesNavigationBar: true)
    }
}

/// Menu Favorit sebagai pintu masuk dari feature lain (tab Profil). Keranjang tetap sama dengan Beranda.
@MainActor
public enum CatalogFavorites {
    public static func open(on router: Router) {
        router.push(CatalogFlow(router: router).makeFavorites(), title: String(localized: "Produk Favorit"))
    }
}

/// State bersama katalog (repository + keranjang) milik Beranda & Menu.
@MainActor
public enum CatalogSession {
    /// Kosongkan keranjang & buat ulang repository (mis. setelah ganti server dari Debugger).
    /// Panggil sebelum tab bar dibuat ulang, karena screen yang sudah tampil masih memegang instance lama.
    public static func reset() {
        CatalogContainer.reset()
    }

    /// Debugger: lunasi / tolak pembayaran online yang sedang menunggu tanpa membuka simulator
    /// Midtrans. Mengembalikan nomor pesanan bila lunas. Butuh backend `APP_ENV=dev` (atau mode mock).
    public static func simulatePendingPayment(_ outcome: PaymentSimulation) async throws -> String? {
        try await CatalogContainer.shared.simulatePayment.execute(outcome).order?.orderNumber
    }
}

/// Hasil pembayaran yang bisa disimulasikan dari Debugger.
public enum PaymentSimulation: CaseIterable {
    case paid, denied, expired, cancelled
}

/// Satu item pesanan lama untuk "Pesan Lagi" (dirakit AppRouter dari tab Pesanan).
public struct CatalogReorderItem {
    public let productID: String
    public let optionID: String?
    public let name: String
    public let quantity: Int
    public let note: String

    public init(productID: String, optionID: String?, name: String, quantity: Int, note: String) {
        self.productID = productID
        self.optionID = optionID
        self.name = name
        self.quantity = quantity
        self.note = note
    }
}

/// Navigasi dari feature katalog ke fitur lain. Ditangani AppRouter (mis. pindah ke tab Profil).
public enum CatalogExternalRoute {
    /// Keranjang → tambah / kelola alamat pengiriman.
    case manageAddresses
    /// Keranjang → tautkan / kelola metode pembayaran.
    case managePaymentMethods
}
