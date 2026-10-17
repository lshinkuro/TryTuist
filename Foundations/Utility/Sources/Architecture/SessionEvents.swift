//
//  SessionEvents.swift
//  Utility
//
//  Sinyal global "sesi login habis". Dikirim NetworkManager saat endpoint yang
//  butuh login membalas 401; diterima AppRouter → bottom sheet → halaman login.
//  Feature tidak perlu menangani 401 sendiri untuk navigasi.
//
import Foundation

public extension Notification.Name {
    static let sessionExpired = Notification.Name("TryTuist.sessionExpired")
}

public enum SessionEvents {
    /// Aman dipanggil dari thread mana pun; notifikasi selalu dikirim di main thread.
    public static func postExpired(path: String? = nil) {
        let post = {
            NotificationCenter.default.post(name: .sessionExpired, object: nil,
                                            userInfo: path.map { ["path": $0] })
        }
        Thread.isMainThread ? post() : DispatchQueue.main.async(execute: post)
    }
}
