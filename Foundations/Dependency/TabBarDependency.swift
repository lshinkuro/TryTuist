//
//  TabBarDependency.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import Coordinator


public protocol TabBarDependency {
  func tabBarCoordinator(_ navigationController: UINavigationController) -> Coordinator
}

