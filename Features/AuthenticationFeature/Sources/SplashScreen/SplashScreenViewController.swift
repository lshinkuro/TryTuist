//
//  SplashScreenViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//

import UIKit
import TTUI
import Coordinator
import Utility
import Lottie

class SplashScreenViewController: BaseViewController {
    
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var contentLottieView: UIView!
    
    weak var coordinator: SplashScreenCoordinator!
    
    var lottieView: LottieAnimationView =  LottieAnimationView(name: "Emoji-Mata Kedip")

    
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
        titleLbl.text = .localized("coachmark.first_title")
        contentLottieView.addSubview(lottieView)
        lottieView.frame = contentLottieView.bounds
        lottieView.contentMode = .scaleAspectFit
        lottieView.loopMode = .loop
        lottieView.isHidden = false
        lottieView.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.coordinator.goToOnBoard()
            self.isTokenExistInKeychain() ?  self.coordinator.goToDashboard() : self.coordinator.goToLogin()
            
        }
    }
}
