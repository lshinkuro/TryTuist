//
//  SignUpcoordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//

import Foundation
import Coordinator
import UIKit
import Dependency

class SignUpCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var tabBarDependency: TabBarDependency

    
    init(navigationController: UINavigationController,
         childCoordinators: [Coordinator] = [],
         parentCoordinator: Coordinator? = nil,
         tabBarDependency: TabBarDependency) {
        self.navigationController = navigationController
        self.childCoordinators = childCoordinators
        self.parentCoordinator = parentCoordinator
        self.tabBarDependency = tabBarDependency
    }
    
    func start() {
        let signUpViewController = SignUpViewController(coordinator: self)
//        startWithRoot(navigationController)
        navigationController.pushViewController(signUpViewController, animated: true)
    }
    
    func goToDashboard() {
        let tabBarCoordinator = tabBarDependency.tabBarCoordinator(navigationController)
        let appCoordinator = getParentCoordinator(from: self, with: "AppCoordinator")
        appCoordinator?.addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.start()
    }
}
