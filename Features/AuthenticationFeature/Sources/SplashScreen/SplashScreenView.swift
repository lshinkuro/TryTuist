//
//  SplashScreenView.swift
//  AuthenticationFeature
//
import SwiftUI
import TTUI

struct SplashScreenView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.appDarkBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                // Animasi native pengganti Lottie "Emoji-Mata Kedip".
                Image(systemName: "face.smiling.inverse")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, options: .repeating)
                    .frame(height: 300)
                    .accessibilityHidden(true)

                Text(title)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
        }
    }
}
