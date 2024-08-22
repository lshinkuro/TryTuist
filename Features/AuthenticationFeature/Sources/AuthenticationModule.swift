//
//  AuthenticationModule.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit
import Dependency
import Coordinator

public class AuthenticationModule: AuthDependency {
    
    var tabBarDependency: TabBarDependency
    
    public  init(tabBarDependency: TabBarDependency) {
        self.tabBarDependency = tabBarDependency
    }
    
    public func signinCoordinator(_ navigationController: UINavigationController) -> Coordinator {
        SplashScreenCoordinator(navigationController: navigationController, authDependency: self, tabBarDependency: tabBarDependency)
    }
    
    public func signupCoordinator(_ navigationController: UINavigationController) -> Coordinator {
        SignUpCoordinator(navigationController: navigationController, tabBarDependency: tabBarDependency)
    }
    
    public func dashboardCoordinator(_ navigationController: UINavigationController) -> Coordinator {
        SignInCoordinator(navigationController: navigationController, authDependency: self, tabBarDependency: tabBarDependency)
    }
    
    public func onboardCoordinator(_ navigationController: UINavigationController) -> Coordinator {
        OnBoardingCoordinator(navigationController: navigationController, authDependency: self, tabBarDependency: tabBarDependency)
    }
    
}
