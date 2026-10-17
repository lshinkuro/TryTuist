//
//  Router.swift
//  Navigation
//
//  Satu-satunya tempat SwiftUI view dibungkus ke UIKit (UIHostingController).
//  Feature cukup memanggil `router.push(SomeView())` — tidak perlu membuat
//  ViewController atau Coordinator per screen lagi.
//
import SwiftUI
import UIKit

@MainActor
public final class Router {
    public let navigationController: UINavigationController

    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }

    // MARK: - Stack

    /// Mengganti seluruh stack dengan satu screen. `animated` memakai efek fade.
    public func setRoot<Content: View>(_ view: Content,
                                       title: String? = nil,
                                       hidesNavigationBar: Bool = false,
                                       animated: Bool = false) {
        let controller = host(view, title: title, hidesNavigationBar: hidesNavigationBar)
        if animated {
            let transition = CATransition()
            transition.duration = 0.3
            transition.type = .fade
            navigationController.view.layer.add(transition, forKey: kCATransition)
        }
        navigationController.setViewControllers([controller], animated: false)
    }

    public func push<Content: View>(_ view: Content,
                                    title: String? = nil,
                                    hidesNavigationBar: Bool = false,
                                    animated: Bool = true) {
        let controller = host(view, title: title, hidesNavigationBar: hidesNavigationBar)
        navigationController.pushViewController(controller, animated: animated)
    }

    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    public func popToRoot(animated: Bool = true) {
        navigationController.popToRootViewController(animated: animated)
    }

    // MARK: - Modal

    /// Menampilkan screen sebagai sheet (dengan navigation bar sendiri bila `title` diisi).
    public func present<Content: View>(_ view: Content, title: String? = nil, animated: Bool = true) {
        let controller = host(view, title: title, hidesNavigationBar: title == nil)
        let modal = UINavigationController(rootViewController: controller)
        navigationController.present(modal, animated: animated)
    }

    public func dismiss(animated: Bool = true) {
        navigationController.dismiss(animated: animated)
    }

    // MARK: - Hosting

    private func host<Content: View>(_ view: Content, title: String?, hidesNavigationBar: Bool) -> UIViewController {
        let controller = HostingController(rootView: view, hidesNavigationBar: hidesNavigationBar)
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = .never
        return controller
    }
}

/// Pembungkus SwiftUI → UIKit yang dipakai semua screen.
/// Mengatur tampil/sembunyi navigation bar per screen.
final class HostingController<Content: View>: UIHostingController<Content>, ScreenNameProviding {
    private let hidesNavigationBar: Bool
    /// Nama screen untuk Debugger, mis. "HomeView".
    let screenName = ScreenTracker.readableName(of: Content.self)

    init(rootView: Content, hidesNavigationBar: Bool) {
        self.hidesNavigationBar = hidesNavigationBar
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(hidesNavigationBar, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ScreenTracker.shared.didAppear(screenName)
    }
}
