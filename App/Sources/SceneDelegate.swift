//
//  SceneDelegate.swift
//  TryTuist
//

import UIKit

/// Window harus dibuat dari `UIWindowScene` (scene lifecycle wajib sejak SDK iOS 26).
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appRouter: AppRouter?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let router = AppRouter(window: window)
        appRouter = router
        router.start()
    }
}
