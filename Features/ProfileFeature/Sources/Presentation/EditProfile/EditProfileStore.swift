//
//  EditProfileStore.swift
//  ProfileFeature · Presentation
//
//  Edit nama & nomor HP (PATCH /v1/me). Email hanya ditampilkan (dipakai untuk login).
//
import Foundation
import Utility

struct EditProfileState: Equatable {
    let original: UserProfile
    var name: String
    var phone: String
    var fieldErrors: [String: String] = [:]
    var isSaving = false
    var errorMessage: String?

    init(profile: UserProfile) {
        original = profile
        name = profile.name
        phone = profile.phone ?? ""
    }

    var email: String { original.email }
    /// Untuk `.alert(isPresented:)`.
    var isShowingError: Bool { errorMessage != nil }
}

enum EditProfileAction {
    case nameChanged(String)
    case phoneChanged(String)
    case saveTapped
    case saveResponse(Result<UserProfile, ProfileError>)
    case errorDismissed
}

enum EditProfileRoute {
    case saved(UserProfile)
}

final class EditProfileStore: Store<EditProfileState, EditProfileAction> {
    private let updateProfile: UpdateProfileUseCase
    var onRoute: ((EditProfileRoute) -> Void)?

    init(profile: UserProfile, updateProfile: UpdateProfileUseCase) {
        self.updateProfile = updateProfile
        super.init(initialState: EditProfileState(profile: profile))
    }

    /// Tombol Simpan aktif hanya bila ada yang berubah.
    var hasChanges: Bool {
        !updateProfile.changes(from: state.original, name: state.name, phone: state.phone).isEmpty
    }

    override func reduce(state: inout EditProfileState, action: EditProfileAction) -> Effect<EditProfileAction>? {
        switch action {
        case .nameChanged(let name):
            state.name = name
            state.fieldErrors["name"] = nil
            return nil

        case .phoneChanged(let phone):
            state.phone = phone
            state.fieldErrors["phone"] = nil
            return nil

        case .saveTapped:
            guard !state.isSaving else { return nil }
            let changes = updateProfile.changes(from: state.original, name: state.name, phone: state.phone)
            guard !changes.isEmpty else {
                let original = state.original
                return .run { [weak self] in self?.onRoute?(.saved(original)) }
            }
            if let error = updateProfile.validate(changes) {
                state.fieldErrors = error.fieldErrors
                return nil
            }
            state.isSaving = true
            let updateProfile = self.updateProfile
            return .task {
                do {
                    return .saveResponse(.success(try await updateProfile.execute(changes)))
                } catch {
                    return .saveResponse(.failure(error as? ProfileError ?? .unknown))
                }
            }

        case .saveResponse(.success(let profile)):
            state.isSaving = false
            return .run { [weak self] in self?.onRoute?(.saved(profile)) }

        case .saveResponse(.failure(let error)):
            state.isSaving = false
            // Error per field tampil di bawah input; selain itu tampilkan alert.
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
