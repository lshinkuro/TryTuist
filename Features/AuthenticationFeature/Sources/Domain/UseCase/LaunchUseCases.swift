//
//  LaunchUseCases.swift
//  AuthenticationFeature · Domain
//
//  Aturan saat app dibuka: ke mana user diarahkan setelah splash.
//
import Foundation
import Utility

enum LaunchDestination: Equatable {
    case main
    case onboarding
    case signIn
}

struct GetLaunchDestinationUseCase {
    var hasSession: () -> Bool = { TokenStorage.hasToken }
    var isFirstLaunch: () -> Bool = { AppSetting.shared.isFirstTime }
    /// Flag in-memory: `true` hanya jika user sudah login di sesi proses yang sedang berjalan.
    /// Selalu `false` saat app baru dibuka (setelah di-kill), sehingga user harus login ulang.
    var isSessionActive: () -> Bool = { AppSetting.shared.isSessionActive }

    func execute() -> LaunchDestination {
        // Token ada di Keychain, tapi session belum aktif → proses baru (app di-kill) → login ulang
        if hasSession() && isSessionActive() { return .main }
        if isFirstLaunch() { return .onboarding }
        return .signIn
    }
}

struct CompleteOnboardingUseCase {
    var markAsSeen: () -> Void = { AppSetting.shared.isFirstTime = false }

    func execute() {
        markAsSeen()
    }
}
