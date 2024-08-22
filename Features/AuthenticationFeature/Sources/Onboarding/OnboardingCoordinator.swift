//
//  OnboardingCoordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//

import Foundation
import Coordinator
import UIKit
import Dependency

class OnBoardingCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var authDependency: AuthDependency
    var tabBarDependency: TabBarDependency

    
    init(navigationController: UINavigationController,
         childCoordinators: [Coordinator] = [],
         parentCoordinator: Coordinator? = nil,
         authDependency: AuthDependency,
         tabBarDependency: TabBarDependency) {
        self.navigationController = navigationController
        self.childCoordinators = childCoordinators
        self.parentCoordinator = parentCoordinator
        self.authDependency = authDependency
        self.tabBarDependency = tabBarDependency
    }
    
    func start() {
        let onBoardViewController = OnBoardingViewController(coordinator: self)
        navigationController.setViewControllers([onBoardViewController], animated: true)
        startWithRoot(navigationController)
    }
    
    
    func goToLogin() {
        let tabBarCoordinator = authDependency.dashboardCoordinator(navigationController)
        let appCoordinator = getParentCoordinator(from: self, with: "AppCoordinator")
        appCoordinator?.addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.start()
    }
    
    func goToDashboard() {
        let tabBarCoordinator = tabBarDependency.tabBarCoordinator(navigationController)
        let appCoordinator = getParentCoordinator(from: self, with: "AppCoordinator")
        appCoordinator?.addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.start()
    }
    
}
