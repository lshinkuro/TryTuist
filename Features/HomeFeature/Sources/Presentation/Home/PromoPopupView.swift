//
//  PromoPopupView.swift
//  HomeFeature · Presentation
//
//  Popup promo makanan/minuman murah di Beranda. Dipresentasikan CatalogFlow di atas
//  seluruh layar (termasuk tab bar). View tidak punya logika: tutup / buka dikirim
//  ke HomeStore lewat closure.
//
import SwiftUI
import TTUI

struct PromoPopupView: View {
    let popup: PromoPopup
    let onClose: () -> Void
    let onOpen: () -> Void

    /// Hanya untuk animasi masuk.
    @State private var isVisible = false

    private var product: Product { popup.product }

    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.55 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityLabel("Tutup promo")
                .accessibilityAddTraits(.isButton)

            card
                .frame(maxWidth: 340)
                .padding(.horizontal, Spacing.xl)
                .scaleEffect(isVisible ? 1 : 0.88)
                .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) { isVisible = true }
        }
        .accessibilityAction(.escape, onClose)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                Color.clear
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay { RemoteImage(url: popup.imageURL) }
                    .overlay {
                        LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(popup.badge)
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, 6)
                            .background(Color.red, in: Capsule())
                            .padding(Spacing.l)
                    }
                    .clipped()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lihat \(product.name)")

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("PROMO HEMAT")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(Color.brand)
                Text(popup.title)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
                if !popup.subtitle.isEmpty {
                    Text(popup.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .firstTextBaseline) {
                    PriceLabel(price: product.price, originalPrice: product.originalPrice, font: .title2.bold())
                    Spacer(minLength: 0)
                    if let endsAt = popup.endsAt {
                        Text("s.d. \(endsAt.formatted(.dateTime.day().month(.abbreviated)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, Spacing.xs)

                PrimaryButton(String(localized: "Lihat Promo"), action: onOpen)
                    .padding(.top, Spacing.s)
            }
            .padding(Spacing.l)
        }
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .buttonStyle(PressableButtonStyle())
            .padding(Spacing.m)
            .accessibilityLabel("Tutup")
        }
        .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
    }
}
