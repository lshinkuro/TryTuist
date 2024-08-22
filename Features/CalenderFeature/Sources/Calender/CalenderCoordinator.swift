//
//  CalenderCoordinator.swift
//  CalenderFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import Coordinator
import UIKit
import Dependency

class CalenderCoordinator: Coordinator {
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
    let calenderViewController = CalenderViewController(coordinator: self)
    navigationController.setViewControllers([calenderViewController], animated: true)
  }
}
