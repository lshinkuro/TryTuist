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
    private let googleClient: GoogleSignInClient

    public init(router: Router, onAuthenticated: @escaping () -> Void) {
        self.router = router
        self.onAuthenticated = onAuthenticated
        self.repository = DefaultAuthRepository(remote: Self.makeRemoteDataSource())
        self.googleClient = AppConfig.useMockData ? MockGoogleSignInClient() : GoogleSDKSignInClient()
    }

    private static func makeRemoteDataSource() -> AuthRemoteDataSource {
        if AppConfig.useMockData { return AuthMockDataSource() }
        return AuthAPIDataSource()
    }

    /// Tombol Google di Sign In & Sign Up memakai use case yang sama (backend yang memutuskan daftar / masuk).
    private var googleSignIn: GoogleSignInUseCase {
        GoogleSignInUseCase(client: googleClient, repository: repository)
    }

    /// Titik masuk flow Auth. Selain `.splash` dipakai Debugger untuk lompat langsung ke screen.
    public enum Entry {
        case splash
        case onboarding
        case signIn
        case signUp
    }

    /// - Parameter showSplash: `false` saat kembali dari logout (langsung ke Sign In).
    public func start(showSplash: Bool = true) {
        start(at: showSplash ? .splash : .signIn)
    }

    public func start(at entry: Entry) {
        switch entry {
        case .splash: showSplash()
        case .onboarding: showOnboarding()
        case .signIn: showSignIn(animated: false)
        case .signUp:
            showSignIn(animated: false)
            showSignUp()
        }
    }

    // MARK: - Routes

    private func showSplash() {
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
        let store = SignInStore(login: LoginUseCase(repository: repository), google: googleSignIn,
                                initialState: Self.signInPrefill)
        store.onRoute = { [weak self] route in
            switch route {
            case .signUp: self?.showSignUp()
            case .forgotPassword(let email): self?.showForgotPassword(email: email)
            case .authenticated: self?.onAuthenticated()
            }
        }
        router.setRoot(SignInView(store: store), hidesNavigationBar: true, animated: animated)
    }

    private func showSignUp() {
        let store = SignUpStore(register: RegisterUseCase(repository: repository), google: googleSignIn)
        store.onRoute = { [weak self] route in
            switch route {
            case .backToSignIn: self?.router.pop()
            case .authenticated: self?.onAuthenticated()
            }
        }
        router.push(SignUpView(store: store))
    }

    private func showForgotPassword(email: String) {
        let store = ForgotPasswordStore(requestReset: RequestPasswordResetUseCase(repository: repository),
                                        resetPassword: ResetPasswordUseCase(repository: repository),
                                        email: email)
        store.onRoute = { [weak self] route in
            switch route {
            case .back: self?.router.pop()
            case .authenticated: self?.onAuthenticated()
            }
        }
        router.push(ForgotPasswordView(store: store))
    }

    #if DEBUG
    /// Prefill akun mock supaya cepat saat development.
    private static let signInPrefill = SignInState(email: "kholis@gmail.com", password: "12345678")
    #else
    private static let signInPrefill = SignInState()
    #endif
}
