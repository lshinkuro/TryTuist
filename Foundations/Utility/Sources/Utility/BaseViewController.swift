//
//  BaseViewController.swift
//  TTUI
//
//  Created by Phincon on 13/08/24.
//
import Foundation
import UIKit
import SwiftUI

/// Base view controller untuk semua screen.
/// Navigasi tetap memakai UIKit (UINavigationController + Coordinator),
/// sedangkan tampilan dibuat dengan SwiftUI lewat `embed(_:)`.
open class BaseViewController: UIViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        configView()
        bindingData()
    }

    open func configView() {}
    open func bindingData() {}

    /// Menempelkan SwiftUI view sebagai child `UIHostingController`
    /// yang memenuhi seluruh `view` milik view controller ini.
    @discardableResult
    public func embed<Content: View>(_ content: Content) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
        return hostingController
    }
}

public extension BaseViewController {
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }

    func validatePassword(candidate: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: candidate)
    }
}
