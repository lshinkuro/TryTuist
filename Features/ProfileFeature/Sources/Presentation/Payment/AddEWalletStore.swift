//
//  AddEWalletStore.swift
//  ProfileFeature · Presentation
//
//  Tautkan e-wallet: pilih penyedia + nomor HP terdaftar (POST /v1/me/payment-methods).
//
import Foundation
import Utility

struct AddEWalletState: Equatable {
    let providers: [EWalletProvider]
    var wallet: NewEWallet
    var fieldErrors: [String: String] = [:]
    var isSaving = false
    var errorMessage: String?

    init(providers: [EWalletProvider]) {
        self.providers = providers
        wallet = NewEWallet(providerID: providers.first?.id ?? "", accountNumber: "", accountName: "", setAsDefault: true)
    }

    var selectedProvider: EWalletProvider? { providers.first { $0.id == wallet.providerID } }
    var isShowingError: Bool { errorMessage != nil }
}

enum AddEWalletAction {
    case providerSelected(String)
    case accountNumberChanged(String)
    case accountNameChanged(String)
    case setAsDefaultToggled(Bool)
    case saveTapped
    case saveResponse(Result<PaymentOverview, ProfileError>)
    case errorDismissed
    case cancelTapped
}

enum AddEWalletRoute {
    case added(PaymentOverview)
    case cancelled
}

final class AddEWalletStore: Store<AddEWalletState, AddEWalletAction> {
    private let addEWallet: AddEWalletUseCase
    var onRoute: ((AddEWalletRoute) -> Void)?

    init(providers: [EWalletProvider], addEWallet: AddEWalletUseCase) {
        self.addEWallet = addEWallet
        super.init(initialState: AddEWalletState(providers: providers))
    }

    override func reduce(state: inout AddEWalletState, action: AddEWalletAction) -> Effect<AddEWalletAction>? {
        switch action {
        case .providerSelected(let id):
            state.wallet.providerID = id
            state.fieldErrors["provider"] = nil
            return nil

        case .accountNumberChanged(let number):
            state.wallet.accountNumber = number
            state.fieldErrors["account_number"] = nil
            return nil

        case .accountNameChanged(let name):
            state.wallet.accountName = name
            state.fieldErrors["account_name"] = nil
            return nil

        case .setAsDefaultToggled(let isOn):
            state.wallet.setAsDefault = isOn
            return nil

        case .saveTapped:
            guard !state.isSaving else { return nil }
            if let error = addEWallet.validate(state.wallet) {
                state.fieldErrors = error.fieldErrors
                return nil
            }
            state.isSaving = true
            let addEWallet = self.addEWallet
            let wallet = state.wallet
            return .task {
                do {
                    return .saveResponse(.success(try await addEWallet.execute(wallet)))
                } catch {
                    return .saveResponse(.failure(error as? ProfileError ?? .unknown))
                }
            }

        case .saveResponse(.success(let overview)):
            state.isSaving = false
            return .run { [weak self] in self?.onRoute?(.added(overview)) }

        case .saveResponse(.failure(let error)):
            state.isSaving = false
            if error.fieldErrors.isEmpty {
                state.errorMessage = error.message
            } else {
                state.fieldErrors = error.fieldErrors
            }
            return nil

        case .errorDismissed:
            state.errorMessage = nil
            return nil

        case .cancelTapped:
            return .run { [weak self] in self?.onRoute?(.cancelled) }
        }
    }
}
