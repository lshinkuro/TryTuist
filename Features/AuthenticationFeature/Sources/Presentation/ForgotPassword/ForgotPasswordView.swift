//
//  ForgotPasswordView.swift
//  AuthenticationFeature · Presentation
//
import SwiftUI
import TTUI

struct ForgotPasswordView: View {
    @StateObject private var store: ForgotPasswordStore

    init(store: ForgotPasswordStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: ForgotPasswordState { store.state }

    var body: some View {
        AuthFormView(
            title: String(localized: "Lupa password?"),
            subtitle: state.step == .email
                ? String(localized: "Masukkan email akunmu. Kami kirim kode untuk membuat password baru.")
                : String(localized: "Jika \(state.email) terdaftar, kode 6 digit sudah dikirim ke email tersebut."),
            submitTitle: state.step == .email ? String(localized: "Kirim kode") : String(localized: "Simpan & masuk"),
            footerText: String(localized: "Ingat password?"),
            footerButtonTitle: String(localized: "Masuk"),
            isLoading: state.isLoading,
            isSubmitEnabled: state.canSubmit,
            errorMessage: state.errorMessage,
            onSubmit: { store.send(.submitTapped) },
            onFooterTap: { store.send(.backTapped) }
        ) {
            if state.step == .email {
                InputFieldView(title: String(localized: "Email"),
                               placeholder: "nama@email.com",
                               text: store.binding(\.email, send: { .emailChanged($0) }),
                               systemImage: "envelope",
                               keyboardType: .emailAddress,
                               contentType: .emailAddress)
            } else {
                InputFieldView(title: String(localized: "Kode"),
                               placeholder: "123456",
                               text: store.binding(\.code, send: { .codeChanged($0) }),
                               systemImage: "number",
                               keyboardType: .numberPad,
                               contentType: .oneTimeCode)
                InputFieldView(title: String(localized: "Password baru"),
                               placeholder: String(localized: "Minimal 8 karakter"),
                               text: store.binding(\.newPassword, send: { .newPasswordChanged($0) }),
                               systemImage: "lock",
                               isSecure: true,
                               contentType: .newPassword)
                Button(String(localized: "Ganti email / kirim ulang kode")) { store.send(.changeEmailTapped) }
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
