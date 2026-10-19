//
//  ProfileView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct ProfileView: View {
    @StateObject private var store: ProfileStore

    init(store: ProfileStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: ProfileState { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                ScreenHeader(title: String(localized: "Profil"))
                profileCard
                quickActionsCard
                promoCard
                settingsCard
                logoutButton

                Text("Versi \(state.appVersion)")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, Spacing.s)
            }
            .padding(Spacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .refreshable { store.send(.onAppear) }
        .onAppear { store.send(.onAppear) }
        .toast(state.toast)
        .confirmationDialog("Keluar dari akun?",
                            isPresented: store.binding(\.isConfirmingLogout, send: { .logoutDialogChanged($0) }),
                            titleVisibility: .visible) {
            Button("Keluar", role: .destructive) { store.send(.logoutConfirmed) }
            Button("Batal", role: .cancel) {}
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var profileCard: some View {
        if let message = state.profile.errorMessage {
            HStack(spacing: Spacing.m) {
                IconBadge(systemImage: "wifi.exclamationmark", tint: .red, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profil gagal dimuat").font(.headline)
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Coba lagi") { store.send(.retryTapped) }
                    .buttonStyle(CapsuleButtonStyle(.outlined))
            }
            .padding(Spacing.l)
            .formCard()
        } else {
            let profile = state.profile.value
            HStack(spacing: Spacing.l) {
                AvatarView(name: state.displayName, size: 64)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(state.displayName)
                        .font(.title3.bold())
                        .lineLimit(1)
                    Label(profile?.tier.title ?? String(localized: "Member"), systemImage: "crown.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    if let email = profile?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Button("Ubah") { store.send(.editTapped) }
                    .buttonStyle(CapsuleButtonStyle(.outlined))
                    .disabled(profile == nil)
            }
            .padding(Spacing.l)
            .formCard()
            .redacted(reason: profile == nil ? .placeholder : [])
        }
    }

    private var quickActionsCard: some View {
        HStack(spacing: 0) {
            ForEach(Array(state.quickActions.enumerated()), id: \.element.id) { index, action in
                if index > 0 {
                    Divider().frame(height: 48)
                }
                VStack(spacing: Spacing.s) {
                    IconBadge(systemImage: action.systemImage, size: 40)
                    Text(action.value)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(action.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, Spacing.l)
        .formCard()
    }

    private var promoCard: some View {
        HStack(spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("LANGGANAN KOPI HARIAN")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .opacity(0.8)
                Text("1 cup cuma 15rb / hari")
                    .font(.title3.bold())
            }
            Spacer(minLength: 0)
            Button {
                withAnimation(.snappy) { store.send(.promoToggled) }
            } label: {
                Label(state.isPromoActive ? String(localized: "Aktif") : String(localized: "Aktifkan"),
                      systemImage: state.isPromoActive ? "checkmark.circle.fill" : "bolt.fill")
            }
            .buttonStyle(CapsuleButtonStyle(.filled, tint: state.isPromoActive ? .green : Color.white.opacity(0.25)))
        }
        .foregroundStyle(.white)
        .padding(Spacing.xl)
        .background(alignment: .trailing) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 96))
                .foregroundStyle(Color.white.opacity(0.1))
                .offset(x: 20, y: 16)
                .accessibilityHidden(true)
        }
        .background(
            LinearGradient(colors: [Color(red: 0.16, green: 0.09, blue: 0.06), Color.brand],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(state.menu.enumerated()), id: \.element.id) { index, item in
                Button { store.send(.menuTapped(item)) } label: {
                    ProfileMenuRow(title: item.title,
                                   subtitle: item == .security && state.profile.value?.emailVerified == false
                                       ? String(localized: "Email belum terverifikasi") : nil,
                                   systemImage: item.systemImage, tint: item.tint)
                }
                .buttonStyle(.plain)

                if index < state.menu.count - 1 {
                    Divider().padding(.leading, 64)
                }
            }
        }
        .formCard()
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            store.send(.logoutTapped)
        } label: {
            Label("Keluar", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .foregroundStyle(.red)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }
}
