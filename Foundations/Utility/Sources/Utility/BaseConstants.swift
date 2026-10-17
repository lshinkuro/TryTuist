//
//  BaseConstants.swift
//  TTUI
//
//  Created by Phincon on 19/08/24.
//

import Foundation
import UIKit

/// Nilai diambil dari environment aktif (Configs/<Env>.xcconfig), bukan di-hardcode.
public enum BaseConstant {
    public static var baseUrl: String { AppEnvironment.apiBaseURL }
    public static var apikey: String { AppEnvironment.apiKey }
}

public enum SFSymbols {
    public static let homeSymbol = UIImage(systemName: "house.circle")
    public static let calenderSymbol = UIImage(systemName: "calendar.circle")
    public static let focusSymbol = UIImage(systemName: "f.circle")
    public static let profileSymbol = UIImage(systemName: "person.crop.circle")
    
    public static let favoriteSymbol = UIImage(systemName: "heart")
    public static let notificationSymbol = UIImage(systemName: "bell")
    
    public static let homeSymbolSelected = UIImage(systemName: "house.circle.fill")
    public static let calenderSymbolSelected = UIImage(systemName: "calendar.circle.fill")
    public static let focusSymbolSelected = UIImage(systemName: "f.circle.fill")
    public static let profileSymbolSelected = UIImage(systemName: "person.crop.circle.fill")
    
    public static let arrowSymbol = UIImage(systemName: "arrow.right.circle.fill")
    public static let statusSymbol = UIImage(systemName: "circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .regular, scale: .default))
}

public enum ScreenSize {
    static let width        = UIScreen.main.bounds.size.width
    static let height       = UIScreen.main.bounds.size.height
    static let maxLength    = max(ScreenSize.width, ScreenSize.height)
    static let minLength    = min(ScreenSize.width, ScreenSize.height)
}

