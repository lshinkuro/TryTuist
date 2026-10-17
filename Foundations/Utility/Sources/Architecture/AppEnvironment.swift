//
//  AppEnvironment.swift
//  Utility
//
//  Ada dua lapis environment:
//  1. Build  — dari Info.plist (diisi Configs/<Env>.xcconfig lewat scheme TryTuist-Dev/-Staging/-Prod).
//  2. Override runtime — dipilih dari Debugger (shake device). Disimpan di UserDefaults
//     dan otomatis DIABAIKAN di build Prod, jadi app store selalu memakai nilai build.
//
//  Semua kode lain cukup membaca `AppEnvironment.current / apiBaseURL / apiKey / useMockData`.
//
import Foundation

public enum AppEnvironment: String, CaseIterable, Codable {
    case dev
    case staging
    case prod

    // MARK: - Build (tidak berubah selama app berjalan)

    /// Environment dari scheme yang di-build. Default `.dev` bila key tidak ada.
    public static let build: AppEnvironment = {
        AppEnvironment(rawValue: value(for: "APP_ENV")?.lowercased() ?? "") ?? .dev
    }()

    public static let buildBaseURL: String = value(for: "API_BASE_URL") ?? "http://localhost:8080"
    public static let buildAPIKey: String = value(for: "API_KEY") ?? ""
    /// `USE_MOCK_DATA = YES` di xcconfig → semua repository memakai Mock data source.
    public static let buildUseMockData: Bool = (value(for: "USE_MOCK_DATA") ?? "YES").uppercased() == "YES"

    /// Debugger (shake) hanya tersedia di build selain Prod.
    public static var isDebugToolsEnabled: Bool { !build.isProduction }

    // MARK: - Aktif (build + override dari Debugger)

    /// Environment API yang sedang dipakai.
    public static var current: AppEnvironment { APIOverride.current?.environment ?? build }
    /// Contoh: "http://localhost:8080" (Dev) atau "https://api.trytuist.com" (Prod).
    public static var apiBaseURL: String { APIOverride.current?.baseURL ?? buildBaseURL }
    public static var apiKey: String { APIOverride.current?.apiKey ?? buildAPIKey }
    public static var useMockData: Bool { APIOverride.current?.useMockData ?? buildUseMockData }
    public static var isOverridden: Bool { APIOverride.current != nil }

    // MARK: - Info

    public var displayName: String {
        switch self {
        case .dev: return "DEV"
        case .staging: return "STAGING"
        case .prod: return "PROD"
        }
    }

    public var isProduction: Bool { self == .prod }

    private static func value(for key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // "$(VAR)" berarti build setting belum terisi (xcconfig tidak terpasang).
        return trimmed.isEmpty || trimmed.hasPrefix("$(") ? nil : trimmed
    }
}

/// Konfigurasi API pengganti yang dipilih dari Debugger.
public struct APIOverride: Codable, Equatable {
    public var environment: AppEnvironment
    public var baseURL: String
    public var apiKey: String
    public var useMockData: Bool

    public init(environment: AppEnvironment, baseURL: String, apiKey: String, useMockData: Bool) {
        self.environment = environment
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.useMockData = useMockData
    }

    private static let storageKey = "debug.apiOverride"
    /// `.none` = belum dibaca dari UserDefaults; `.some(nil)` = sudah dibaca, tidak ada override.
    nonisolated(unsafe) private static var cache: APIOverride??

    /// `nil` = pakai nilai build. Selalu `nil` di build Prod.
    public static var current: APIOverride? {
        guard AppEnvironment.isDebugToolsEnabled else { return nil }
        if let cache { return cache }
        let loaded = UserDefaults.standard.data(forKey: storageKey)
            .flatMap({ try? JSONDecoder().decode(APIOverride.self, from: $0) })
        cache = .some(loaded)
        return loaded
    }

    /// Simpan override. `nil` = kembali ke nilai build.
    public static func save(_ value: APIOverride?) {
        guard AppEnvironment.isDebugToolsEnabled else { return }
        if let value, let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
        cache = .some(value)
    }
}
