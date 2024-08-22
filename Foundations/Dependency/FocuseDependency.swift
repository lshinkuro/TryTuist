//
//  FocuseDependency.swift
//  Coordinator
//
//  Created by Phincon on 21/08/24.
//

import UIKit
import Coordinator

public protocol FocusDependency {
  func focusCoordinator(_ navigationController: UINavigationController) -> Coordinator
}
