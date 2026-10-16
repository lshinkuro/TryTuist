//
//  OnBoardingViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `OnBoardingView`. Navigasi tetap lewat `OnBoardingCoordinator`.
class OnBoardingViewController: BaseViewController {
    weak var coordinator: OnBoardingCoordinator!

    private let items: [OnboardingItem] = [
        .init(imageName: "onboarding-1", title: "Manage your tasks", subtitle: "You can easily manage all of your daily tasks in DoMe for free", bgImageName: "bg-1"),
        .init(imageName: "onboarding-2", title: "Create daily routine", subtitle: "In Uptodo  you can create your personalized routine to stay productive", bgImageName: "bg-2"),
        .init(imageName: "onboarding-3", title: "Orgonaize your tasks", subtitle: "You can organize your daily tasks by adding your tasks into separate categories", bgImageName: "bg-3")
    ]

    init(coordinator: OnBoardingCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configView() {
        super.configView()
        embed(
            OnBoardingView(
                items: items,
                onNext: { [weak self] in self?.coordinator.goToLogin() },
                onSkip: { [weak self] in self?.coordinator.goToLogin() }
            )
        )
    }
}
