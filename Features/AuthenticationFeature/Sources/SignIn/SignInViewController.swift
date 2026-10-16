//
//  SignInViewController.swift
//  TTUI
//
//  Created by Phincon on 13/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `SignInView`. Navigasi tetap lewat `SignInCoordinator`.
public class SignInViewController: BaseViewController {
    weak var coordinator: SignInCoordinator!
    let vm = SignInViewModel()
    var name = "kholis"
    var password = ""

    init(coordinator: SignInCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func configView() {
        super.configView()
        embed(
            SignInView(
                viewModel: vm,
                email: name,
                password: password,
                onSignUp: { [weak self] in self?.coordinator.goToSignUp() },
                onLoginSuccess: { [weak self] in self?.coordinator.goToDashboard() }
            )
        )
    }
}
