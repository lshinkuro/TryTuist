//
//  Ext+Font.swift
//  TryTuist
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import UIKit

public extension UIFont {
    
    static func omoBold(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-Bold",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoBoldItalic(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-BoldItalic",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoCondBold(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-CondBold",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoCondLight(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-CondLight",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoCondLightItalic(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-CondLightItalic",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoExtraBold(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-ExtraBold",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoExtraBoldItalic(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-ExtraBoldItalic",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoItalic(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-Italic",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoLight(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-Light",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoLightItalic(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-LightItalic",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoRegular(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-Regular",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoSemiBold(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-SemiBold",
            size: size) ?? .systemFont(ofSize: size)
    }
    
    static func omoSemiBoldItalic(_ size: CGFloat) -> UIFont {
        return UIFont(
            name: "OpenSans-SemiBoldItalic",
            size: size) ?? .systemFont(ofSize: size)
    }
    
}
