//
//  ProfileView.swift
//  ProfileFeature
//
import SwiftUI
import TTUI

struct QuickAction: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let value: String
    let systemImage: String
}

struct SettingItem: Identifiable {
    var id: String { title }
    let title: String
    let systemImage: String
}

struct ProfileView: View {
    @State private var quickActions: [QuickAction] = [
        .init(title: "Vouchers", value: "1", systemImage: "ticket.fill"),
        .init(title: "TOMORO Points", value: "78 pts", systemImage: "clock.fill"),
        .init(title: "QR Code", value: "", systemImage: "qrcode")
    ]

    private let settings: [SettingItem] = [
        .init(title: "My Addresses", systemImage: "location.fill"),
        .init(title: "Help Center", systemImage: "questionmark.circle.fill"),
        .init(title: "Language", systemImage: "globe"),
        .init(title: "Terms of Services", systemImage: "doc.text.fill"),
        .init(title: "Privacy Policy", systemImage: "lock.fill"),
        .init(title: "Settings", systemImage: "gearshape.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Hi, Ishinkuro")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 60)
                    .padding(.bottom, -8)
                    .accessibilityAddTraits(.isHeader)

                promoCard

                HStack(spacing: 0) {
                    ForEach(quickActions) { action in
                        QuickActionView(action: action)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)

                Image("promo_banner")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .clipped()
                    .accessibilityLabel("Promo banner")

                VStack(spacing: 8) {
                    ForEach(settings) { item in
                        SettingsRow(item: item)
                    }
                }

                VStack(spacing: 8) {
                    Text("version 1.2.0")
                    Text("app.com.contol")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.white)
    }

    private var promoCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("DAILY COFFEE HAPPINESS")
                    .font(.system(size: 16, weight: .bold))
                Text("Weekly | 1 Cup Only 15K")
            }
            .foregroundStyle(.white)

            Spacer()

            Button {
                // Tukar posisi Vouchers <-> TOMORO Points.
                withAnimation(.easeInOut(duration: 0.25)) {
                    quickActions.swapAt(0, 1)
                }
            } label: {
                Text("Activate")
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 40)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .frame(height: 100)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct QuickActionView: View {
    let action: QuickAction

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: action.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)
                .padding(.top, 12)
                .accessibilityHidden(true)
            Text(action.title)
                .font(.system(size: 14))
                .padding(.top, 12)
            Text(action.value)
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 6)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsRow: View {
    let item: SettingItem

    var body: some View {
        Button {} label: {
            HStack(spacing: 16) {
                Image(systemName: item.systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(item.title)
                    .font(.system(size: 16))
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
