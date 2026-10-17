//
//  AddressFormStore.swift
//  ProfileFeature · Presentation
//
//  Tambah / ubah alamat. Validasi lewat SaveAddressUseCase (sama dengan backend).
//
import Foundation
import Utility

struct AddressFormState: Equatable {
    /// `nil` = alamat baru.
    let addressID: String?
    var draft: AddressDraft
    var fieldErrors: [String: String] = [:]
    var isSaving = false
    var errorMessage: String?
    let labelSuggestions = SaveAddressUseCase.labelSuggestions

    var isEditing: Bool { addressID != nil }
    var title: String { isEditing ? "Ubah Alamat" : "Tambah Alamat" }
    var isShowingError: Bool { errorMessage != nil }
}

enum AddressFormField: String {
    case label, recipient, phone, address, notes

    var keyPath: WritableKeyPath<AddressDraft, String> {
        switch self {
        case .label: return \.label
        case .recipient: return \.recipient
        case .phone: return \.phone
        case .address: return \.address
        case .notes: return \.notes
        }
    }
}

enum AddressFormAction {
    case textChanged(AddressFormField, String)
    case defaultToggled(Bool)
    case labelSuggestionTapped(String)
    case saveTapped
    case saveResponse(Result<Address, ProfileError>)
    case errorDismissed
}

enum AddressFormRoute {
    case saved(Address, isNew: Bool)
}

final class AddressFormStore: Store<AddressFormState, AddressFormAction> {
    private let saveAddress: SaveAddressUseCase
    var onRoute: ((AddressFormRoute) -> Void)?

    /// - Parameter isFirstAddress: alamat pertama otomatis jadi utama (aturan backend).
    init(address: Address?, isFirstAddress: Bool = false, saveAddress: SaveAddressUseCase) {
        self.saveAddress = saveAddress
        var draft = address.map { AddressDraft($0) } ?? AddressDraft()
        if address == nil, isFirstAddress { draft.isDefault = true }
        super.init(initialState: AddressFormState(addressID: address?.id, draft: draft))
    }

    override func reduce(state: inout AddressFormState, action: AddressFormAction) -> Effect<AddressFormAction>? {
        switch action {
        case .textChanged(let field, let value):
            state.draft[keyPath: field.keyPath] = value
            state.fieldErrors[field.rawValue] = nil
            return nil

        case .defaultToggled(let isOn):
            state.draft.isDefault = isOn
            return nil

        case .labelSuggestionTapped(let label):
            state.draft.label = label
            state.fieldErrors["label"] = nil
            return nil

        case .saveTapped:
            guard !state.isSaving else { return nil }
            if let error = saveAddress.validate(state.draft) {
                state.fieldErrors = error.fieldErrors
                return nil
            }
            state.isSaving = true
            let saveAddress = self.saveAddress
            let id = state.addressID
            let draft = state.draft
            return .task {
                do {
                    return .saveResponse(.success(try await saveAddress.execute(id: id, draft)))
                } catch {
                    return .saveResponse(.failure(error as? ProfileError ?? .unknown))
                }
            }

        case .saveResponse(.success(let address)):
            state.isSaving = false
            let isNew = !state.isEditing
            return .run { [weak self] in self?.onRoute?(.saved(address, isNew: isNew)) }

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
        }
    }
}
