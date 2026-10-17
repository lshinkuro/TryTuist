//
//  FormCard.swift
//  TTUI
//
//  Card standar: background adaptif, sudut membulat, shadow halus.
//
import SwiftUI

public struct FormCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

public extension View {
    /// Membungkus view dalam card standar aplikasi.
    func formCard(cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(FormCardModifier(cornerRadius: cornerRadius))
    }
}
