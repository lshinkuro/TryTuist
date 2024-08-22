//
//  HomeDependency.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit
import Coordinator

public protocol HomeDependency {
  func homeCoordinator(_ navigationController: UINavigationController) -> Coordinator
}
