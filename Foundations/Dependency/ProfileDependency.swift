//
//  ProfileDependency.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import Coordinator

public protocol ProfileDependency {
  func profileCoordinator(_ navigationController: UINavigationController) -> Coordinator
}
