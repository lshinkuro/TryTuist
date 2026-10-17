//
//  Toast.swift
//  TTUI
//
//  Pesan singkat di atas layar. Disimpan di State sebagai `ToastMessage?`;
//  Store yang mengatur kapan muncul & hilang.
//
import SwiftUI

public struct ToastMessage: Identifiable, Equatable {
    public let id: UUID
    public let message: String
    public let systemImage: String
    public let isError: Bool

    public init(_ message: String, systemImage: String = "checkmark.circle.fill", isError: Bool = false) {
        self.id = UUID()
        self.message = message
        self.systemImage = systemImage
        self.isError = isError
    }

    public static func error(_ message: String) -> ToastMessage {
        ToastMessage(message, systemImage: "exclamationmark.circle.fill", isError: true)
    }
}

public struct ToastView: View {
    private let toast: ToastMessage

    public init(_ toast: ToastMessage) {
        self.toast = toast
    }

    public var body: some View {
        Label(toast.message, systemImage: toast.systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)
            .background(toast.isError ? Color.red : Color(white: 0.12), in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

public extension View {
    /// Tampilkan toast di atas konten bila `toast` tidak nil.
    func toast(_ toast: ToastMessage?) -> some View {
        overlay(alignment: .top) {
            if let toast {
                ToastView(toast)
                    .padding(.top, Spacing.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(toast.id)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast)
    }
}
