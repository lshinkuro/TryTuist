//
//  PrimaryButton.swift
//  TTUI
//
//  Tombol utama dengan state loading & disabled.
//
import SwiftUI

public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let isEnabled: Bool
    private let tint: Color
    private let action: () -> Void

    public init(_ title: String,
                isLoading: Bool = false,
                isEnabled: Bool = true,
                tint: Color = .brand,
                action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(tint, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading || !isEnabled)
        .accessibilityLabel(isLoading ? "\(title), memuat" : title)
    }
}

/// Efek mengecil sedikit saat ditekan.
public struct PressableButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Tombol kecil berbentuk kapsul (isi penuh atau outline).
public struct CapsuleButtonStyle: ButtonStyle {
    public enum Kind {
        case filled
        case outlined
    }

    private let kind: Kind
    private let tint: Color

    public init(_ kind: Kind = .filled, tint: Color = .brand) {
        self.kind = kind
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(kind == .filled ? Color.white : tint)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background {
                if kind == .filled {
                    Capsule().fill(tint)
                } else {
                    Capsule().stroke(tint, lineWidth: 1.2)
                }
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
