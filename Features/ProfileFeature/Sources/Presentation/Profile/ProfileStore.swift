//
//  ProfileStore.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import Utility

struct QuickAction: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let value: String
    let systemImage: String
}

struct SettingItem: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let systemImage: String
    let tint: Color
}

struct ProfileState: Equatable {
    var userName = "Ishinkuro"
    var memberTier = "Member Gold"
    var isPromoActive = false
    var isConfirmingLogout = false

    let quickActions: [QuickAction] = [
        .init(title: "Voucher", value: "3", systemImage: "ticket.fill"),
        .init(title: "Poin", value: "1.250", systemImage: "star.fill"),
        .init(title: "Saldo", value: "Rp 50rb", systemImage: "wallet.pass.fill")
    ]

    let settings: [SettingItem] = [
        .init(title: "Alamat Pengiriman", systemImage: "location.fill", tint: .blue),
        .init(title: "Metode Pembayaran", systemImage: "creditcard.fill", tint: .green),
        .init(title: "Menu Favorit", systemImage: "heart.fill", tint: .pink),
        .init(title: "Pusat Bantuan", systemImage: "questionmark.circle.fill", tint: .teal),
        .init(title: "Bahasa", systemImage: "globe", tint: .indigo),
        .init(title: "Kebijakan Privasi", systemImage: "lock.fill", tint: .gray)
    ]

    var appVersion: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let env = AppEnvironment.current
        // Selain Prod, tampilkan environment supaya QA tahu sedang memakai build apa.
        return env.isProduction ? version : "\(version) · \(env.displayName)"
    }()
}

enum ProfileAction {
    case promoToggled
    case settingTapped(SettingItem)
    case logoutTapped
    case logoutDialogChanged(Bool)
    case logoutConfirmed
}

enum ProfileRoute {
    case setting(SettingItem)
    case loggedOut
}

final class ProfileStore: Store<ProfileState, ProfileAction> {
    private let clearSession: () -> Void
    var onRoute: ((ProfileRoute) -> Void)?

    init(clearSession: @escaping () -> Void = { _ = TokenStorage.delete() }) {
        self.clearSession = clearSession
        super.init(initialState: ProfileState())
    }

    override func reduce(state: inout ProfileState, action: ProfileAction) -> Effect<ProfileAction>? {
        switch action {
        case .promoToggled:
            state.isPromoActive.toggle()
            return nil

        case .settingTapped(let item):
            return .run { [weak self] in self?.onRoute?(.setting(item)) }

        case .logoutTapped:
            state.isConfirmingLogout = true
            return nil

        case .logoutDialogChanged(let isPresented):
            state.isConfirmingLogout = isPresented
            return nil

        case .logoutConfirmed:
            state.isConfirmingLogout = false
            let clearSession = self.clearSession
            return .run { [weak self] in
                clearSession()
                self?.onRoute?(.loggedOut)
            }
        }
    }
}
