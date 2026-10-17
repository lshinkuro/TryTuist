//
//  PaymentMethodsStore.swift
//  ProfileFeature · Presentation
//
//  Pilih metode utama, tautkan & hapus e-wallet (/v1/me/payment-methods).
//  Setiap response backend = overview lengkap terbaru, jadi state cukup diganti.
//
import Foundation
import TTUI
import Utility

struct PaymentMethodsState: Equatable {
    var overview: Loadable<PaymentOverview> = .idle
    var busyID: String?
    var pendingRemoval: PaymentMethod?
    var toast: ToastMessage?

    var isConfirmingRemoval: Bool { pendingRemoval != nil }
}

enum PaymentMethodsAction {
    case onAppear
    case retryTapped
    case overviewResponse(Result<PaymentOverview, ProfileError>)
    case methodTapped(PaymentMethod)
    case removeTapped(PaymentMethod)
    case removeDialogChanged(Bool)
    case removeConfirmed
    case mutationResponse(Result<PaymentOverview, ProfileError>, successMessage: String)
    case addTapped
    /// Dari form Tambah E-Wallet.
    case eWalletAdded(PaymentOverview)
    case toastDismissed(UUID)
}

enum PaymentMethodsRoute {
    case addEWallet(providers: [EWalletProvider])
}

final class PaymentMethodsStore: Store<PaymentMethodsState, PaymentMethodsAction> {
    private let repository: PaymentMethodRepository
    var onRoute: ((PaymentMethodsRoute) -> Void)?

    init(repository: PaymentMethodRepository) {
        self.repository = repository
        super.init(initialState: PaymentMethodsState())
    }

    override func reduce(state: inout PaymentMethodsState, action: PaymentMethodsAction) -> Effect<PaymentMethodsAction>? {
        switch action {
        case .onAppear:
            guard state.overview.isIdle else { return nil }
            state.overview = .loading
            return fetch()

        case .retryTapped:
            state.overview = .loading
            return fetch()

        case .overviewResponse(.success(let overview)):
            state.overview = .loaded(overview)
            return nil

        case .overviewResponse(.failure(let error)):
            state.overview = .failed(error.message)
            return nil

        case .methodTapped(let method):
            guard state.busyID == nil, !method.isDefault else { return nil }
            guard method.isEnabled else {
                return showToast(&state, .error("\(method.name) sedang tidak tersedia"))
            }
            state.busyID = method.id
            let repository = self.repository
            return .task {
                do {
                    return .mutationResponse(.success(try await repository.setDefaultPaymentMethod(id: method.id)),
                                             successMessage: "\(method.name) jadi metode utama")
                } catch {
                    return .mutationResponse(.failure(error as? ProfileError ?? .unknown), successMessage: "")
                }
            }

        case .removeTapped(let method):
            guard method.isRemovable else { return nil }
            state.pendingRemoval = method
            return nil

        case .removeDialogChanged(let isPresented):
            if !isPresented { state.pendingRemoval = nil }
            return nil

        case .removeConfirmed:
            guard let method = state.pendingRemoval else { return nil }
            state.pendingRemoval = nil
            state.busyID = method.id
            let repository = self.repository
            return .task {
                do {
                    return .mutationResponse(.success(try await repository.removePaymentMethod(id: method.id)),
                                             successMessage: "\(method.name) dihapus")
                } catch {
                    return .mutationResponse(.failure(error as? ProfileError ?? .unknown), successMessage: "")
                }
            }

        case .mutationResponse(.success(let overview), let message):
            state.busyID = nil
            state.overview = .loaded(overview)
            return showToast(&state, ToastMessage(message))

        case .mutationResponse(.failure(let error), _):
            state.busyID = nil
            return showToast(&state, .error(error.message))

        case .addTapped:
            guard let overview = state.overview.value, overview.canAddEWallet else { return nil }
            return .run { [weak self] in self?.onRoute?(.addEWallet(providers: overview.providers)) }

        case .eWalletAdded(let overview):
            state.overview = .loaded(overview)
            return showToast(&state, ToastMessage("E-wallet berhasil ditautkan"))

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func showToast(_ state: inout PaymentMethodsState, _ toast: ToastMessage) -> Effect<PaymentMethodsAction> {
        state.toast = toast
        return dismissToast(id: toast.id) { .toastDismissed($0) }
    }

    private func fetch() -> Effect<PaymentMethodsAction> {
        let repository = self.repository
        return .task {
            do {
                return .overviewResponse(.success(try await repository.paymentOverview()))
            } catch {
                return .overviewResponse(.failure(error as? ProfileError ?? .unknown))
            }
        }
    }
}
