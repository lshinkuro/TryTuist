//
//  SignUpStore.swift
//  AuthenticationFeature · Presentation
//
import Foundation
import Utility

struct SignUpState: Equatable {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var isGoogleLoading = false
    var errorMessage: String?

    // Pesan validasi baru muncul setelah user mulai mengetik.
    var emailError: String? {
        guard !email.isEmpty, !CredentialValidator.isValidEmail(email) else { return nil }
        return AuthError.invalidEmail.errorDescription
    }

    var passwordError: String? {
        guard !password.isEmpty, !CredentialValidator.isStrongPassword(password) else { return nil }
        return AuthError.weakPassword.errorDescription
    }

    var confirmError: String? {
        guard !confirmPassword.isEmpty, confirmPassword != password else { return nil }
        return String(localized: "Password tidak sama.")
    }

    var canSubmit: Bool {
        CredentialValidator.isValidEmail(email)
            && CredentialValidator.isStrongPassword(password)
            && confirmPassword == password
            && !isLoading
    }
}

enum SignUpAction {
    case emailChanged(String)
    case passwordChanged(String)
    case confirmPasswordChanged(String)
    case submitTapped
    case signInTapped
    case registerResponse(Result<UserSession, AuthError>)
    case googleTapped
    case googleResponse(Result<UserSession, AuthError>)
}

enum SignUpRoute {
    case backToSignIn
    case authenticated(UserSession)
}

final class SignUpStore: Store<SignUpState, SignUpAction> {
    private let register: RegisterUseCase
    private let google: GoogleSignInUseCase
    var onRoute: ((SignUpRoute) -> Void)?

    init(register: RegisterUseCase, google: GoogleSignInUseCase) {
        self.register = register
        self.google = google
        super.init(initialState: SignUpState())
    }

    override func reduce(state: inout SignUpState, action: SignUpAction) -> Effect<SignUpAction>? {
        switch action {
        case .emailChanged(let value):
            state.email = value
            state.errorMessage = nil
            return nil

        case .passwordChanged(let value):
            state.password = value
            state.errorMessage = nil
            return nil

        case .confirmPasswordChanged(let value):
            state.confirmPassword = value
            return nil

        case .submitTapped:
            guard state.canSubmit, !state.isGoogleLoading else { return nil }
            state.isLoading = true
            state.errorMessage = nil
            let (email, password, register) = (state.email, state.password, self.register)
            return .task {
                do {
                    let session = try await register.execute(email: email, password: password)
                    return .registerResponse(.success(session))
                } catch {
                    return .registerResponse(.failure(error as? AuthError ?? .unknown))
                }
            }

        case .signInTapped:
            return .run { [weak self] in self?.onRoute?(.backToSignIn) }

        case .registerResponse(.success(let session)):
            state.isLoading = false
            return .run { [weak self] in self?.onRoute?(.authenticated(session)) }

        case .registerResponse(.failure(let error)):
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
