//
//  SignInView.swift
//  AuthenticationFeature · Presentation
//
//  View hanya membaca `store.state` dan mengirim action.
//
import SwiftUI
import TTUI

struct SignInView: View {
    @StateObject private var store: SignInStore

    init(store: SignInStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        AuthFormView(
            title: "Selamat datang 👋",
            subtitle: "Masuk untuk melanjutkan ke akunmu.",
            submitTitle: "Masuk",
            footerText: "Belum punya akun?",
            footerButtonTitle: "Daftar",
            isLoading: store.state.isLoading,
            isSubmitEnabled: store.state.canSubmit,
            errorMessage: store.state.errorMessage,
            onSubmit: { store.send(.submitTapped) },
            onFooterTap: { store.send(.signUpTapped) }
        ) {
            InputFieldView(title: "Email",
                           placeholder: "nama@email.com",
                           text: store.binding(\.email, send: { .emailChanged($0) }),
                           systemImage: "envelope",
                           keyboardType: .emailAddress,
                           contentType: .emailAddress)
            InputFieldView(title: "Password",
                           placeholder: "Masukkan password",
                           text: store.binding(\.password, send: { .passwordChanged($0) }),
                           systemImage: "lock",
                           isSecure: true,
                           contentType: .password)
        }
    }
}
