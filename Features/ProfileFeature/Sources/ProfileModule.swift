//
//  ProfileModule.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit
import Dependency
import Coordinator

public class ProfileModule: ProfileDependency {
    
  public func profileCoordinator(_ navigationController: UINavigationController) -> any Coordinator {
    ProfileCoordinator(navigationController: navigationController)
  }
  
  public init() {}
  
}

