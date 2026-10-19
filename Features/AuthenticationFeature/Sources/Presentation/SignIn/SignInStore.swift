//
//  SignInStore.swift
//  AuthenticationFeature · Presentation
//
import Foundation
import Utility

struct SignInState: Equatable {
    var email = ""
    var password = ""
    var isLoading = false
    var isGoogleLoading = false
    var errorMessage: String?

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }
}

enum SignInAction {
    // Dari user
    case emailChanged(String)
    case passwordChanged(String)
    case submitTapped
    case signUpTapped
    case forgotPasswordTapped
    // Hasil effect
    case loginResponse(Result<UserSession, AuthError>)
    case googleTapped
    case googleResponse(Result<UserSession, AuthError>)
}

enum SignInRoute {
    case signUp
    case forgotPassword(email: String)
    case authenticated(UserSession)
}

final class SignInStore: Store<SignInState, SignInAction> {
    private let login: LoginUseCase
    private let google: GoogleSignInUseCase
    /// Diset oleh Module (routing). Store tidak tahu soal UIKit/Router.
    var onRoute: ((SignInRoute) -> Void)?

    init(login: LoginUseCase, google: GoogleSignInUseCase, initialState: SignInState = SignInState()) {
        self.login = login
        self.google = google
        super.init(initialState: initialState)
    }

    override func reduce(state: inout SignInState, action: SignInAction) -> Effect<SignInAction>? {
        switch action {
        case .emailChanged(let email):
            state.email = email
            state.errorMessage = nil
            return nil

        case .passwordChanged(let password):
            state.password = password
            state.errorMessage = nil
            return nil

        case .submitTapped:
            guard state.canSubmit, !state.isGoogleLoading else { return nil }
            state.isLoading = true
            state.errorMessage = nil
            let (email, password, login) = (state.email, state.password, self.login)
            return .task {
                do {
                    let session = try await login.execute(email: email, password: password)
                    return .loginResponse(.success(session))
                } catch {
                    return .loginResponse(.failure(error as? AuthError ?? .unknown))
                }
            }

        case .signUpTapped:
            return .run { [weak self] in self?.onRoute?(.signUp) }

        case .forgotPasswordTapped:
            let email = state.email
            return .run { [weak self] in self?.onRoute?(.forgotPassword(email: email)) }

        case .loginResponse(.success(let session)):
            state.isLoading = false
            return .run { [weak self] in self?.onRoute?(.authenticated(session)) }

        case .loginResponse(.failure(let error)):
            state.isLoading = false
            state.errorMessage = error.errorDescription
            return nil

        case .googleTapped:
            guard !state.isLoading, !state.isGoogleLoading else { return nil }
            state.isGoogleLoading = true
            state.errorMessage = nil
            let google = self.google
            return .task { @MainActor in
                do {
                    return .googleResponse(.success(try await google.execute()))
                } catch {
                    return .googleResponse(.failure(error as? AuthError ?? .googleFailed))
                }
            }

        case .googleResponse(.success(let session)):
            state.isGoogleLoading = false
            return .run { [weak self] in self?.onRoute?(.authenticated(session)) }

        case .googleResponse(.failure(let error)):
            state.isGoogleLoading = false
            // Sheet ditutup user → diam saja.
            state.errorMessage = error == .googleCancelled ? nil : error.errorDescription
            return nil
        }
    }
}
