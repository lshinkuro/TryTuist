//
//  FormCard.swift
//  TTUI
//
//  Card standar: background adaptif, sudut membulat, garis tepi halus.
//
import SwiftUI

public struct FormCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Color.cardLine))
    }
}

public extension View {
    /// Membungkus view dalam card standar aplikasi.
    func formCard(cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(FormCardModifier(cornerRadius: cornerRadius))
    }
}
