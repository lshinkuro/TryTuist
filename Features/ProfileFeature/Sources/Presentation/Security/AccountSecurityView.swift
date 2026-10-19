//
//  AccountSecurityView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct AccountSecurityView: View {
    @StateObject private var store: AccountSecurityStore

    init(store: AccountSecurityStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: AccountSecurityState { store.state }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                emailSection
                passwordSection
            }
            .padding(Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .toast(state.toast)
    }

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Label(state.emailVerified ? String(localized: "Email terverifikasi") : String(localized: "Email belum terverifikasi"),
                  systemImage: state.emailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(state.emailVerified ? .green : .orange)
            Text(state.email).font(.subheadline).foregroundStyle(.secondary)
            if !state.emailVerified {
                Text("Masukkan kode 6 digit yang kami kirim ke email kamu. Verifikasi diperlukan sebelum memesan.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                InputFieldView(title: String(localized: "Kode verifikasi"),
                               placeholder: "123456",
                               text: store.binding(\.code, send: { .codeChanged($0) }),
                               systemImage: "number",
                               keyboardType: .numberPad,
                               contentType: .oneTimeCode,
                               errorMessage: state.fieldErrors["code"])
                PrimaryButton(String(localized: "Verifikasi"), isLoading: state.isVerifying, isEnabled: state.canVerify) {
                    store.send(.verifyTapped)
                }
                Button(state.isSending ? String(localized: "Mengirim…") : String(localized: "Kirim ulang kode")) {
                    store.send(.resendTapped)
                }
                .font(.footnote.weight(.semibold))
                .disabled(state.isSending)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.l)
        .formCard()
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Text(state.hasPassword ? "Ganti password" : "Buat password").font(.headline)
            if state.hasPassword {
                InputFieldView(title: String(localized: "Password saat ini"),
                               placeholder: String(localized: "Masukkan password"),
                               text: store.binding(\.currentPassword, send: { .currentPasswordChanged($0) }),
                               systemImage: "lock",
                               isSecure: true,
                               contentType: .password,
                               errorMessage: state.fieldErrors["current_password"])
            } else {
                Text("Akun ini masuk dengan Google. Buat password supaya bisa masuk dengan email juga.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            InputFieldView(title: String(localized: "Password baru"),
                           placeholder: String(localized: "Minimal 8 karakter"),
                           text: store.binding(\.newPassword, send: { .newPasswordChanged($0) }),
                           systemImage: "lock.rotation",
                           isSecure: true,
                           contentType: .newPassword,
                           errorMessage: state.fieldErrors["new_password"])
            PrimaryButton(String(localized: "Simpan password"), isLoading: state.isSaving, isEnabled: state.canSavePassword) {
                store.send(.savePasswordTapped)
            }
            Text("Setelah diganti, perangkat lain otomatis dikeluarkan dari akunmu.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.l)
        .formCard()
    }
}
