//
//  MenuAdsView.swift
//  HomeFeature
//
import SwiftUI
import TTUI

struct MenuAdsView: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .formCard()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .accessibilityLabel("Promo")
    }
}
