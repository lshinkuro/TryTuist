//
//  AppSettings.swift
//  TTUI
//
//  Created by Phincon on 19/08/24.
//

import Foundation

class AppSetting {
    static let shared =  AppSetting()
    
    let kUserDefaults = UserDefaults.standard

    var isFirstTime: Bool {
        get {
            return kUserDefaults.value(forKey: "isFirstTime") as? Bool ?? true
        }
        set(_isNewDevice) {
            kUserDefaults.set(_isNewDevice, forKey: "isFirstTime")
            kUserDefaults.synchronize()
        }
    }
}
