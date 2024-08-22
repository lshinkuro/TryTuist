//
//  SplashScreenViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//

import UIKit
import TTUI
import Coordinator

class SplashScreenViewController: BaseViewController {
    
    
    weak var coordinator: SplashScreenCoordinator!
    
    // MARK: used if screen using NIB file
    init(coordinator: SplashScreenCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: "SplashScreenViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.coordinator.goToOnBoard()
            self.isTokenExistInKeychain() ?  self.coordinator.goToDashboard() : self.coordinator.goToLogin()
            
        }
    }
}
