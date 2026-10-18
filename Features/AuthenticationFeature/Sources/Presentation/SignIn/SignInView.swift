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
            title: String(localized: "Selamat datang 👋"),
            subtitle: String(localized: "Masuk untuk melanjutkan ke akunmu."),
            submitTitle: String(localized: "Masuk"),
            footerText: String(localized: "Belum punya akun?"),
            footerButtonTitle: String(localized: "Daftar"),
            isLoading: store.state.isLoading,
            isSubmitEnabled: store.state.canSubmit,
            errorMessage: store.state.errorMessage,
            onSubmit: { store.send(.submitTapped) },
            onFooterTap: { store.send(.signUpTapped) },
            googleTitle: String(localized: "Masuk dengan Google"),
            isGoogleLoading: store.state.isGoogleLoading,
            onGoogleTap: { store.send(.googleTapped) }
        ) {
            InputFieldView(title: String(localized: "Email"),
                           placeholder: "nama@email.com",
                           text: store.binding(\.email, send: { .emailChanged($0) }),
                           systemImage: "envelope",
                           keyboardType: .emailAddress,
                           contentType: .emailAddress)
            InputFieldView(title: String(localized: "Password"),
                           placeholder: String(localized: "Masukkan password"),
                           text: store.binding(\.password, send: { .passwordChanged($0) }),
                           systemImage: "lock",
                           isSecure: true,
                           contentType: .password)
        }
    }
}
