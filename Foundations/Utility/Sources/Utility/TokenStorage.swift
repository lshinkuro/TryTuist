//
//  TokenStorage.swift
//  Utility
//
//  Sesi login di Keychain: access token, refresh token, dan waktu habis access token.
//  Keychain tetap ada walau app di-kill / device restart, jadi user tidak perlu login ulang.
//  Access token (15 menit) diperbarui otomatis oleh NetworkManager memakai refresh token (30 hari).
//
import Foundation
import Security

public enum TokenStorage {
    private enum Item: String, CaseIterable {
        case accessToken = "AuthToken"           // nama lama, supaya sesi yang sudah tersimpan tetap terbaca
        case refreshToken = "AuthRefreshToken"
        case expiresAt = "AuthTokenExpiresAt"    // unix detik
    }

    // MARK: - Simpan

    /// Simpan sesi lengkap dari login / register / Google / refresh.
    @discardableResult
    public static func saveSession(accessToken: String, refreshToken: String, expiresAt: Date) -> Bool {
        let saved = write(accessToken, to: .accessToken)
        if refreshToken.isEmpty {
            remove(.refreshToken)
        } else {
            write(refreshToken, to: .refreshToken)
        }
        if expiresAt == .distantFuture {
            remove(.expiresAt)
        } else {
            write(String(Int(expiresAt.timeIntervalSince1970)), to: .expiresAt)
        }
        return saved
    }

    /// Hanya access token (tanpa refresh). Dipertahankan untuk kode lama.
    @discardableResult
    public static func save(_ token: String) -> Bool {
        write(token, to: .accessToken)
    }

    // MARK: - Baca

    /// Access token untuk header `Authorization: Bearer <token>`.
    public static var token: String? { read(.accessToken) }

    public static var refreshToken: String? { read(.refreshToken).flatMap { $0.isEmpty ? nil : $0 } }

    /// `nil` bila tidak diketahui (mis. sesi dari versi app lama).
    public static var expiresAt: Date? {
        read(.expiresAt).flatMap(TimeInterval.init).map(Date.init(timeIntervalSince1970:))
    }

    /// Masih punya sesi: access token, atau refresh token untuk memperbaruinya.
    public static var hasToken: Bool { token != nil || refreshToken != nil }

    /// Access token sudah (hampir) habis → perbarui dulu sebelum request. `leeway` menghindari
    /// token yang habis di tengah jalan.
    public static func isAccessTokenExpired(leeway: TimeInterval = 30, now: Date = Date()) -> Bool {
        guard token != nil else { return true }
        guard let expiresAt else { return false }
        return expiresAt.addingTimeInterval(-leeway) <= now
    }

    // MARK: - Hapus

    /// Logout / sesi tidak berlaku: hapus semua item sesi.
    @discardableResult
    public static func delete() -> Bool {
        var deleted = false
        for item in Item.allCases where remove(item) {
            deleted = true
        }
        return deleted
    }

    // MARK: - Keychain

    private static func query(_ item: Item) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrAccount: item.rawValue]
    }

    @discardableResult
    private static func write(_ value: String, to item: Item) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        // Hapus nilai lama dulu supaya SecItemAdd tidak gagal karena duplikat.
        SecItemDelete(query(item) as CFDictionary)
        var attributes = query(item)
        attributes[kSecValueData] = data
        // Bisa dibaca setelah device dibuka sekali sejak restart (juga saat app dibangunkan di background).
        attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    private static func read(_ item: Item) -> String? {
        var q = query(item)
        q[kSecReturnData] = kCFBooleanTrue
        q[kSecMatchLimit] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func remove(_ item: Item) -> Bool {
        SecItemDelete(query(item) as CFDictionary) == errSecSuccess
    }
}
