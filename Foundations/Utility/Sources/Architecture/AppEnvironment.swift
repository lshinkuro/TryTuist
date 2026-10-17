//
//  AppEnvironment.swift
//  Utility
//
//  Environment aktif (Dev / Staging / Prod) dibaca dari Info.plist,
//  yang nilainya diisi build setting di Configs/<Env>.xcconfig.
//  Pilih environment dengan memilih scheme: TryTuist-Dev / -Staging / -Prod.
//
import Foundation

public enum AppEnvironment: String {
    case dev
    case staging
    case prod

    /// Environment dari build yang sedang berjalan. Default `.dev` bila key tidak ada.
    public static let current: AppEnvironment = {
        AppEnvironment(rawValue: value(for: "APP_ENV")?.lowercased() ?? "") ?? .dev
    }()

    /// Contoh: "http://localhost:8080" (Dev) atau "https://api.trytuist.com" (Prod).
    public static let apiBaseURL: String = value(for: "API_BASE_URL") ?? "http://localhost:8080"

    public static let apiKey: String = value(for: "API_KEY") ?? ""

    /// `USE_MOCK_DATA = YES` di xcconfig → semua repository memakai Mock data source.
    public static let useMockData: Bool = (value(for: "USE_MOCK_DATA") ?? "YES").uppercased() == "YES"

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
