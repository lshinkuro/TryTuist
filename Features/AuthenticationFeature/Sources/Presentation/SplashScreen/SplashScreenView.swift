//
//  SplashScreenView.swift
//  AuthenticationFeature · Presentation
//
import SwiftUI
import TTUI

struct SplashScreenView: View {
    @StateObject private var store: SplashStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: SplashStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var appeared: Bool { store.state.hasAppeared }

    /// Ikon belanjaan yang melayang di sekitar logo: (simbol, posisi relatif ke tengah, ukuran).
    private let groceries: [(symbol: String, offset: CGSize, size: CGFloat)] = [
        ("carrot.fill", CGSize(width: -118, height: -96), 30),
        ("leaf.fill", CGSize(width: 116, height: -110), 26),
        ("cart.fill", CGSize(width: -132, height: 34), 28),
        ("drop.fill", CGSize(width: 128, height: 22), 24),
        ("fish.fill", CGSize(width: -84, height: 132), 26),
        ("tag.fill", CGSize(width: 92, height: 128), 24)
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.brand, Color(red: 0.56, green: 0.18, blue: 0.04)],
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 420, height: 420)
                .offset(x: 140, y: -300)
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    ForEach(Array(groceries.enumerated()), id: \.offset) { index, item in
                        Image(systemName: item.symbol)
                            .font(.system(size: item.size, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: item.size * 1.9, height: item.size * 1.9)
                            .background(Color.white.opacity(0.14), in: Circle())
                            .offset(appeared || reduceMotion ? item.offset : .zero)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.15 + Double(index) * 0.06),
                                       value: appeared)
                    }

                    Image(systemName: "basket.fill")
                        .font(.system(size: 58, weight: .semibold))
                        .foregroundStyle(Color.brand)
                        .frame(width: 124, height: 124)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)
                }
                .frame(height: 320)
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("KOPDES")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .tracking(4)
                    Text("Koperasi Desa")
                        .font(.headline)
                        .opacity(0.85)
                    Text(store.state.title)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                        .padding(.top, 8)
                        .padding(.horizontal, 40)
                }
                .foregroundStyle(.white)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 16)
                .animation(.easeOut(duration: 0.5).delay(0.35), value: appeared)
                .accessibilityElement(children: .combine)

                Spacer()

                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.white)
                    Text("by TryTuist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
        }
        .task { @MainActor in store.send(.onAppear) }
    }
}

#Preview {
    SplashScreenView(store: SplashStore(title: "Belanja kebutuhan harian, harga koperasi"))
}
