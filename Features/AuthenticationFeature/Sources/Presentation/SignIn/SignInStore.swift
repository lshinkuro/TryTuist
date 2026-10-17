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
    // Hasil effect
    case loginResponse(Result<UserSession, AuthError>)
}

enum SignInRoute {
    case signUp
    case authenticated(UserSession)
}

final class SignInStore: Store<SignInState, SignInAction> {
    private let login: LoginUseCase
    /// Diset oleh Module (routing). Store tidak tahu soal UIKit/Router.
    var onRoute: ((SignInRoute) -> Void)?

    init(login: LoginUseCase, initialState: SignInState = SignInState()) {
        self.login = login
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
            guard state.canSubmit else { return nil }
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

        case .loginResponse(.success(let session)):
            state.isLoading = false
            return .run { [weak self] in self?.onRoute?(.authenticated(session)) }

        case .loginResponse(.failure(let error)):
            state.isLoading = false
            state.errorMessage = error.errorDescription
            return nil
        }
    }
}
