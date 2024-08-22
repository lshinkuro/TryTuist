//
//  AppCoordinator.swift
//  TryTuist
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import Dependency
import Coordinator

class AppCoordinator: Coordinator, NavigationCoordinator {
    
    
    let profileDependency: ProfileDependency
    let homeDependency: HomeDependency
    let authDependency: AuthDependency

    
    let tabBarDependency: TabBarDependency
    weak var parentCoordinator: Coordinator?
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    init(
        profileDependency: ProfileDependency,
        homeDependency: HomeDependency,
        authDependency: AuthDependency,
        tabBarDependency: TabBarDependency,
        navigationController: UINavigationController) {
            self.profileDependency = profileDependency
            self.homeDependency = homeDependency
            self.authDependency = authDependency
            self.tabBarDependency = tabBarDependency
            self.navigationController = navigationController
        }
    
    func start() {
//        showSplash()
        showLogin()
//            showProfile()
        //    showSetting()
        //    showContacts()
        //    showOnBoarding()
        //    showHome()
        //    showHistory()
        //    showTabBar()
    }
    
    func showLogin() {
        let coordinator = authDependency.signinCoordinator(navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func showProfile() {
        let coordinator = profileDependency.profileCoordinator(navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func showHome() {
        let coordinator = homeDependency.homeCoordinator(navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func showTabBar() {
        let coordinator = tabBarDependency.tabBarCoordinator(navigationController)
        addChildCoordinator(coordinator)
        coordinator.start()
    }
}
