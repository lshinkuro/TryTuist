//
//  HomeModule.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit
import Dependency
import Coordinator

public class HomeModule: HomeDependency {
    
  public func homeCoordinator(_ navigationController: UINavigationController) -> any Coordinator {
    HomeCoordinator(navigationController: navigationController)
  }
  
  public init() {}
  
}
