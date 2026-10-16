//
//  SignUpView.swift
//  AuthenticationFeature
//
import SwiftUI
import NetworkManager
import TTUI
import Utility

struct SignUpView: View {
    @ObservedObject var viewModel: SignUpViewModel
    @State private var email: String
    @State private var password: String
    @State private var showSuccessAlert = false

    /// Aksi navigasi diteruskan ke view controller / coordinator.
    let onSignIn: () -> Void
    let onRegisterSuccess: () -> Void

    init(viewModel: SignUpViewModel,
         email: String,
         password: String,
         onSignIn: @escaping () -> Void,
         onRegisterSuccess: @escaping () -> Void) {
        self.viewModel = viewModel
        self._email = State(initialValue: email)
        self._password = State(initialValue: password)
        self.onSignIn = onSignIn
        self.onRegisterSuccess = onRegisterSuccess
    }

    var body: some View {
        AuthFormView(
            title: "Register Akun Aplikasi",
            submitTitle: "Sign Up",
            footerText: "sudah punya Akun ?",
            footerButtonTitle: "Sign In",
            background: Color(.systemBackground),
            isLoading: viewModel.loadingState == .loading,
            email: $email,
            password: $password,
            onSubmit: { viewModel.fetchRegister(param: RegisterParam(email: email, password: password)) },
            onFooterTap: onSignIn
        )
        .onChange(of: viewModel.loadingState) { _, state in
            if state == .finished { showSuccessAlert = true }
        }
        .alert("sukses", isPresented: $showSuccessAlert) {
            Button("OK", action: onRegisterSuccess)
        } message: {
            Text("Please Sign In to continue")
        }
    }
}
