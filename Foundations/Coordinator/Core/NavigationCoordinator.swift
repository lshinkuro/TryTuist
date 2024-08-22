//
//  NAvigationCoordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit

public protocol NavigationCoordinator: Coordinator {
  var navigationController: UINavigationController { get set }
}

public extension NavigationCoordinator {
  func startWithRootNavigation(_ vc: UIViewController) {
      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
      let window = windowScene?.windows.first(where: { $0.isKeyWindow })
      let nav = window?.rootViewController as? UINavigationController
      
      if nav === navigationController {
        navigationController.setViewControllers([vc], animated: true)
      } else if nav != nil {
        nav?.setViewControllers([vc], animated: true)
        self.navigationController = nav!
      } else {
        self.navigationController = UINavigationController(rootViewController: vc)
        window?.rootViewController = self.navigationController
      }
    }
}
