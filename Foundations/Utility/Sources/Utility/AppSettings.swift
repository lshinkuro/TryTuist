//
//  AppSettings.swift
//  Utility
//
//  Created by Phincon on 19/08/24.
//

import Foundation

public final class AppSetting {
    public static let shared = AppSetting()

    private let defaults = UserDefaults.standard
    private init() {}

    /// `true` sampai user menyelesaikan onboarding.
    public var isFirstTime: Bool {
        get { defaults.object(forKey: "isFirstTime") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "isFirstTime") }
    }
}
