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
                ScreenHeader(title: "Profil")
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
        .confirmationDialog("Keluar dari akun?",
                            isPresented: store.binding(\.isConfirmingLogout, send: { .logoutDialogChanged($0) }),
                            titleVisibility: .visible) {
            Button("Keluar", role: .destructive) { store.send(.logoutConfirmed) }
            Button("Batal", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var profileCard: some View {
        HStack(spacing: Spacing.l) {
            AvatarView(name: state.userName, size: 64)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(state.userName)
                    .font(.title3.bold())
                Label(state.memberTier, systemImage: "crown.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
            Spacer()
            Button("Ubah") {}
                .buttonStyle(CapsuleButtonStyle(.outlined))
        }
        .padding(Spacing.l)
        .formCard()
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
                Label(state.isPromoActive ? "Aktif" : "Aktifkan",
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
            ForEach(Array(state.settings.enumerated()), id: \.element.id) { index, item in
                Button { store.send(.settingTapped(item)) } label: {
                    HStack(spacing: 14) {
                        IconBadge(systemImage: item.systemImage, tint: item.tint, size: 34)
                        Text(item.title)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, Spacing.l)
                    .frame(height: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < state.settings.count - 1 {
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

/// Placeholder untuk screen yang di-push dari menu pengaturan (statis, tanpa logika → tanpa Store).
struct SettingDetailView: View {
    let item: SettingItem

    var body: some View {
        ContentUnavailableView(item.title,
                               systemImage: item.systemImage,
                               description: Text("Halaman ini belum tersedia."))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
    }
}
