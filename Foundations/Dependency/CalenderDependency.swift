//
//  CalenderDependency.swift
//  Coordinator
//
//  Created by Phincon on 21/08/24.
//

import UIKit
import Coordinator

public protocol CalenderDependency {
  func calenderCoordinator(_ navigationController: UINavigationController) -> Coordinator
}
