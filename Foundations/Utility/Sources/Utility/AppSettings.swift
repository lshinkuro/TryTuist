//
//  AppSettings.swift
//  Utility
//
//  Created by Phincon on 19/08/24.
//

import Foundation

public final class AppSetting {
    public static let shared = AppSetting()

    private let defaults = UserDefaults.standard
    private init() {}

    /// `true` sampai user menyelesaikan onboarding.
    public var isFirstTime: Bool {
        get { defaults.object(forKey: "isFirstTime") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "isFirstTime") }
    }

    /// `true` selama proses app aktif (in-memory, tidak persisten).
    /// Otomatis `false` ketika app di-kill karena nilai ini tidak disimpan ke disk.
    /// Di-set ke `true` setelah login / register berhasil.
    public var isSessionActive: Bool = false
}
