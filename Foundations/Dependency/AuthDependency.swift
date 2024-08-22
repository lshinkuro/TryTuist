//
//  AuthDependency.swift
//  Dependency
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit
import Coordinator

public protocol AuthDependency {
    
  func signinCoordinator(_ navigationController: UINavigationController) -> Coordinator
    
  func signupCoordinator(_ navigationController: UINavigationController) -> Coordinator

  func dashboardCoordinator(_ navigationController: UINavigationController) -> Coordinator
    
  func onboardCoordinator(_ navigationController: UINavigationController) -> Coordinator


}
