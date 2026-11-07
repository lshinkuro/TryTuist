//
//  OrderLiveActivity.swift
//  Utility
//
//  Mulai saat pesanan dibuat (Keranjang), diperbarui saat app memuat status pesanan (tab Pesanan).
//  shortcut: update hanya saat app terbuka; supaya Lock Screen berubah saat app di background,
//  backend perlu mengirim push Live Activity (token dari `Activity.pushTokenUpdates`).
//
import ActivityKit
import Foundation

public enum OrderLiveActivity {
    /// Diterima → Diproses → Diantar → Selesai; `nil` = batal / gagal.
    public static func step(for rawStatus: String) -> Int? {
        switch rawStatus {
        case "PENDING", "PAID": return 0
        case "PROCESSING": return 1
        case "DELIVERING": return 2
        case "COMPLETED", "DONE": return 3
        default: return nil
        }
    }

    public static func start(orderID: String, orderNumber: String, storeName: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity(for: orderID) == nil else { return }
        let state = OrderActivityAttributes.ContentState(step: 0, title: String(localized: "Pesanan diterima"))
        _ = try? Activity.request(attributes: OrderActivityAttributes(orderID: orderID, orderNumber: orderNumber, storeName: storeName),
                                  content: ActivityContent(state: state, staleDate: nil))
    }

    /// Pesanan selesai / batal / gagal → aktivitas diakhiri (tetap terlihat 15 menit).
    public static func update(orderID: String, rawStatus: String, title: String, arrivalEnd: Date?) {
        guard let activity = activity(for: orderID) else { return }
        let step = step(for: rawStatus)
        let state = OrderActivityAttributes.ContentState(step: step ?? 0, title: title,
                                                         arrivalEnd: step.map { $0 < 3 } == true ? arrivalEnd : nil)
        Task {
            if let step, step < 3 {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            } else {
                await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(.now + 15 * 60))
            }
        }
    }

    private static func activity(for orderID: String) -> Activity<OrderActivityAttributes>? {
        Activity<OrderActivityAttributes>.activities.first { $0.attributes.orderID == orderID }
    }
}
