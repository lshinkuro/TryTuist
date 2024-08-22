//
//  Ext+Color.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import UIKit

public extension UIColor {
    // MARK: - Additional - NORMAL GREEN
    static let foodGreenBase         = #colorLiteral(red: 0.5137254902, green: 0.7529411765, blue: 0.2823529412, alpha: 1)
    
    
    // MARK: - Additional - WHITE
    static let foodWhite30           = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 0.3)
    static let foodWhite50           = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
    static let foodWhite65           = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.65)
    static let foodWhite80           = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)
    static let foodWhite100          = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    
    // MARK: - Addtional - BLACK
    static let foodBlack30           = #colorLiteral(red: 0.6941176471, green: 0.6941176471, blue: 0.6941176471, alpha: 1)
    static let foodBlack50           = #colorLiteral(red: 0.4980392157, green: 0.4980392157, blue: 0.4980392157, alpha: 1)
    static let foodBlack65           = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.65)
    static let foodBlack80           = #colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
    static let foodBlack100          = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    
    // MARK: - Primary - GREY
    static let foodGrey1             = #colorLiteral(red: 0.9647058824, green: 0.9647058824, blue: 0.9647058824, alpha: 1)
    static let foodGrey1e            = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    static let foodGrey2             = #colorLiteral(red: 0.8588235294, green: 0.862745098, blue: 0.8705882353, alpha: 1)
    static let foodGrey3             = #colorLiteral(red: 0.6549019608, green: 0.662745098, blue: 0.6745098039, alpha: 1)
    static let foodGrey4             = #colorLiteral(red: 0.4509803922, green: 0.462745098, blue: 0.4784313725, alpha: 1)
    static let foodGrey5             = #colorLiteral(red: 0.2588235294, green: 0.262745098, blue: 0.2705882353, alpha: 1)
    static let foodGrey6             = #colorLiteral(red: 0.4980392157, green: 0.4980392157, blue: 0.4980392157, alpha: 1)
    static let foodGrey7             = #colorLiteral(red: 0.6980392157, green: 0.6980392157, blue: 0.6980392157, alpha: 1)
    static let foodGrey8             = #colorLiteral(red: 0.8588235294, green: 0.862745098, blue: 0.8705882353, alpha: 1)
    static let foodGrey9             = #colorLiteral(red: 0.9411764706, green: 0.9411764706, blue: 0.9411764706, alpha: 1)
    
    // MARK: - Primary - MAROON
    static let foodMaroon1           = #colorLiteral(red: 0.8705882353, green: 0, blue: 0, alpha: 1)
    static let foodMaroon2           = #colorLiteral(red: 0.6705882353, green: 0, blue: 0, alpha: 1)
    static let foodMaroon3           = #colorLiteral(red: 0.4705882353, green: 0, blue: 0, alpha: 1)
    static let foodMaroon3a          = #colorLiteral(red: 0.3921568627, green: 0.05098039216, blue: 0.05490196078, alpha: 1)
    static let foodMaroon4           = #colorLiteral(red: 0.2705882353, green: 0, blue: 0, alpha: 1)
    static let foodMaroon5           = #colorLiteral(red: 0.07058823529, green: 0, blue: 0, alpha: 1)
    
    // MARK: - Primary - RED
    static let foodRed1              = #colorLiteral(red: 1, green: 0.8, blue: 0.8, alpha: 1)
    static let foodRed2              = #colorLiteral(red: 1, green: 0.4, blue: 0.4, alpha: 1)
    static let foodRed3              = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
    static let foodRed4              = #colorLiteral(red: 0.8, green: 0, blue: 0, alpha: 1)
    static let foodRed5              = #colorLiteral(red: 0.6, green: 0, blue: 0, alpha: 1)
    
    // MARK: - Secondary - BRIGHT CORAL
    static let foodBrightCoral1      = #colorLiteral(red: 0.9843137255, green: 0.7098039216, blue: 0.7019607843, alpha: 1)
    static let foodBrightCoral2      = #colorLiteral(red: 0.9725490196, green: 0.5254901961, blue: 0.5137254902, alpha: 1)
    static let foodBrightCoral3      = #colorLiteral(red: 0.9607843137, green: 0.3411764706, blue: 0.3254901961, alpha: 1)
    static let foodBrightCoral4      = #colorLiteral(red: 0.9490196078, green: 0.1568627451, blue: 0.137254902, alpha: 1)
    static let foodBrightCoral5      = #colorLiteral(red: 0.8392156863, green: 0.06666666667, blue: 0.04705882353, alpha: 1)
    
    static let foodBrightBlue        = #colorLiteral(red: 0.5254901961, green: 0.5294117647, blue: 0.9058823529, alpha: 1)
    
    
    // MARK: - Secondary - BRIGHT CORAL
    static let foodBrightLinear1      = #colorLiteral(red: 0.9764705882, green: 0.5333333333, blue: 0.1215686275, alpha: 1)
    
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        // swiftlint:disable identifier_name
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
