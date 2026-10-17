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
            title: "Buat akun",
            subtitle: "Daftar gratis dan mulai atur harimu.",
            submitTitle: "Daftar",
            footerText: "Sudah punya akun?",
            footerButtonTitle: "Masuk",
            isLoading: store.state.isLoading,
            isSubmitEnabled: store.state.canSubmit,
            errorMessage: store.state.errorMessage,
            onSubmit: { store.send(.submitTapped) },
            onFooterTap: { store.send(.signInTapped) }
        ) {
            InputFieldView(title: "Email",
                           placeholder: "nama@email.com",
                           text: store.binding(\.email, send: { .emailChanged($0) }),
                           systemImage: "envelope",
                           keyboardType: .emailAddress,
                           contentType: .emailAddress,
                           errorMessage: store.state.emailError)
            InputFieldView(title: "Password",
                           placeholder: "Minimal 8 karakter",
                           text: store.binding(\.password, send: { .passwordChanged($0) }),
                           systemImage: "lock",
                           isSecure: true,
                           contentType: .newPassword,
                           errorMessage: store.state.passwordError)
            InputFieldView(title: "Konfirmasi password",
                           placeholder: "Ulangi password",
                           text: store.binding(\.confirmPassword, send: { .confirmPasswordChanged($0) }),
                           systemImage: "lock.rotation",
                           isSecure: true,
                           contentType: .newPassword,
                           errorMessage: store.state.confirmError)
        }
    }
}
