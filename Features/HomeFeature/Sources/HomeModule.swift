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
    public let tabItem = TabItem(title: "Beranda", systemImage: "house", selectedSystemImage: "house.fill")
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
}

@MainActor
public final class MenuModule: TabFeature {
    public let tabItem = TabItem(title: "Menu", systemImage: "menucard", selectedSystemImage: "menucard.fill")
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

/// State bersama katalog (repository + keranjang) milik Beranda & Menu.
@MainActor
public enum CatalogSession {
    /// Kosongkan keranjang & buat ulang repository (mis. setelah ganti server dari Debugger).
    /// Panggil sebelum tab bar dibuat ulang, karena screen yang sudah tampil masih memegang instance lama.
    public static func reset() {
        CatalogContainer.reset()
    }
}

/// Navigasi dari feature katalog ke fitur lain. Ditangani AppRouter (mis. pindah ke tab Profil).
public enum CatalogExternalRoute {
    /// Keranjang → tambah / kelola alamat pengiriman.
    case manageAddresses
    /// Keranjang → tautkan / kelola metode pembayaran.
    case managePaymentMethods
}
