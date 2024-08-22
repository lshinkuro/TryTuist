//
//  ProfileCoordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import Coordinator
import UIKit
import Dependency

class ProfileCoordinator: Coordinator {
  weak var navigationController: UINavigationController!
  weak var parentCoordinator: Coordinator?
  var childCoordinators: [Coordinator] = []
  
  init(navigationController: UINavigationController,
       childCoordinators: [Coordinator] = [],
       parentCoordinator: Coordinator? = nil) {
    self.navigationController = navigationController
    self.childCoordinators = childCoordinators
    self.parentCoordinator = parentCoordinator
  }
  
  func start(){
    let profileViewController = ProfileViewController(coordinator: self)
    navigationController.setViewControllers([profileViewController], animated: true)
  }
}
