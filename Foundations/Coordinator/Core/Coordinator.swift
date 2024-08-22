//
//  Coordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit

public protocol Coordinator: AnyObject {
  var childCoordinators: [Coordinator] { get set }
  var parentCoordinator: Coordinator? { get set }
  
  func start()
  func removeChildCoordinator(_ coordinator: Coordinator)
  func addChildCoordinator(_ coordinator: Coordinator)
}

public extension Coordinator {
  
  var coorinatorName: String {
    "\(Self.self)"
  }
  
  func removeChildCoordinator(_ coordinator: Coordinator) {
    childCoordinators.removeAll { $0 === coordinator }
  }
  
  func addChildCoordinator(_ coordinator: Coordinator) {
    self.childCoordinators.append(coordinator)
    coordinator.parentCoordinator = self
  }
  
  func startWithRoot(_ vc: UIViewController) {
    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let window = windowScene?.windows.first(where: { $0.isKeyWindow })
    window?.rootViewController = vc
  }
  
  func getParentCoordinator<T: Coordinator>(from coordinator: Coordinator) -> T? {
    let parent = coordinator.parentCoordinator
    if let parent = parent as? T {
      return parent
    } else if let parent{
      return getParentCoordinator(from: parent)
    }
    return nil
  }
  
  func getParentCoordinator(from coordinator: Coordinator, with className: String) -> Coordinator? {
    let parent = coordinator.parentCoordinator
    if parent?.coorinatorName == className {
      return parent
    } else if let parent {
      return getParentCoordinator(from: parent, with: className)
    }
    return nil
  }
  
}

public extension Coordinator {
  
    // Fungsi untuk kembali ke layar sebelumnya
    func popToPreviousScreen(animated: Bool = true) {
        if let navigationController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })?.rootViewController as? UINavigationController {
            navigationController.popViewController(animated: animated)
        }
    }
  
    // Fungsi untuk kembali ke root view controller
    func popToRoot(animated: Bool = true) {
        if let navigationController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })?.rootViewController as? UINavigationController {
            navigationController.popToRootViewController(animated: animated)
        }
    }
}

