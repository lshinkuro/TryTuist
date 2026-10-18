//
//  ProfileStore.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI
import Utility

struct QuickAction: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let value: String
    let systemImage: String
}

/// Menu pengaturan Profil. Urutan di sini = urutan tampil.
enum ProfileMenuItem: String, CaseIterable, Identifiable {
    case editProfile
    case addresses
    case paymentMethods
    case favorites
    case helpCenter
    case language
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editProfile: return String(localized: "Edit Profil")
        case .addresses: return String(localized: "Alamat Pengiriman")
        case .paymentMethods: return String(localized: "Metode Pembayaran")
        case .favorites: return String(localized: "Menu Favorit")
        case .helpCenter: return String(localized: "Pusat Bantuan")
        case .language: return String(localized: "Bahasa")
        case .privacyPolicy: return String(localized: "Kebijakan Privasi")
        }
    }

    var systemImage: String {
        switch self {
        case .editProfile: return "person.crop.circle"
        case .addresses: return "location.fill"
        case .paymentMethods: return "creditcard.fill"
        case .favorites: return "heart.fill"
        case .helpCenter: return "questionmark.circle.fill"
        case .language: return "globe"
        case .privacyPolicy: return "lock.fill"
        }
    }

    var tint: Color {
        switch self {
        case .editProfile: return .orange
        case .addresses: return .blue
        case .paymentMethods: return .green
        case .favorites: return .pink
        case .helpCenter: return .teal
        case .language: return .indigo
        case .privacyPolicy: return .gray
        }
    }
}

struct ProfileState: Equatable {
    var profile: Loadable<UserProfile> = .idle
    var isPromoActive = false
    var isConfirmingLogout = false
    var toast: ToastMessage?
    let menu = ProfileMenuItem.allCases

    var appVersion: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let env = AppEnvironment.current
        // Selain Prod, tampilkan environment supaya QA tahu sedang memakai build apa.
        return env.isProduction ? version : "\(version) · \(env.displayName)"
    }()

    var displayName: String { profile.value?.name ?? String(localized: "Memuat…") }

    var quickActions: [QuickAction] {
        let profile = profile.value
        return [
            QuickAction(title: String(localized: "Voucher"), value: profile.map { "\($0.voucherCount)" } ?? "–", systemImage: "ticket.fill"),
            QuickAction(title: String(localized: "Poin"), value: profile.map { $0.points.formatted(.number.locale(Locale(identifier: "id_ID"))) } ?? "–",
                        systemImage: "star.fill"),
            QuickAction(title: String(localized: "Saldo"), value: profile.map { $0.balance.rupiahFormatted } ?? "–", systemImage: "wallet.pass.fill")
        ]
    }
}

enum ProfileAction {
    case onAppear
    case retryTapped
    case profileResponse(Result<UserProfile, ProfileError>)
    case profileUpdated(UserProfile)
    case editTapped
    case menuTapped(ProfileMenuItem)
    case promoToggled
    case logoutTapped
    case logoutDialogChanged(Bool)
    case logoutConfirmed
    case toastRequested(ToastMessage)
    case toastDismissed(UUID)
}

enum ProfileRoute {
    case editProfile(UserProfile)
    case addresses
    case paymentMethods
    case helpCenter
    case legal(LegalDocumentKind)
    case favorites
    /// Bahasa app diatur iOS (Settings → TryTuist → Bahasa); app dimulai ulang otomatis oleh iOS.
    case languageSettings
    case loggedOut
}

final class ProfileStore: Store<ProfileState, ProfileAction> {
    private let getProfile: GetProfileUseCase
    private let clearSession: () -> Void
    var onRoute: ((ProfileRoute) -> Void)?

    init(getProfile: GetProfileUseCase, clearSession: @escaping () -> Void = { _ = TokenStorage.delete() }) {
        self.getProfile = getProfile
        self.clearSession = clearSession
        super.init(initialState: ProfileState())
    }

    override func reduce(state: inout ProfileState, action: ProfileAction) -> Effect<ProfileAction>? {
        switch action {
        case .onAppear:
            // Pertama kali tampil loading; setelahnya refresh diam-diam (mis. poin bertambah setelah pesan).
            if state.profile.isIdle { state.profile = .loading }
            return fetch()

        case .retryTapped:
            state.profile = .loading
            return fetch()

        case .profileResponse(.success(let profile)):
            state.profile = .loaded(profile)
            return nil

        case .profileResponse(.failure(let error)):
            // Refresh yang gagal tidak menghapus data yang sudah tampil.
            if state.profile.value == nil { state.profile = .failed(error.message) }
            return nil

        case .profileUpdated(let profile):
            state.profile = .loaded(profile)
            return .run { [weak self] in
                self?.send(.toastRequested(ToastMessage(String(localized: "Profil disimpan"))))
            }

        case .editTapped:
            guard let profile = state.profile.value else { return nil }
            return route(.editProfile(profile))

        case .menuTapped(let item):
            switch item {
            case .editProfile:
                guard let profile = state.profile.value else {
                    let toast = ToastMessage.error(String(localized: "Profil belum termuat. Coba lagi sebentar."))
                    state.toast = toast
                    return dismissToast(id: toast.id) { .toastDismissed($0) }
                }
                return route(.editProfile(profile))
            case .addresses: return route(.addresses)
            case .paymentMethods: return route(.paymentMethods)
            case .helpCenter: return route(.helpCenter)
            case .privacyPolicy: return route(.legal(.privacyPolicy))
            case .favorites: return route(.favorites)
            case .language: return route(.languageSettings)
            }

        case .promoToggled:
            state.isPromoActive.toggle()
            return nil

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

        case .toastRequested(let toast):
            state.toast = toast
            return dismissToast(id: toast.id) { .toastDismissed($0) }

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func route(_ route: ProfileRoute) -> Effect<ProfileAction> {
        .run { [weak self] in self?.onRoute?(route) }
    }

    private func fetch() -> Effect<ProfileAction> {
        let getProfile = self.getProfile
        return .task {
            do {
                return .profileResponse(.success(try await getProfile.execute()))
            } catch {
                return .profileResponse(.failure(error as? ProfileError ?? .unknown))
            }
        }
    }
}
