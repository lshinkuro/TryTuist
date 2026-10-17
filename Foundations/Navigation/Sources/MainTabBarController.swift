//
//  MainTabBarController.swift
//  Navigation
//
//  Tab bar generik: setiap tab punya Router (UINavigationController) sendiri.
//
import UIKit

@MainActor
public final class MainTabBarController: UITabBarController {
    /// Disimpan supaya feature & router hidup selama tab bar tampil.
    private let features: [TabFeature]
    private let routers: [Router]

    public init(features: [TabFeature]) {
        self.features = features
        self.routers = features.map { feature in
            let router = Router()
            let item = feature.tabItem
            router.navigationController.tabBarItem = UITabBarItem(
                title: item.title,
                image: UIImage(systemName: item.systemImage),
                selectedImage: UIImage(systemName: item.selectedSystemImage)
            )
            feature.start(router: router)
            return router
        }
        super.init(nibName: nil, bundle: nil)
        viewControllers = routers.map(\.navigationController)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
