//
//  SplashScreenViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//
import UIKit
import TTUI
import Utility

/// Host UIKit untuk `SplashScreenView`. Navigasi tetap lewat `SplashScreenCoordinator`.
class SplashScreenViewController: BaseViewController {
    weak var coordinator: SplashScreenCoordinator!

    init(coordinator: SplashScreenCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configView() {
        super.configView()
        embed(SplashScreenView(title: .localized("coachmark.first_title")))

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            TokenStorage.hasToken ? self.coordinator.goToDashboard() : self.coordinator.goToLogin()
        }
    }
}
