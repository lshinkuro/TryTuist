//
//  LocalRestockReminderScheduler.swift
//  HomeFeature · Data
//
//  Notifikasi lokal "waktunya beli lagi". Tap → AppDelegate membuka detail produk
//  (`CatalogNotifications.restockProductIDKey`).
//
import Foundation
import UserNotifications

struct LocalRestockReminderScheduler: RestockReminderScheduler {
    private static let identifierPrefix = "restock."

    func schedule(_ reminders: [RestockReminder]) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let old = requests.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: old)
            for reminder in reminders {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "Waktunya beli \(reminder.name) lagi?")
                content.body = String(localized: "Biasanya kamu beli sekitar waktu ini. Tap untuk pesan.")
                content.sound = .default
                content.userInfo = [CatalogNotifications.restockProductIDKey: reminder.productID]
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                center.add(UNNotificationRequest(identifier: Self.identifierPrefix + reminder.productID,
                                                 content: content, trigger: trigger))
            }
        }
    }
}
