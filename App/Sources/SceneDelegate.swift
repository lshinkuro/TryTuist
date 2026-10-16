//
//  SceneDelegate.swift
//  TryTuist
//

import UIKit
import AuthenticationFeature
import ProfileFeature
import HomeFeature
import CalenderFeature
import FocuseFeature
import TabBarFeature

/// Window harus dibuat dari `UIWindowScene` (scene lifecycle wajib sejak SDK iOS 26).
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var app: AppCoordinator?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let nav = UINavigationController()
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window

        //MARK: set coordinator
        let homeDependency = HomeModule()
        let profileDependency = ProfileModule()
        let calenderDependency = CalenderModule()
        let focusDependency = FocusModule()

        let tabBarDependency = TabBarModule(homeDependency: homeDependency,
                                            calenderDependency: calenderDependency,
                                            focusDependency: focusDependency,
                                            profileDependency: profileDependency)
        let authDependency = AuthenticationModule(tabBarDependency: tabBarDependency)

        app = AppCoordinator(profileDependency: profileDependency,
                             homeDependency: homeDependency,
                             authDependency: authDependency,
                             tabBarDependency: tabBarDependency,
                             navigationController: nav)
        app?.start()
    }
}
