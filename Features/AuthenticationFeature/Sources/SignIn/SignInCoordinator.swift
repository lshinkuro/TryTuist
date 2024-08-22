//
//  SignInCoordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import Coordinator
import UIKit
import Dependency

class SignInCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var tabBarDependency: TabBarDependency
    var authDependency: AuthDependency

    
    init(navigationController: UINavigationController,
         childCoordinators: [Coordinator] = [],
         parentCoordinator: Coordinator? = nil,
         authDependency: AuthDependency,
         tabBarDependency: TabBarDependency) {
        self.navigationController = navigationController
        self.childCoordinators = childCoordinators
        self.parentCoordinator = parentCoordinator
        self.tabBarDependency = tabBarDependency
        self.authDependency = authDependency

    }
    
    func start() {
        let signInViewController = SignInViewController(coordinator: self)
        signInViewController.name = "kholis@gmail.com"
        signInViewController.password = "12345678"
        navigationController.setViewControllers([signInViewController], animated: false)
        startWithRoot(navigationController)
    }
    
    func goToSignUp() {
        let tabBarCoordinator = authDependency.signupCoordinator(navigationController)
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

