//
//  AuthFormView.swift
//  AuthenticationFeature
//
//  Layout bersama untuk Sign In & Sign Up.
//
import SwiftUI
import TTUI

struct AuthFormView<Fields: View>: View {
    let title: String
    let subtitle: String
    let submitTitle: String
    let footerText: String
    let footerButtonTitle: String
    let isLoading: Bool
    let isSubmitEnabled: Bool
    let errorMessage: String?
    let onSubmit: () -> Void
    let onFooterTap: () -> Void
    /// nil = tombol Google disembunyikan.
    let googleTitle: String?
    let isGoogleLoading: Bool
    let onGoogleTap: () -> Void
    let fields: Fields

    init(title: String,
         subtitle: String,
         submitTitle: String,
         footerText: String,
         footerButtonTitle: String,
         isLoading: Bool,
         isSubmitEnabled: Bool,
         errorMessage: String?,
         onSubmit: @escaping () -> Void,
         onFooterTap: @escaping () -> Void,
         googleTitle: String? = nil,
         isGoogleLoading: Bool = false,
         onGoogleTap: @escaping () -> Void = {},
         @ViewBuilder fields: () -> Fields) {
        self.title = title
        self.subtitle = subtitle
        self.submitTitle = submitTitle
        self.footerText = footerText
        self.footerButtonTitle = footerButtonTitle
        self.isLoading = isLoading
        self.isSubmitEnabled = isSubmitEnabled
        self.errorMessage = errorMessage
        self.onSubmit = onSubmit
        self.onFooterTap = onFooterTap
        self.googleTitle = googleTitle
        self.isGoogleLoading = isGoogleLoading
        self.onGoogleTap = onGoogleTap
        self.fields = fields()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                header

                VStack(spacing: Spacing.l) {
                    fields
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.m)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.control))
                        .transition(.opacity)
                }

                PrimaryButton(submitTitle, isLoading: isLoading, isEnabled: isSubmitEnabled && !isGoogleLoading,
                              action: onSubmit)

                if let googleTitle {
                    VStack(spacing: Spacing.l) {
                        OrDivider()
                        GoogleSignInButton(title: googleTitle, isLoading: isGoogleLoading, action: onGoogleTap)
                            .disabled(isLoading || isGoogleLoading)
                    }
                }

                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .animation(.easeOut(duration: 0.2), value: errorMessage)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            IconBadge(systemImage: "fork.knife", size: 56)
                .padding(.bottom, Spacing.m)
            Text(title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: Spacing.xs) {
            Text(footerText)
                .foregroundStyle(.secondary)
            Button(footerButtonTitle, action: onFooterTap)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
}

/// Garis pemisah "atau".
private struct OrDivider: View {
    var body: some View {
        HStack(spacing: Spacing.m) {
            line
            Text("atau")
                .font(.footnote)
                .foregroundStyle(.secondary)
            line
        }
        .accessibilityHidden(true)
    }

    private var line: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.25))
            .frame(height: 1)
    }
}

/// Tombol "Lanjutkan dengan Google" (gaya netral: latar terang, garis tepi).
/// Untuk rilis, ganti ikon dengan logo "G" resmi dari Google Branding Guidelines
/// (developers.google.com/identity/branding-guidelines) sebagai asset di Resources.
struct GoogleSignInButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "g.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.multicolor)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color(uiColor: .secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(isLoading ? "\(title), memuat" : title)
    }
}
