//
//  InputFieldView.swift
//  TTUI
//
//  Pengganti `InputField` (UIKit).
//
import SwiftUI

public struct InputFieldView: View {
    private let title: String
    private let placeholder: String
    private let isSecure: Bool
    private let errorMessage: String?
    @Binding private var text: String

    public init(title: String,
                placeholder: String,
                text: Binding<String>,
                isSecure: Bool = false,
                errorMessage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.black)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 14))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 15)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .foodBlack80.opacity(0.5), radius: 2, x: 0, y: 3)
            )
            .accessibilityLabel(title)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.702, green: 0.049, blue: 0.132))
                    .padding(.leading, 10)
            }
        }
    }
}
