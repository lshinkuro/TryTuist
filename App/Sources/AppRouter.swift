//
//  AppRouter.swift
//  TryTuist
//
//  Routing level aplikasi: memilih flow Auth atau Main (tab bar) sebagai root window.
//  Semua perakitan feature ada di sini — tidak ada lagi *Dependency / *Coordinator.
//  Juga menyediakan shortcut navigasi untuk Debugger (shake device, non-Prod).
//
import UIKit
import SafariServices
import Navigation
import TTUI
import Utility
import Debugger
import AuthenticationFeature
import HomeFeature
import FocuseFeature
import ProfileFeature

@MainActor
final class AppRouter {
    private let window: UIWindow
    private var authModule: AuthenticationModule?
    private weak var tabBar: MainTabBarController?
    private weak var homeModule: HomeModule?
    private weak var profileModule: ProfileModule?
    /// AppRouter hidup selama app berjalan, jadi observer tidak perlu dilepas.
    private var sessionObserver: NSObjectProtocol?
    /// Cegah bottom sheet dobel saat beberapa request 401 bersamaan.
    private var isShowingSessionExpired = false

    /// Urutan tab di MainTabBarController.
    private enum MainTab: Int, CaseIterable {
        case home, menu, orders, profile

        var title: String {
            switch self {
            case .home: return String(localized: "Beranda")
            case .menu: return String(localized: "Menu")
            case .orders: return String(localized: "Pesanan")
            case .profile: return String(localized: "Profil")
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .menu: return "menucard.fill"
            case .orders: return "clock.arrow.circlepath"
            case .profile: return "person.fill"
            }
        }
    }

    init(window: UIWindow) {
        self.window = window
        window.tintColor = UIColor.brand
        configureDebugMenu()
        observeSessionExpired()
        PushRegistrar.shared.onOpenOrders = { [weak self] in self?.showTab(.orders) }
    }

    /// Dipanggil sekali saat app dibuka dari nol (cold start, mis. setelah di-kill).
    /// Kebijakan sesi: sesi tidak dibawa ke peluncuran berikutnya, jadi kill app = login ulang.
    /// Selama app masih berjalan (termasuk ke background lalu kembali), sesi tetap dan
    /// access token diperbarui otomatis oleh NetworkManager.
    func start() {
        PushRegistrar.shared.sessionEnded()
        TokenStorage.delete()
        showAuth(at: .splash)
    }

    // MARK: - Flows

    private func showAuth(at entry: AuthenticationModule.Entry) {
        let router = Router()
        let auth = AuthenticationModule(router: router) { [weak self] in
            self?.showMain()
        }
        authModule = auth
        auth.start(at: entry)
        setRoot(router.navigationController, animated: entry != .splash)
    }

    private func showMain(selecting tab: MainTab = .home) {
        authModule = nil
        let catalogRoute: (CatalogExternalRoute) -> Void = { [weak self] route in
            self?.handleCatalogRoute(route)
        }
        let home = HomeModule(onExternalRoute: catalogRoute)
        let profile = ProfileModule(onLogout: { [weak self] in
            PushRegistrar.shared.sessionEnded()
            self?.showAuth(at: .signIn)
        }, onOpenFavorites: { CatalogFavorites.open(on: $0) })
        let tabBar = MainTabBarController(features: [
            home,
            MenuModule(onExternalRoute: catalogRoute),
            FocusModule(onReorder: { [weak self] items in self?.reorder(items) }),
            profile
        ])
        // Dibuka dari tap notifikasi sebelum login → langsung ke Pesanan.
        tabBar.selectedIndex = PushRegistrar.shared.consumePendingOpenOrders() ? MainTab.orders.rawValue : tab.rawValue
        // tabBar menyimpan feature-nya, jadi referensi weak di sini cukup.
        self.tabBar = tabBar
        self.homeModule = home
        self.profileModule = profile
        setRoot(tabBar, animated: true)
        // Hanya user yang login yang didaftarkan (token sesi wajib).
        if TokenStorage.hasToken { PushRegistrar.shared.sessionStarted() }
    }

    /// Pindah tab; bila sedang di flow Auth, tab bar dibuat dulu (tanpa login).
    private func showTab(_ tab: MainTab) {
        guard let tabBar, window.rootViewController === tabBar else {
            showMain(selecting: tab)
            return
        }
        tabBar.selectedIndex = tab.rawValue
        (tabBar.selectedViewController as? UINavigationController)?.popToRootViewController(animated: false)
    }

    /// Keranjang → tab Profil (tambah alamat / tautkan e-wallet). Keranjang sudah ditutup oleh CatalogFlow.
    private func handleCatalogRoute(_ route: CatalogExternalRoute) {
        guard let tabBar, window.rootViewController === tabBar else { return }
        tabBar.selectedIndex = MainTab.profile.rawValue
        switch route {
        case .manageAddresses: profileModule?.open(.addresses)
        case .managePaymentMethods: profileModule?.open(.paymentMethods)
        }
    }

