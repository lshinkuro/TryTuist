//
//  AppDelegate.swift
//  TryTuist
//
//  Created by Phincon on 13/08/24.
//

import UIKit
import AuthenticationFeature
import ProfileFeature
import HomeFeature
import CalenderFeature
import FocuseFeature
import TTUI
import TabBarFeature
import Dependency
import netfox

@main
class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var app: AppCoordinator?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = .init(frame: UIScreen.main.bounds)
        
//        window?.rootViewController = MainViewController(nibName: "MainViewController", bundle: .module)
//        window?.rootViewController = SignInViewController()
        
        let nav = UINavigationController()
        window?.rootViewController = nav
        UITabBar.appearance().unselectedItemTintColor = .gray
        UITabBar.appearance().tintColor = .label
        window?.makeKeyAndVisible()
        
        #if DEBUG
        NFX.sharedInstance().start()
        #endif
        

        
        
        //MARK: set coordinator
        
        let homeDependency = HomeModule()
        let profileDependency = ProfileModule()
        let calenderDependency = CalenderModule()
        let focusDependency = FocusModule()
        
        
        let tabBarDependency = TabBarModule(homeDependency: homeDependency,calenderDependency: calenderDependency  , focusDependency: focusDependency, profileDependency: profileDependency)
        
        let authDependency = AuthenticationModule(tabBarDependency: tabBarDependency)

        app = AppCoordinator(profileDependency: profileDependency, homeDependency: homeDependency, authDependency: authDependency, tabBarDependency: tabBarDependency, navigationController: nav)
        app?.start()
        return true
    }
    
}
