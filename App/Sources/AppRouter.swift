//
//  AppRouter.swift
//  TryTuist
//
//  Routing level aplikasi: memilih flow Auth atau Main (tab bar) sebagai root window.
//  Semua perakitan feature ada di sini — tidak ada lagi *Dependency / *Coordinator.
//  Juga menyediakan shortcut navigasi untuk Debugger (shake device, non-Prod).
//
import UIKit
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
            case .home: return "Beranda"
            case .menu: return "Menu"
            case .orders: return "Pesanan"
            case .profile: return "Profil"
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
    }

    func start() {
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
            self?.showAuth(at: .signIn)
        })
        let tabBar = MainTabBarController(features: [
            home,
            MenuModule(onExternalRoute: catalogRoute),
            FocusModule(),
            profile
        ])
        tabBar.selectedIndex = tab.rawValue
        // tabBar menyimpan feature-nya, jadi referensi weak di sini cukup.
        self.tabBar = tabBar
        self.homeModule = home
        self.profileModule = profile
        setRoot(tabBar, animated: true)
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
                TokenStorage.delete()
                self?.showAuth(at: .signIn)
            },
            DebugShortcut("Reset onboarding", subtitle: "Hapus token, onboarding tampil lagi",
                          systemImage: "arrow.counterclockwise", role: .destructive) { [weak self] in
                AppSetting.shared.isFirstTime = true
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

        return [main, auth, session]
    }
}
