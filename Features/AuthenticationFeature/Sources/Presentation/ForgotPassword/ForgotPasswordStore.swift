//
//  ForgotPasswordStore.swift
//  AuthenticationFeature · Presentation
//
//  Dua langkah: email → (kode 6 digit dari email + password baru). Berhasil = langsung masuk.
//
import Foundation
import Utility

struct ForgotPasswordState: Equatable {
    enum Step: Equatable { case email, reset }

    var step: Step = .email
    var email = ""
    var code = ""
    var newPassword = ""
    var isLoading = false
    var errorMessage: String?

    var canSubmit: Bool {
        guard !isLoading else { return false }
        switch step {
        case .email: return !email.trimmingCharacters(in: .whitespaces).isEmpty
        case .reset: return code.count == 6 && !newPassword.isEmpty
        }
    }
}

enum ForgotPasswordAction {
    case emailChanged(String)
    case codeChanged(String)
    case newPasswordChanged(String)
    case submitTapped
    /// Kembali ke langkah email (ganti email / kirim ulang kode).
    case changeEmailTapped
    case backTapped
    case codeSent(Result<Void, AuthError>)
    case resetResponse(Result<UserSession, AuthError>)
}

enum ForgotPasswordRoute {
    case back
    case authenticated(UserSession)
}

final class ForgotPasswordStore: Store<ForgotPasswordState, ForgotPasswordAction> {
    private let requestReset: RequestPasswordResetUseCase
    private let resetPassword: ResetPasswordUseCase
    var onRoute: ((ForgotPasswordRoute) -> Void)?

    init(requestReset: RequestPasswordResetUseCase, resetPassword: ResetPasswordUseCase, email: String = "") {
        self.requestReset = requestReset
        self.resetPassword = resetPassword
        super.init(initialState: ForgotPasswordState(email: email))
    }

    override func reduce(state: inout ForgotPasswordState, action: ForgotPasswordAction) -> Effect<ForgotPasswordAction>? {
        switch action {
        case .emailChanged(let email):
            state.email = email
            state.errorMessage = nil
            return nil

        case .codeChanged(let code):
            state.code = String(code.filter(\.isNumber).prefix(6))
            state.errorMessage = nil
            return nil

        case .newPasswordChanged(let password):
            state.newPassword = password
            state.errorMessage = nil
            return nil

        case .submitTapped:
            guard state.canSubmit else { return nil }
            state.isLoading = true
            state.errorMessage = nil
            let email = state.email
            switch state.step {
            case .email:
                let requestReset = self.requestReset
                return .task {
                    do {
                        try await requestReset.execute(email: email)
                        return .codeSent(.success(()))
                    } catch {
                        return .codeSent(.failure(error as? AuthError ?? .unknown))
                    }
                }
            case .reset:
                let (code, password, resetPassword) = (state.code, state.newPassword, self.resetPassword)
                return .task {
                    do {
                        return .resetResponse(.success(try await resetPassword.execute(email: email, code: code, newPassword: password)))
                    } catch {
                        return .resetResponse(.failure(error as? AuthError ?? .unknown))
                    }
                }
            }

        case .changeEmailTapped:
            state.step = .email
            state.code = ""
            state.errorMessage = nil
            return nil

        case .backTapped:
            return .run { [weak self] in self?.onRoute?(.back) }

        case .codeSent(.success):
            state.isLoading = false
            state.step = .reset
            return nil

        case .codeSent(.failure(let error)), .resetResponse(.failure(let error)):
            state.isLoading = false
            state.errorMessage = error.errorDescription
            return nil

        case .resetResponse(.success(let session)):
            state.isLoading = false
            return .run { [weak self] in self?.onRoute?(.authenticated(session)) }
        }
    }
}
