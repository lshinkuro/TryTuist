//
//  AddressListStore.swift
//  ProfileFeature · Presentation
//
//  Daftar alamat: tambah, ubah, jadikan utama, hapus (/v1/me/addresses).
//
import Foundation
import TTUI
import Utility

struct AddressListState: Equatable {
    var addresses: Loadable<[Address]> = .idle
    /// Alamat yang sedang diproses (jadikan utama / hapus) → tampilkan spinner di barisnya.
    var busyID: String?
    var pendingDeletion: Address?
    var toast: ToastMessage?

    var isConfirmingDeletion: Bool { pendingDeletion != nil }
}

enum AddressListAction {
    case onAppear
    case retryTapped
    case addressesResponse(Result<[Address], ProfileError>)
    case addTapped
    case editTapped(Address)
    case setDefaultTapped(Address)
    case deleteTapped(Address)
    case deleteDialogChanged(Bool)
    case deleteConfirmed
    case mutationFinished(Result<String, ProfileError>)
    /// Dari form: alamat berhasil disimpan.
    case addressSaved(isNew: Bool)
    case toastDismissed(UUID)
}

enum AddressListRoute {
    /// `nil` = alamat baru.
    case form(Address?)
}

final class AddressListStore: Store<AddressListState, AddressListAction> {
    private let repository: AddressRepository
    var onRoute: ((AddressListRoute) -> Void)?

    init(repository: AddressRepository) {
        self.repository = repository
        super.init(initialState: AddressListState())
    }

    override func reduce(state: inout AddressListState, action: AddressListAction) -> Effect<AddressListAction>? {
        switch action {
        case .onAppear:
            guard state.addresses.isIdle else { return nil }
            state.addresses = .loading
            return fetch()

        case .retryTapped:
            state.addresses = .loading
            return fetch()

        case .addressesResponse(.success(let list)):
            state.addresses = .loaded(list)
            // Toast dari aksi sebelumnya (simpan / hapus / utama) ditutup setelah daftar baru tampil.
            guard let toast = state.toast else { return nil }
            return dismissToast(id: toast.id) { .toastDismissed($0) }

        case .addressesResponse(.failure(let error)):
            if state.addresses.value == nil {
                state.addresses = .failed(error.message)
                return nil
            }
            return toast(&state, .error(error.message))

        case .addTapped:
            return .run { [weak self] in self?.onRoute?(.form(nil)) }

        case .editTapped(let address):
            return .run { [weak self] in self?.onRoute?(.form(address)) }

        case .setDefaultTapped(let address):
            guard state.busyID == nil, !address.isDefault else { return nil }
            state.busyID = address.id
            var draft = AddressDraft(address)
            draft.isDefault = true
            let repository = self.repository
            return .task {
                do {
                    _ = try await repository.updateAddress(id: address.id, draft)
                    return .mutationFinished(.success(String(localized: "\(address.label) jadi alamat utama")))
                } catch {
                    return .mutationFinished(.failure(error as? ProfileError ?? .unknown))
                }
            }

        case .deleteTapped(let address):
            state.pendingDeletion = address
            return nil

        case .deleteDialogChanged(let isPresented):
            if !isPresented { state.pendingDeletion = nil }
            return nil

        case .deleteConfirmed:
            guard let address = state.pendingDeletion else { return nil }
            state.pendingDeletion = nil
            state.busyID = address.id
            let repository = self.repository
            return .task {
                do {
                    try await repository.deleteAddress(id: address.id)
                    return .mutationFinished(.success(String(localized: "Alamat \(address.label) dihapus")))
                } catch {
                    return .mutationFinished(.failure(error as? ProfileError ?? .unknown))
                }
            }

        case .mutationFinished(let result):
            state.busyID = nil
            switch result {
            case .success(let message):
                // Alamat utama bisa pindah ke alamat lain → muat ulang daftar dari server.
                state.toast = ToastMessage(message)
                return fetch()
            case .failure(let error):
                return toast(&state, .error(error.message))
            }

        case .addressSaved(let isNew):
            state.toast = ToastMessage(isNew ? String(localized: "Alamat ditambahkan") : String(localized: "Alamat diperbarui"))
            return fetch()

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func toast(_ state: inout AddressListState, _ toast: ToastMessage) -> Effect<AddressListAction> {
        state.toast = toast
        return dismissToast(id: toast.id) { .toastDismissed($0) }
    }

    private func fetch() -> Effect<AddressListAction> {
        let repository = self.repository
        return .task {
            do {
                return .addressesResponse(.success(try await repository.addresses()))
            } catch {
                return .addressesResponse(.failure(error as? ProfileError ?? .unknown))
            }
        }
    }
}
