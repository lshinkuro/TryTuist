//
//  SignUpView.swift
//  AuthenticationFeature · Presentation
//
import SwiftUI
import TTUI

struct SignUpView: View {
    @StateObject private var store: SignUpStore

    init(store: SignUpStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        AuthFormView(
            title: String(localized: "Buat akun"),
            subtitle: String(localized: "Daftar gratis dan mulai atur harimu."),
            submitTitle: String(localized: "Daftar"),
            footerText: String(localized: "Sudah punya akun?"),
            footerButtonTitle: String(localized: "Masuk"),
            isLoading: store.state.isLoading,
            isSubmitEnabled: store.state.canSubmit,
            errorMessage: store.state.errorMessage,
            onSubmit: { store.send(.submitTapped) },
            onFooterTap: { store.send(.signInTapped) },
            googleTitle: String(localized: "Daftar dengan Google"),
            isGoogleLoading: store.state.isGoogleLoading,
            onGoogleTap: { store.send(.googleTapped) }
        ) {
            InputFieldView(title: String(localized: "Email"),
                           placeholder: "nama@email.com",
                           text: store.binding(\.email, send: { .emailChanged($0) }),
                           systemImage: "envelope",
                           keyboardType: .emailAddress,
                           contentType: .emailAddress,
                           errorMessage: store.state.emailError)
            InputFieldView(title: String(localized: "Password"),
                           placeholder: String(localized: "Minimal 8 karakter"),
                           text: store.binding(\.password, send: { .passwordChanged($0) }),
                           systemImage: "lock",
                           isSecure: true,
                           contentType: .newPassword,
                           errorMessage: store.state.passwordError)
            InputFieldView(title: String(localized: "Konfirmasi password"),
                           placeholder: String(localized: "Ulangi password"),
                           text: store.binding(\.confirmPassword, send: { .confirmPasswordChanged($0) }),
                           systemImage: "lock.rotation",
                           isSecure: true,
                           contentType: .newPassword,
                           errorMessage: store.state.confirmError)
        }
    }
}
