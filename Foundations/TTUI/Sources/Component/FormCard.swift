//
//  FormCard.swift
//  TTUI
//
//  Pengganti `FormView` (UIKit): card putih dengan border tipis dan shadow.
//
import SwiftUI

public struct FormCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    public func body(content: Content) -> some View {
        content
            .background(Color.foodWhite100)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

public extension View {
    /// Membungkus view dalam card bergaya `FormView`.
    func formCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(FormCardModifier(cornerRadius: cornerRadius))
    }
}
