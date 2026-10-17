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

    func execute() -> LaunchDestination {
        if hasSession() { return .main }
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
