//
//  SignInView.swift
//  AuthenticationFeature
//
import SwiftUI
import NetworkManager
import TTUI
import Utility

struct SignInView: View {
    @ObservedObject var viewModel: SignInViewModel
    @State private var email: String
    @State private var password: String
    @State private var showSuccessAlert = false

    /// Aksi navigasi diteruskan ke view controller / coordinator.
    let onSignUp: () -> Void
    let onLoginSuccess: () -> Void

    init(viewModel: SignInViewModel,
         email: String,
         password: String,
         onSignUp: @escaping () -> Void,
         onLoginSuccess: @escaping () -> Void) {
        self.viewModel = viewModel
        self._email = State(initialValue: email)
        self._password = State(initialValue: password)
        self.onSignUp = onSignUp
        self.onLoginSuccess = onLoginSuccess
    }

    var body: some View {
        AuthFormView(
            title: "Login Aplikasi",
            submitTitle: "Sign In",
            footerText: "belum punya Akun ?",
            footerButtonTitle: "Sign Up",
            background: .appDarkBackground,
            isLoading: viewModel.loadingState == .loading,
            email: $email,
            password: $password,
            onSubmit: { viewModel.fetchLogin(param: LoginParam(email: email, password: password)) },
            onFooterTap: onSignUp
        )
        .onChange(of: viewModel.loadingState) { _, state in
            if state == .finished { showSuccessAlert = true }
        }
        .alert("sukses", isPresented: $showSuccessAlert) {
            Button("OK", action: onLoginSuccess)
        } message: {
            Text("Please Sign In to continue")
        }
    }
}