    /// Pesanan → "Pesan Lagi": pindah ke Beranda, isi keranjang, lalu buka Keranjang.
    private func reorder(_ items: [OrderReorderItem]) {
        showTab(.home)
        homeModule?.reorder(items.map {
            CatalogReorderItem(productID: $0.productID, optionID: $0.optionID, name: $0.name,
                               quantity: $0.quantity, note: $0.note)
        })
    }

    // MARK: - Sesi habis (401)

    private func observeSessionExpired() {
        sessionObserver = NotificationCenter.default.addObserver(forName: .sessionExpired,
                                                                 object: nil,
                                                                 queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleSessionExpired() }
        }
    }

    /// Bottom sheet "Sesi habis" → Mengerti → halaman Sign In.
    private func handleSessionExpired() {
        // Hanya relevan saat user di dalam app (bukan di flow login), dan cukup sekali.
        guard !isShowingSessionExpired,
              let tabBar, window.rootViewController === tabBar,
              let presenter = BottomSheetPresenter.topController(in: window) else { return }
        isShowingSessionExpired = true
        // Token sudah tidak berlaku: hapus sekarang supaya request lain tidak memakainya.
        PushRegistrar.shared.sessionEnded()
        TokenStorage.delete()

        BottomSheetPresenter.present(.sessionExpired { [weak self] in
            self?.goToSignInAfterSessionExpired()
        }, from: presenter)
    }

    private func goToSignInAfterSessionExpired() {
        isShowingSessionExpired = false
        CatalogSession.reset()
        // Tutup modal yang masih terbuka (mis. Keranjang) sebelum root diganti.
        window.rootViewController?.dismiss(animated: false)
        showAuth(at: .signIn)
    }

    // MARK: - Window

    private func setRoot(_ controller: UIViewController, animated: Bool) {
        window.rootViewController = controller
        window.makeKeyAndVisible()
        guard animated else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }
}

// MARK: - Debugger

private extension AppRouter {
    func configureDebugMenu() {
        guard AppEnvironment.isDebugToolsEnabled else { return }
        let menu = DebugMenu.shared
        menu.shortcutsProvider = { [weak self] in self?.debugShortcuts() ?? [] }
        menu.onServerChanged = { [weak self] in self?.restartWithFreshSession() }
    }

    /// Ganti server = token & keranjang lama tidak berlaku lagi.
    func restartWithFreshSession() {
        PushRegistrar.shared.sessionEnded()
        TokenStorage.delete()
        CatalogSession.reset()
        showAuth(at: .splash)
    }

    func debugShortcuts() -> [DebugShortcutSection] {
        let hasToken = TokenStorage.hasToken

        let tabs = MainTab.allCases.map { tab in
            DebugShortcut(tab.title, systemImage: tab.systemImage) { [weak self] in
                self?.showTab(tab)
            }
        }
        let cart = DebugShortcut("Keranjang", subtitle: "Buka sheet keranjang di Beranda", systemImage: "cart.fill") { [weak self] in
            self?.showTab(.home)
            // Tunggu tab bar selesai tampil sebelum present.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.homeModule?.openCart()
            }
        }
        let main = DebugShortcutSection(
            "Fitur",
            footer: hasToken ? nil : "Belum login: tab tetap bisa dibuka, tapi API yang butuh token (Pesanan, checkout) akan 401.",
            items: tabs + [cart]
        )

        let auth = DebugShortcutSection("Auth", items: [
            DebugShortcut("Splash", subtitle: "Ulangi alur launch app", systemImage: "sparkles") { [weak self] in
                self?.showAuth(at: .splash)
            },
            DebugShortcut("Onboarding", systemImage: "rectangle.on.rectangle.angled") { [weak self] in
                self?.showAuth(at: .onboarding)
            },
            DebugShortcut("Sign In", subtitle: "Token tidak dihapus", systemImage: "person.badge.key") { [weak self] in
                self?.showAuth(at: .signIn)
            },
            DebugShortcut("Sign Up", systemImage: "person.badge.plus") { [weak self] in
                self?.showAuth(at: .signUp)
            }
        ])

