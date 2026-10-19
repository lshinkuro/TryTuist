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
        router.setRoot(flow.makeHome(), hidesNavigationBar: true)
    }

    /// Buka Keranjang dari luar feature (shortcut Debugger).
    public func openCart() {
        flow?.openCart()
    }

    /// "Pesan Lagi" dari tab Pesanan: isi keranjang lalu buka Keranjang.
    public func reorder(_ items: [CatalogReorderItem]) {
        flow?.reorder(items)
    }
}

@MainActor
public final class MenuModule: TabFeature {
    public let tabItem = TabItem(title: String(localized: "Menu"), systemImage: "menucard", selectedSystemImage: "menucard.fill")
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
        router.push(CatalogFlow(router: router).makeFavorites(), title: String(localized: "Menu Favorit"))
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
