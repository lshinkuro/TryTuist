//
//  PrimaryButton.swift
//  TTUI
//
//  Tombol utama dengan state loading (pengganti addLoading/afterDissmissed).
//
import SwiftUI

public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                } else {
                    Text(title)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isLoading ? Color(.systemGray5) : Color.foodBrightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
    }
}
