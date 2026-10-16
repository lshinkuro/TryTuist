//
//  FocusesViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `FocusesView`. Navigasi tetap lewat `FocuseCoordinator`.
class FocusesViewController: BaseViewController {
    weak var coordinator: FocuseCoordinator!

    init(coordinator: FocuseCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configView() {
        super.configView()
        view.backgroundColor = .white
        embed(FocusesView())
    }
}
