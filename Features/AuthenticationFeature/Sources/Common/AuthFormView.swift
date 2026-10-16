//
//  AuthFormView.swift
//  AuthenticationFeature
//
//  Form bersama untuk Sign In & Sign Up.
//
import SwiftUI
import TTUI
import Utility

struct AuthFormView: View {
    let title: String
    let submitTitle: String
    let footerText: String
    let footerButtonTitle: String
    let background: Color
    let isLoading: Bool
    @Binding var email: String
    @Binding var password: String
    let onSubmit: () -> Void
    let onFooterTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                form
                    .padding(.horizontal, 20)
                    // Form selalu di tengah layar, tapi tetap bisa di-scroll saat keyboard muncul.
                    .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(background.ignoresSafeArea())
    }

    private var form: some View {
        VStack(spacing: 20) {
            Text(title)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .accessibilityAddTraits(.isHeader)

            InputFieldView(title: "UserName", placeholder: "masukan nama", text: $email)
            InputFieldView(title: "Password", placeholder: "password", text: $password, isSecure: true)

            PrimaryButton(submitTitle, isLoading: isLoading, action: onSubmit)
                .padding(.top, 30)

            HStack(spacing: 2) {
                Text(footerText)
                    .frame(maxWidth: .infinity)
                Button(footerButtonTitle, action: onFooterTap)
                    .foregroundStyle(Color.foodBrightBlue)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 20)
        }
        .foregroundStyle(.black)
        .padding(20)
        .formCard()
    }
}
