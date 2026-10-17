//
//  ProfileModule.swift
//  ProfileFeature
//
//  Composition root + routing tab Profil:
//  Profil → Edit Profil · Alamat (→ form) · Metode Pembayaran (→ tambah e-wallet) · Pusat Bantuan · Kebijakan Privasi.
//  Setiap screen punya Store; module hanya merakit dependency dan menerjemahkan Route jadi navigasi.
//
import SwiftUI
import UIKit
import Navigation
import Utility

@MainActor
public final class ProfileModule: TabFeature {
    public let tabItem = TabItem(title: "Profil", systemImage: "person", selectedSystemImage: "person.fill")
    private let onLogout: () -> Void
    private let repository: DefaultProfileRepository
    private weak var router: Router?

    public init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
        self.repository = DefaultProfileRepository(remote: Self.makeRemoteDataSource())
    }

    private static func makeRemoteDataSource() -> ProfileRemoteDataSource {
        if AppConfig.useMockData { return ProfileMockDataSource() }
        return ProfileAPIDataSource()
    }

    public func start(router: Router) {
        self.router = router
        let store = ProfileStore(getProfile: GetProfileUseCase(repository: repository))
        store.onRoute = { [weak self, weak store] route in
            guard let self else { return }
            switch route {
            case .editProfile(let profile):
                self.showEditProfile(profile) { store?.send(.profileUpdated($0)) }
            case .addresses:
                self.showAddresses()
            case .paymentMethods:
                self.showPaymentMethods()
            case .helpCenter:
                self.showHelpCenter()
            case .legal(let kind):
                self.showLegal(kind)
            case .comingSoon(let item):
                self.router?.push(ComingSoonView(item: item), title: item.title)
            case .loggedOut:
                self.onLogout()
            }
        }
        router.setRoot(ProfileView(store: store), hidesNavigationBar: true)
    }

    /// Screen di tab Profil yang bisa dibuka dari luar feature (mis. dari Keranjang).
    public enum Destination {
        case addresses
        case paymentMethods
    }

    /// Kembali ke root Profil lalu buka `destination`.
    public func open(_ destination: Destination) {
        router?.popToRoot(animated: false)
        switch destination {
        case .addresses: showAddresses()
        case .paymentMethods: showPaymentMethods()
        }
    }

    // MARK: - Edit profil

    private func showEditProfile(_ profile: UserProfile, onSaved: @escaping (UserProfile) -> Void) {
        let store = EditProfileStore(profile: profile, updateProfile: UpdateProfileUseCase(repository: repository))
        store.onRoute = { [weak self] route in
            switch route {
            case .saved(let updated):
                self?.router?.pop()
                if updated != profile { onSaved(updated) }
            }
        }
        router?.push(EditProfileView(store: store), title: "Edit Profil")
    }

    // MARK: - Alamat

    private func showAddresses() {
        let store = AddressListStore(repository: repository)
        store.onRoute = { [weak self, weak store] route in
            switch route {
            case .form(let address):
                let isFirst = store?.state.addresses.value?.isEmpty ?? true
                self?.showAddressForm(address, isFirstAddress: isFirst) { isNew in
                    store?.send(.addressSaved(isNew: isNew))
                }
            }
        }
        router?.push(AddressListView(store: store), title: "Alamat Pengiriman")
    }

    private func showAddressForm(_ address: Address?, isFirstAddress: Bool, onSaved: @escaping (Bool) -> Void) {
        let store = AddressFormStore(address: address, isFirstAddress: isFirstAddress,
                                     saveAddress: SaveAddressUseCase(repository: repository))
        store.onRoute = { [weak self] route in
            switch route {
            case .saved(_, let isNew):
                self?.router?.pop()
                onSaved(isNew)
            }
        }
        router?.push(AddressFormView(store: store), title: store.state.title)
    }

    // MARK: - Metode pembayaran

    private func showPaymentMethods() {
        let store = PaymentMethodsStore(repository: repository)
        store.onRoute = { [weak self, weak store] route in
            switch route {
            case .addEWallet(let providers):
                self?.showAddEWallet(providers) { store?.send(.eWalletAdded($0)) }
            }
        }
        router?.push(PaymentMethodsView(store: store), title: "Metode Pembayaran")
    }

    private func showAddEWallet(_ providers: [EWalletProvider], onAdded: @escaping (PaymentOverview) -> Void) {
        let store = AddEWalletStore(providers: providers, addEWallet: AddEWalletUseCase(repository: repository))
        store.onRoute = { [weak self] route in
            switch route {
            case .added(let overview):
                self?.router?.dismiss()
                onAdded(overview)
            case .cancelled:
                self?.router?.dismiss()
            }
        }
        router?.present(AddEWalletView(store: store), title: "Tambah E-Wallet")
    }

    // MARK: - Bantuan & legal

    private func showHelpCenter() {
        let store = HelpCenterStore(repository: repository)
        store.onRoute = { route in
            switch route {
            case .open(let url):
                // Hanya https / mailto / tel yang lolos dari Mapper.
                UIApplication.shared.open(url)
            }
        }
        router?.push(HelpCenterView(store: store), title: "Pusat Bantuan")
    }

    private func showLegal(_ kind: LegalDocumentKind) {
        let store = LegalDocumentStore(kind: kind, repository: repository)
        router?.push(LegalDocumentView(store: store), title: kind.title)
    }
}
