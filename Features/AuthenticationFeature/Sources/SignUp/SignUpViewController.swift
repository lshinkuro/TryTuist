//
//  SignUpViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `SignUpView`. Navigasi tetap lewat `SignUpCoordinator`.
public class SignUpViewController: BaseViewController {
    let vm = SignUpViewModel()
    weak var coordinator: SignUpCoordinator!
    var name = "kholis"
    var password = ""

    init(coordinator: SignUpCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func configView() {
        super.configView()
        navigationItem.hidesBackButton = true
        embed(
            SignUpView(
                viewModel: vm,
                email: name,
                password: password,
                onSignIn: { [weak self] in self?.coordinator.popToPreviousScreen() },
                onRegisterSuccess: { [weak self] in self?.coordinator.goToDashboard() }
            )
        )
    }
}
