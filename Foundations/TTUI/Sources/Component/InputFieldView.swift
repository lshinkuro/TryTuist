//
//  InputFieldView.swift
//  TTUI
//
import SwiftUI
import UIKit

public struct InputFieldView: View {
    private let title: String
    private let placeholder: String
    private let systemImage: String?
    private let isSecure: Bool
    private let keyboardType: UIKeyboardType
    private let contentType: UITextContentType?
    private let errorMessage: String?
    @Binding private var text: String
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    public init(title: String,
                placeholder: String,
                text: Binding<String>,
                systemImage: String? = nil,
                isSecure: Bool = false,
                keyboardType: UIKeyboardType = .default,
                contentType: UITextContentType? = nil,
                errorMessage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.systemImage = systemImage
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.m) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(isFocused ? Color.brand : Color.secondary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                }

                field

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(isRevealed ? String(localized: "Sembunyikan password") : String(localized: "Tampilkan password"))
                }
            }
            .padding(.horizontal, Spacing.l)
            .frame(height: 52)
            .background(Color.fieldBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var field: some View {
        Group {
            if isSecure && !isRevealed {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .focused($isFocused)
        .keyboardType(keyboardType)
        .textContentType(contentType)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .accessibilityLabel(title)
    }

    private var borderColor: Color {
        if errorMessage != nil { return .red }
        return isFocused ? .brand : .clear
    }
}
