//
//  MainTabBarType.swift
//  TabBarFeature
//
//  Created by Phincon on 19/08/24.
//

import Foundation
import UIKit
import TTUI

enum MainTabBarType {
    case home
    case calender
    case focus
    case profile
}

extension MainTabBarType {
    var index: Int {
        switch self {
        case .home: return 0
        case .calender: return 1
        case .focus: return 2
        case .profile: return 3
        }
        
    }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .calender: return "Calender"
        case .focus: return "Focuses"
        case .profile: return "Profile"
        }
    }
    
    func setImage() -> UIImage? {
        var image: UIImage?
        switch self {
        case .home:
            image = SFSymbols.homeSymbol
        case .calender:
            image = SFSymbols.calenderSymbol
        case .focus:
            image = SFSymbols.focusSymbol
        case .profile:
            image = SFSymbols.profileSymbol
        }
        return image
    }
    
    func selectedImage() -> UIImage? {
        var image: UIImage?
        switch self {
        case .home:
            image = SFSymbols.homeSymbolSelected
        case .calender:
            image = SFSymbols.calenderSymbolSelected
        case .focus:
            image = SFSymbols.focusSymbolSelected
        case .profile:
            image = SFSymbols.profileSymbolSelected
        }
        return image
    }
    
}
