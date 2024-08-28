//
//  TabbarCoordinator.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit
import Dependency
import Coordinator
import TTUI

class TabbarCoordinator: NSObject, TabbarCoordinatorable {
    
    var tabbarController: UITabBarController
    var childCoordinators: [any Coordinator] = []
    
    weak var parentCoordinator: Coordinator?
    
    let homeDependency: HomeDependency
    let calenderDependency: CalenderDependency
    let focusDependency: FocusDependency
    let profileDependency: ProfileDependency
    
    let tabBarItemsData: [MainTabBarType] = [
        .home, .calender, .focus, .profile
    ]
    
    init(tabBarController: UITabBarController = .init(),
         homeDependency: HomeDependency,
         calenderDependency: CalenderDependency,
         focusDependency: FocusDependency,
         profileDependency: ProfileDependency) {
        self.tabbarController = tabBarController
        self.homeDependency = homeDependency
        self.profileDependency = profileDependency
        self.calenderDependency = calenderDependency
        self.focusDependency = focusDependency
        
        super.init()
        self.tabbarController.delegate = self
    }
    
    func start() {
        let homeNav = UINavigationController()
        let homeCoordinator = homeDependency.homeCoordinator(homeNav)
        addChildCoordinator(homeCoordinator)
        homeCoordinator.start()
        
        let calenderNav = UINavigationController()
        let calenderCoordinator = calenderDependency.calenderCoordinator(calenderNav)
        addChildCoordinator(homeCoordinator)
        calenderCoordinator.start()
        
        let focusNav = UINavigationController()
        let focusCoordinator = focusDependency.focusCoordinator(focusNav)
        addChildCoordinator(homeCoordinator)
        focusCoordinator.start()
        
        let profileNav = UINavigationController()
        let profileCoordinator = profileDependency.profileCoordinator(profileNav)
        addChildCoordinator(profileCoordinator)
        profileCoordinator.start()
        
        
        startWithRoot(tabbarController)
        tabbarController.setViewControllers([
            homeNav,
            calenderNav,
            focusNav,
            profileNav
        ], animated: false)
        setupTabbar()
        
    }
    
    private func setupTabbar() {
        setupTabBarItems(tabbarController.tabBar)
    }
    
    public func setupTabBarItems(_ tabBar: UITabBar) {
        guard let tabBarItems = tabBar.items else { return }

        zip(tabBarItemsData.indices, tabBarItemsData).forEach { index, tabBarType in
            let tabBarItem = tabBarItems[index]
            tabBarItem.title = tabBarType.title
            tabBarItem.image = tabBarType.setImage()
            tabBarItem.selectedImage =  tabBarType.selectedImage()
        }
        
        UITabBar.appearance().unselectedItemTintColor = .gray
        UITabBar.appearance().tintColor = .label
    }
}

extension TabbarCoordinator {
    

}

extension TabbarCoordinator: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let nav = viewController as? UINavigationController
        nav?.popToRootViewController(animated: false)
    }
}

