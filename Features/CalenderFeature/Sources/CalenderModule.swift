//
//  CalenderModule.swift
//  CalenderFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import UIKit
import Dependency
import Coordinator

public class CalenderModule: CalenderDependency {
    
  public func calenderCoordinator(_ navigationController: UINavigationController) -> any Coordinator {
    CalenderCoordinator(navigationController: navigationController)
  }
  
  public init() {}
  
}
