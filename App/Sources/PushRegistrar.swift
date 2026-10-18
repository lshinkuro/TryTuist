//
//  PushRegistrar.swift
//  TryTuist
//
//  Notifikasi push (APNs, API_PLAN.md §5.28):
//  - Token APNs dari AppDelegate disimpan, lalu dikirim ke backend (`PUT /v1/me/devices`) selama user login.
//  - Sesi berakhir (logout, sesi habis, cold start) → `POST /v1/devices/unregister` supaya device
//    tidak menerima notifikasi pesanan akun sebelumnya.
//  - Tap notifikasi pesanan / pembayaran → tab Pesanan.
//
import Foundation
import UIKit
import NetworkManager
import Utility

@MainActor
final class PushRegistrar {
    static let shared = PushRegistrar()

    private static let tokenKey = "push.apnsDeviceToken"
    private let api: APIManager
    private let defaults: UserDefaults
    private var isLoggedIn = false
    /// Tap notifikasi sebelum tab bar siap (mis. app dibuka dari notifikasi lalu login dulu).
    private(set) var pendingOpenOrders = false

    /// Diisi AppRouter: pindah ke tab Pesanan.
    var onOpenOrders: (() -> Void)?

    init(api: APIManager = .shared, defaults: UserDefaults = .standard) {
        self.api = api
        self.defaults = defaults
    }

    private var deviceToken: String? {
        get { defaults.string(forKey: Self.tokenKey) }
        set { defaults.set(newValue, forKey: Self.tokenKey) }
    }

    /// Build Debug memakai APNs sandbox (entitlement `aps-environment = development`).
    private var environment: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    // MARK: - Dari AppDelegate

    func didRegister(deviceToken data: Data) {
        let token = data.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        // Selalu kirim saat login: memperbarui last_seen_at / memindahkan token dari akun lain.
        if isLoggedIn { send() }
    }

    func didFailToRegister(_ error: Error) {
        // Simulator lama / tanpa akun Apple Developer berbayar: push tidak tersedia, app tetap jalan.
        print("APNs: gagal mendaftar — \(error.localizedDescription)")
    }

    /// Tap pada notifikasi.
    func handleTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String,
              ["payment_paid", "order_status"].contains(type) else { return }   // lainnya cukup membuka app
        if isLoggedIn, let onOpenOrders {
            onOpenOrders()
        } else {
            pendingOpenOrders = true
        }
    }

    func consumePendingOpenOrders() -> Bool {
        defer { pendingOpenOrders = false }
        return pendingOpenOrders
    }

    // MARK: - Dari AppRouter

    /// Setelah login / tab bar tampil.
    func sessionStarted() {
        isLoggedIn = true
        send()
    }

    /// Sebelum / sesudah token sesi dihapus. Tidak butuh login.
    func sessionEnded() {
        isLoggedIn = false
        guard !AppConfig.useMockData, let token = deviceToken else { return }
        let api = self.api
        Task {
            _ = try? await api.send(.unregisterDevice(token: token), as: APIEnvelope<EmptyDTO>.self)
        }
    }

    private func send() {
        guard !AppConfig.useMockData, TokenStorage.hasToken, let token = deviceToken,
              let bundleID = Bundle.main.bundleIdentifier else { return }
        let param = RegisterDeviceParam(token: token, bundleID: bundleID, environment: environment)
        let api = self.api
        Task {
            do {
                _ = try await api.send(.registerDevice(param: param), as: APIEnvelope<EmptyDTO>.self)
            } catch {
                print("Push: gagal mendaftarkan device — \(error.localizedDescription)")
            }
        }
    }
}
