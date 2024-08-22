//
//  TabbarCoordinatorable.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit

public protocol TabbarCoordinatorable: Coordinator {
  var tabbarController: UITabBarController { get set }
}
