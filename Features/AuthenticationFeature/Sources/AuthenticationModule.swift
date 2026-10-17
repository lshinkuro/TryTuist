//
//  AuthenticationModule.swift
//  AuthenticationFeature
//
//  Composition root feature Auth:
//  1. Merakit dependency (DataSource → Repository → UseCase → Store).
//  2. Routing: Splash → (Onboarding pertama kali) → Sign In ⇄ Sign Up → selesai.
//  Setiap screen punya Store; module hanya menerjemahkan Route menjadi navigasi.
//
import SwiftUI
import Navigation
import TTUI
import Utility

@MainActor
public final class AuthenticationModule {
    private let router: Router
    private let onAuthenticated: () -> Void
    private let repository: AuthRepository

    public init(router: Router, onAuthenticated: @escaping () -> Void) {
        self.router = router
        self.onAuthenticated = onAuthenticated
        self.repository = DefaultAuthRepository(remote: Self.makeRemoteDataSource())
    }

    private static func makeRemoteDataSource() -> AuthRemoteDataSource {
        if AppConfig.useMockData { return AuthMockDataSource() }
        return AuthAPIDataSource()
    }

    /// - Parameter showSplash: `false` saat kembali dari logout (langsung ke Sign In).
    public func start(showSplash: Bool = true) {
        guard showSplash else {
            showSignIn(animated: false)
            return
        }
        let store = SplashStore(title: String.localized("coachmark.first_title"))
        store.onRoute = { [weak self] destination in
            switch destination {
            case .main: self?.onAuthenticated()
            case .onboarding: self?.showOnboarding()
            case .signIn: self?.showSignIn(animated: true)
            }
        }
        router.setRoot(SplashScreenView(store: store), hidesNavigationBar: true)
    }

    // MARK: - Routes

    private func showOnboarding() {
        let store = OnboardingStore()
        store.onRoute = { [weak self] route in
            switch route {
            case .finished: self?.showSignIn(animated: true)
            }
        }
        router.setRoot(OnBoardingView(store: store), hidesNavigationBar: true, animated: true)
    }

    private func showSignIn(animated: Bool) {
        let store = SignInStore(login: LoginUseCase(repository: repository), initialState: Self.signInPrefill)
        store.onRoute = { [weak self] route in
            switch route {
            case .signUp: self?.showSignUp()
            case .authenticated: self?.onAuthenticated()
            }
        }
        router.setRoot(SignInView(store: store), hidesNavigationBar: true, animated: animated)
    }

    private func showSignUp() {
        let store = SignUpStore(register: RegisterUseCase(repository: repository))
        store.onRoute = { [weak self] route in
            switch route {
            case .backToSignIn: self?.router.pop()
            case .authenticated: self?.onAuthenticated()
            }
        }
        router.push(SignUpView(store: store))
    }

    #if DEBUG
    /// Prefill akun mock supaya cepat saat development.
    private static let signInPrefill = SignInState(email: "kholis@gmail.com", password: "12345678")
    #else
    private static let signInPrefill = SignInState()
    #endif
}
