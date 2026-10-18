//
//  NotificationManager.swift
//  TryTuist
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Minta izin notifikasi; bila diizinkan, daftarkan ke APNs → AppDelegate menerima device token
    /// (diteruskan ke `PushRegistrar`). Juga dipanggil ulang tiap launch supaya token tetap segar.
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else {
                print("Notification authorization denied")
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
