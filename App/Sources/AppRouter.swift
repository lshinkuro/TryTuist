//
//  AppRouter.swift
//  TryTuist
//
//  Routing level aplikasi: memilih flow Auth atau Main (tab bar) sebagai root window.
//  Semua perakitan feature ada di sini — tidak ada lagi *Dependency / *Coordinator.
//
import UIKit
import Navigation
import TTUI
import AuthenticationFeature
import HomeFeature
import FocuseFeature
import ProfileFeature

@MainActor
final class AppRouter {
    private let window: UIWindow
    private var authModule: AuthenticationModule?

    init(window: UIWindow) {
        self.window = window
        window.tintColor = UIColor.brand
    }

    func start() {
        showAuth(showSplash: true)
    }

    // MARK: - Flows

    private func showAuth(showSplash: Bool) {
        let router = Router()
        let auth = AuthenticationModule(router: router) { [weak self] in
            self?.showMain()
        }
        authModule = auth
        auth.start(showSplash: showSplash)
        setRoot(router.navigationController, animated: !showSplash)
    }

    private func showMain() {
        authModule = nil
        let tabBar = MainTabBarController(features: [
            HomeModule(),
            MenuModule(),
            FocusModule(),
            ProfileModule(onLogout: { [weak self] in
                self?.showAuth(showSplash: false)
            })
        ])
        setRoot(tabBar, animated: true)
    }

    // MARK: - Window

    private func setRoot(_ controller: UIViewController, animated: Bool) {
        window.rootViewController = controller
        window.makeKeyAndVisible()
        guard animated else { return }
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
    }
}
