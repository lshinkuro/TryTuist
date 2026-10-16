//
//  CalenderViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//
import UIKit
import Utility

/// Host UIKit untuk `CalenderView`. Navigasi tetap lewat `CalenderCoordinator`.
class CalenderViewController: BaseViewController {
    weak var coordinator: CalenderCoordinator!

    init(coordinator: CalenderCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configView() {
        super.configView()
        title = "calender"
        embed(CalenderView())
    }
}
