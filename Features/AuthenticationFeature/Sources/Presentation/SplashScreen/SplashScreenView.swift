//
//  SplashScreenView.swift
//  AuthenticationFeature · Presentation
//
import SwiftUI
import TTUI

struct SplashScreenView: View {
    @StateObject private var store: SplashStore

    init(store: SplashStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var appeared: Bool { store.state.hasAppeared }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.brand, Color.brand.opacity(0.8)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 112, height: 112)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .accessibilityHidden(true)

                Text(store.state.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)

            VStack {
                Spacer()
                ProgressView()
                    .tint(.white)
                    .padding(.bottom, 48)
            }
        }
        .task { @MainActor in store.send(.onAppear) }
    }
}
