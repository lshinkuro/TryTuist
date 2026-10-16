//
//  HomeViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `HomeView`. Navigasi tetap lewat `HomeCoordinator`.
class HomeViewController: BaseViewController {
    weak var coordinator: HomeCoordinator!
    private let viewModel = HomeViewModel()

    init(coordinator: HomeCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configView() {
        super.configView()
        embed(HomeView(viewModel: viewModel))
    }

    override func bindingData() {
        super.bindingData()
        viewModel.loadData()
    }
}