        let session = DebugShortcutSection("Sesi & data", items: [
            DebugShortcut("Logout", subtitle: hasToken ? "Hapus token lalu ke Sign In" : "Belum ada token",
                          systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) { [weak self] in
                PushRegistrar.shared.sessionEnded()
                TokenStorage.delete()
                self?.showAuth(at: .signIn)
            },
            DebugShortcut("Reset onboarding", subtitle: "Hapus token, onboarding tampil lagi",
                          systemImage: "arrow.counterclockwise", role: .destructive) { [weak self] in
                AppSetting.shared.isFirstTime = true
                PushRegistrar.shared.sessionEnded()
                TokenStorage.delete()
                self?.showAuth(at: .splash)
            },
            DebugShortcut("Kosongkan keranjang", subtitle: "Juga muat ulang katalog",
                          systemImage: "cart.badge.minus", role: .destructive) { [weak self] in
                CatalogSession.reset()
                // Screen yang sudah tampil masih memegang keranjang lama → buat ulang tab bar.
                guard let self, let tabBar = self.tabBar, self.window.rootViewController === tabBar else { return }
                self.showMain(selecting: MainTab(rawValue: tabBar.selectedIndex) ?? .home)
            },
            DebugShortcut("Simulasikan sesi habis", subtitle: "Bottom sheet 401 → Sign In (perlu di dalam app)",
                          systemImage: "clock.badge.exclamationmark", role: .destructive) { [weak self] in
                if let self, self.window.rootViewController !== self.tabBar {
                    self.showMain()
                }
                // Tunggu tab bar tampil dulu bila baru dibuat.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    SessionEvents.postExpired(path: "debugger")
                }
            },
            DebugShortcut("Hapus cache gambar", systemImage: "photo.badge.exclamationmark", role: .destructive) {
                URLCache.shared.removeAllCachedResponses()
            }
        ])

        // Simulator sandbox Midtrans di dalam app: salin kode bayar (VA / QRIS / link GoPay) dari layar
        // Snap, tempel di sini, bayar. Layar Pembayaran menangkap hasilnya lewat polling.
        let simulatorBase = "https://simulator.sandbox.midtrans.com"
        let simulators = DebugShortcutSection(
            "Simulator Midtrans (sandbox)",
            footer: "Buka di dalam app (tidak pindah ke Safari). Salin kode bayar dari layar Snap → buka simulator yang sesuai → tempel → bayar → tutup. "
                + "Status di layar Pembayaran berubah dalam beberapa detik.",
            items: [
                ("QRIS", "Tempel URL gambar QR dari Snap", "qrcode", "/v2/qris/index"),
                ("GoPay", "Tempel URL QR GoPay", "wallet.pass.fill", "/gopay/ui/index"),
                ("GoPay / ShopeePay (deeplink)", "Tempel link deeplink dari Snap", "link", "/v2/deeplink/index"),
                ("BCA Virtual Account", "Tempel nomor VA", "building.columns.fill", "/bca/va/index"),
                ("BNI Virtual Account", "Tempel nomor VA", "building.columns.fill", "/bni/va/index"),
                ("BRI Virtual Account", "Tempel nomor VA", "building.columns.fill", "/openapi/va/index?bank=bri"),
                ("Mandiri Bill", "Tempel kode perusahaan & nomor tagihan", "building.columns.fill", "/openapi/va/index?bank=mandiri"),
                ("Permata Virtual Account", "Tempel nomor VA", "building.columns.fill", "/permata/va/index"),
                ("CIMB Virtual Account", "Tempel nomor VA", "building.columns.fill", "/openapi/va/index?bank=cimb"),
                ("Semua simulator", "Daftar lengkap simulator sandbox", "list.bullet", "/")
            ].map { title, subtitle, icon, path in
                DebugShortcut(title, subtitle: subtitle, systemImage: icon) { [weak self] in
                    if let url = URL(string: simulatorBase + path) { self?.openInAppBrowser(url) }
                }
            }
        )

        let midtrans = DebugShortcutSection(
            "Simulasi Midtrans",
            footer: "Untuk pembayaran online yang sedang menunggu (paling baru), tanpa membuka simulator Midtrans di browser. "
                + "Layar Pembayaran yang terbuka ikut berubah dalam ±3 detik. Butuh backend APP_ENV=dev (atau mode mock).",
            items: [
                (PaymentSimulation.paid, "Bayar lunas", "Pesanan dibuat & push \"Pembayaran berhasil\"", "checkmark.seal.fill", DebugShortcut.Role.normal),
                (.denied, "Ditolak", "Seperti kartu / e-wallet menolak", "xmark.octagon.fill", .destructive),
                (.expired, "Kedaluwarsa", "Batas waktu bayar habis", "clock.badge.xmark", .destructive),
                (.cancelled, "Dibatalkan", "Dibatalkan dari sisi Midtrans", "nosign", .destructive)
            ].map { outcome, title, subtitle, icon, role in
                DebugShortcut(title, subtitle: subtitle, systemImage: icon, role: role) { [weak self] in
                    self?.simulatePayment(outcome, title: title)
                }
            }
        )

        return [main, simulators, midtrans, auth, session]
    }

    func simulatePayment(_ outcome: PaymentSimulation, title: String) {
        Task { @MainActor [weak self] in
            let message: String
            do {
                let orderNumber = try await CatalogSession.simulatePendingPayment(outcome)
                message = orderNumber.map { "Pesanan \($0) dibuat." } ?? "Status pembayaran diperbarui."
            } catch {
                message = error.localizedDescription
            }
            self?.showDebugAlert("Simulasi Midtrans: \(title)", message: message)
        }
    }

    /// Browser di dalam app (cookie & clipboard tetap jalan), di atas layar yang sedang tampil.
    func openInAppBrowser(_ url: URL) {
        guard let presenter = BottomSheetPresenter.topController(in: window) else { return }
        presenter.present(SFSafariViewController(url: url), animated: true)
    }

    func showDebugAlert(_ title: String, message: String) {
        guard let presenter = BottomSheetPresenter.topController(in: window) else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }
}
