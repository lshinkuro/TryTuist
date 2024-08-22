//
//  TabBarModule.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import Dependency
import Coordinator

public class TabBarModule: TabBarDependency {
    
    var homeDependency: HomeDependency!
    var calenderDepency: CalenderDependency!
    var focusDependency: FocusDependency!
    var profileDependency: ProfileDependency!
    
    public init( homeDependency: HomeDependency, calenderDependency: CalenderDependency, focusDependency: FocusDependency, profileDependency: ProfileDependency){
        self.homeDependency = homeDependency
        self.calenderDepency = calenderDependency
        self.focusDependency = focusDependency
        
        self.profileDependency = profileDependency
    }
    
    public func tabBarCoordinator(_ navigationController: UINavigationController) -> Coordinator {
        TabbarCoordinator(homeDependency: homeDependency, calenderDependency: calenderDepency, focusDependency: focusDependency,  profileDependency: profileDependency)
    }
}
