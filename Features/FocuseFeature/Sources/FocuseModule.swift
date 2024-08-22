//
//  FocusesModule.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import UIKit
import Dependency
import Coordinator

public class FocusModule: FocusDependency {
    
  public func focusCoordinator(_ navigationController: UINavigationController) -> any Coordinator {
    FocuseCoordinator(navigationController: navigationController)
  }
  
  public init() {}
  
}

