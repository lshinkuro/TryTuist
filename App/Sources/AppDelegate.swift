//
//  AppDelegate.swift
//  TryTuist
//
//  Created by Phincon on 13/08/24.
//

import UIKit
import AuthenticationFeature
import ProfileFeature
import HomeFeature
import CalenderFeature
import FocuseFeature
import TTUI
import TabBarFeature
import Dependency
import netfox
import UserNotifications
import FLEX

@main
class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    var app: AppCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestNotificationPermission()
        
        window = .init(frame: UIScreen.main.bounds)
        
        let nav = UINavigationController()
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        
        
        //MARK: set coordinator
        
        let homeDependency = HomeModule()
        let profileDependency = ProfileModule()
        let calenderDependency = CalenderModule()
        let focusDependency = FocusModule()
        
        let tabBarDependency = TabBarModule(homeDependency: homeDependency,calenderDependency: calenderDependency, focusDependency: focusDependency, profileDependency: profileDependency)
        let authDependency = AuthenticationModule(tabBarDependency: tabBarDependency)
        
        app = AppCoordinator(profileDependency: profileDependency,
                             homeDependency: homeDependency,
                             authDependency: authDependency,
                             tabBarDependency: tabBarDependency,
                             navigationController: nav)
        app?.start()
        return true
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "snoozeAction":
            // Handle snooze action
            break
        case "cancelAction":
            // Handle cancel action
            break
        default:
            // Handle default action
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle foreground presentation options
        completionHandler([.banner, .list, .sound, .badge])
    }
}

// MARK: Notification Locals
extension AppDelegate {
    
    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Don't forget to check your tasks!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        let request = UNNotificationRequest(identifier: "reminderNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    func scheduleNotificationWithActions() {
        let content = UNMutableNotificationContent()
        content.title = "Meeting Reminder"
        content.body = "Your meeting starts in 10 minutes!"
        content.sound = UNNotificationSound.default
        
        let action1 = UNNotificationAction(identifier: "snoozeAction", title: "Snooze", options: [])
        let action2 = UNNotificationAction(identifier: "cancelAction", title: "Cancel", options: [.destructive])
        
        let category = UNNotificationCategory(identifier: "meetingCategory", actions: [action1, action2], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        content.categoryIdentifier = "meetingCategory"
        
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["meetingCategory"])
        
        center.removeAllPendingNotificationRequests()
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        let request = UNNotificationRequest(identifier: "meetingNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification with actions scheduled successfully")
            }
        }
    }
}


extension UIWindow {
    open override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // code you want to implement
        #if DEV || DEBUG
        if motion == .motionShake {
            guard let view = UIApplication.topViewController() else {
                return
            }
            
            if view.responds(to: Selector(("shouldForceLandscape"))) {
                // If the rootViewController should force landscape, do not handle shake
                return
            }
            showSimpleActionSheet(controller: view)
        }
        #endif
    }
    
    func showSimpleActionSheet(controller: UIViewController) {
        let alert = UIAlertController(title: "Debug", message: "show debug status", preferredStyle: .actionSheet)
        
        #if DEBUG
        alert.addAction(UIAlertAction(title: "NETWORK DEBUG", style: .default, handler: { _ in
            NFX.sharedInstance().start()
        }))
        #endif
        
        #if DEV || DEBUG
        alert.addAction(UIAlertAction(title: "UI DEBUGGING 😮‍💨", style: .default, handler: { _ in
            FLEXManager.shared.showExplorer()
        }))
        
        alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel, handler: nil))
        
        controller.present(alert, animated: true, completion: {})
        #endif
    }
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.firstKeyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    var firstKeyWindow: UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes
            .filter { $0.activationState == .foregroundActive }
        let firstActiveScene = activeScene.first
        let keyWindow = firstActiveScene?.keyWindow
        return keyWindow
    }
}

