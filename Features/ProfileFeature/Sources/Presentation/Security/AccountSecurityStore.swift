//
//  AccountSecurityStore.swift
//  ProfileFeature · Presentation
//
//  Keamanan Akun: verifikasi email (wajib untuk memesan) & ganti password.
//
import Foundation
import TTUI
import Utility

struct AccountSecurityState: Equatable {
    let email: String
    var emailVerified: Bool
    let hasPassword: Bool
    var code = ""
    var currentPassword = ""
    var newPassword = ""
    var isVerifying = false
    var isSending = false
    var isSaving = false
    var fieldErrors: [String: String] = [:]
    var toast: ToastMessage?

    var canVerify: Bool { code.count == 6 && !isVerifying }
    var canSavePassword: Bool { newPassword.count >= 8 && (!hasPassword || !currentPassword.isEmpty) && !isSaving }
}

enum AccountSecurityAction {
    case codeChanged(String)
    case verifyTapped
    case resendTapped
    case currentPasswordChanged(String)
    case newPasswordChanged(String)
    case savePasswordTapped
    case verifyResponse(Result<Void, ProfileError>)
    case resendResponse(Result<Void, ProfileError>)
    case passwordResponse(Result<Void, ProfileError>)
    case toastDismissed(UUID)
}

final class AccountSecurityStore: Store<AccountSecurityState, AccountSecurityAction> {
    private let repository: AccountSecurityRepository

    init(profile: UserProfile, repository: AccountSecurityRepository) {
        self.repository = repository
        super.init(initialState: AccountSecurityState(email: profile.email, emailVerified: profile.emailVerified,
                                                      hasPassword: profile.hasPassword))
    }

    override func reduce(state: inout AccountSecurityState, action: AccountSecurityAction) -> Effect<AccountSecurityAction>? {
        let repository = self.repository
        switch action {
        case .codeChanged(let code):
            state.code = String(code.filter(\.isNumber).prefix(6))
            return nil

        case .verifyTapped:
            guard state.canVerify else { return nil }
            state.isVerifying = true
            let code = state.code
            return .task { await .verifyResponse(Self.result { try await repository.verifyEmail(code: code) }) }

        case .resendTapped:
            guard !state.isSending else { return nil }
            state.isSending = true
            return .task { await .resendResponse(Self.result { try await repository.sendEmailVerification() }) }

        case .currentPasswordChanged(let text):
            state.currentPassword = text
            state.fieldErrors["current_password"] = nil
            return nil

        case .newPasswordChanged(let text):
            state.newPassword = text
            state.fieldErrors["new_password"] = nil
            return nil

        case .savePasswordTapped:
            guard state.canSavePassword else { return nil }
            state.isSaving = true
            state.fieldErrors = [:]
            let (current, new) = (state.currentPassword, state.newPassword)
            return .task { await .passwordResponse(Self.result { try await repository.changePassword(current: current, new: new) }) }

        case .verifyResponse(.success):
            state.isVerifying = false
            state.emailVerified = true
            return toast(&state, ToastMessage(String(localized: "Email terverifikasi")))

        case .resendResponse(.success):
            state.isSending = false
            return toast(&state, ToastMessage(String(localized: "Kode baru dikirim ke \(state.email)")))

        case .passwordResponse(.success):
            state.isSaving = false
            state.currentPassword = ""
            state.newPassword = ""
            return toast(&state, ToastMessage(String(localized: "Password diperbarui. Perangkat lain sudah dikeluarkan.")))

        case .verifyResponse(.failure(let error)), .resendResponse(.failure(let error)), .passwordResponse(.failure(let error)):
            state.isVerifying = false
            state.isSending = false
            state.isSaving = false
            state.fieldErrors = error.fieldErrors
            guard error.fieldErrors.isEmpty else { return nil }
            return toast(&state, .error(error.errorDescription ?? ""))

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func toast(_ state: inout AccountSecurityState, _ toast: ToastMessage) -> Effect<AccountSecurityAction> {
        state.toast = toast
        return dismissToast(id: toast.id) { .toastDismissed($0) }
    }

    private static func result(_ work: () async throws -> Void) async -> Result<Void, ProfileError> {
        do {
            try await work()
            return .success(())
        } catch {
            return .failure(error as? ProfileError ?? .unknown)
        }
    }
}
