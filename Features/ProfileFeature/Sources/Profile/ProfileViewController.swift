//
//  ProfileViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `ProfileView`. Navigasi tetap lewat `ProfileCoordinator`.
class ProfileViewController: BaseViewController {
    weak var coordinator: ProfileCoordinator!

    init(coordinator: ProfileCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configView() {
        super.configView()
        view.backgroundColor = .white
        embed(ProfileView())
    }
}
