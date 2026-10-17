//
//  TokenStorage.swift
//  Utility
//
import Foundation
import Security

/// Penyimpanan auth token di Keychain.
public enum TokenStorage {
    private static let account = "AuthToken"

    private static var baseQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account
        ]
    }

    @discardableResult
    public static func save(_ token: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else { return false }
        // Hapus token lama dulu supaya SecItemAdd tidak gagal karena duplikat.
        SecItemDelete(baseQuery as CFDictionary)
        var query = baseQuery
        query[kSecValueData] = tokenData
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Access token untuk header `Authorization: Bearer <token>`.
    public static var token: String? {
        var query = baseQuery
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne
        var tokenData: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &tokenData) == errSecSuccess,
              let data = tokenData as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static var hasToken: Bool {
        var query = baseQuery
        query[kSecReturnData] = kCFBooleanTrue
        var tokenData: AnyObject?
        return SecItemCopyMatching(query as CFDictionary, &tokenData) == errSecSuccess
    }

    @discardableResult
    public static func delete() -> Bool {
        SecItemDelete(baseQuery as CFDictionary) == errSecSuccess
    }
}
