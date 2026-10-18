//
//  ProfileUseCases.swift
//  ProfileFeature · Domain
//
//  Aturan bisnis fitur Profil. Validasi di sini SAMA dengan backend (API_PLAN.md §5.16, §5.17, §5.21),
//  supaya error tampil sebelum request dikirim. Key `fields` = nama field backend.
//
import Foundation

enum PhoneNumber {
    /// Buang spasi, strip, titik, kurung. "+62 812-3456" → "+628123456".
    static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { !" -.()".contains($0) }
    }

    /// 08…, 628…, atau +628…, total 10–15 digit (sama dengan regex backend).
    static func isValid(_ text: String) -> Bool {
        normalized(text).range(of: #"^(?:\+?62|0)8[0-9]{7,12}$"#, options: .regularExpression) != nil
    }

    static let invalidMessage = String(localized: "Nomor HP tidak valid, contoh 081234567890")
}

private func validationError(_ fields: [String: String]) -> ProfileError? {
    fields.isEmpty ? nil : .validation(message: String(localized: "Periksa lagi data yang kamu isi."), fields: fields)
}

private func trimmed(_ text: String) -> String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Profil

struct GetProfileUseCase {
    let repository: ProfileRepository

    func execute() async throws -> UserProfile {
        try await repository.profile()
    }
}

struct UpdateProfileUseCase {
    let repository: ProfileRepository

    static let maxNameLength = 100

    /// Hanya field yang berubah dari `original` yang dikirim.
    func changes(from original: UserProfile, name: String, phone: String) -> ProfileChanges {
        let name = trimmed(name)
        let phone = PhoneNumber.normalized(phone)
        return ProfileChanges(name: name == original.name ? nil : name,
                              phone: phone == (original.phone ?? "") ? nil : phone)
    }

    func validate(_ changes: ProfileChanges) -> ProfileError? {
        var fields: [String: String] = [:]
        if let name = changes.name {
            if name.isEmpty { fields["name"] = String(localized: "Nama wajib diisi") }
            else if name.count > Self.maxNameLength { fields["name"] = String(localized: "Maksimal \(Self.maxNameLength) karakter") }
        }
        if let phone = changes.phone, !phone.isEmpty, !PhoneNumber.isValid(phone) {
            fields["phone"] = PhoneNumber.invalidMessage
        }
        return validationError(fields)
    }

    func execute(_ changes: ProfileChanges) async throws -> UserProfile {
        if let error = validate(changes) { throw error }
        return try await repository.updateProfile(changes)
    }
}

// MARK: - Alamat

struct SaveAddressUseCase {
    let repository: AddressRepository

    static let labelSuggestions = [String(localized: "Rumah"), String(localized: "Kantor"), String(localized: "Kos"), String(localized: "Apartemen")]

    func validate(_ draft: AddressDraft) -> ProfileError? {
        var fields: [String: String] = [:]
        func check(_ key: String, _ value: String, required: Bool = true, max: Int) {
            let value = trimmed(value)
            if required, value.isEmpty { fields[key] = String(localized: "Wajib diisi") }
            else if value.count > max { fields[key] = String(localized: "Maksimal \(max) karakter") }
        }
        check("label", draft.label, max: 50)
        check("recipient", draft.recipient, max: 100)
        check("address", draft.address, max: 500)
        check("notes", draft.notes, required: false, max: 500)
        if trimmed(draft.phone).isEmpty { fields["phone"] = String(localized: "Wajib diisi") }
        else if !PhoneNumber.isValid(draft.phone) { fields["phone"] = PhoneNumber.invalidMessage }
        return validationError(fields)
    }

    /// `id == nil` → alamat baru.
    func execute(id: String?, _ draft: AddressDraft) async throws -> Address {
        if let error = validate(draft) { throw error }
        var clean = draft
        clean.label = trimmed(draft.label)
        clean.recipient = trimmed(draft.recipient)
        clean.phone = PhoneNumber.normalized(draft.phone)
        clean.address = trimmed(draft.address)
        clean.notes = trimmed(draft.notes)
        if let id { return try await repository.updateAddress(id: id, clean) }
        return try await repository.createAddress(clean)
    }
}

// MARK: - Metode pembayaran

struct AddEWalletUseCase {
    let repository: PaymentMethodRepository

    func validate(_ wallet: NewEWallet) -> ProfileError? {
        var fields: [String: String] = [:]
        if wallet.providerID.isEmpty { fields["provider"] = String(localized: "Pilih penyedia e-wallet") }
        if trimmed(wallet.accountNumber).isEmpty { fields["account_number"] = String(localized: "Wajib diisi") }
        else if !PhoneNumber.isValid(wallet.accountNumber) { fields["account_number"] = PhoneNumber.invalidMessage }
        if wallet.accountName.count > 100 { fields["account_name"] = String(localized: "Maksimal 100 karakter") }
        return validationError(fields)
    }

    func execute(_ wallet: NewEWallet) async throws -> PaymentOverview {
        if let error = validate(wallet) { throw error }
        var clean = wallet
        clean.accountNumber = PhoneNumber.normalized(wallet.accountNumber)
        clean.accountName = trimmed(wallet.accountName)
        return try await repository.addEWallet(clean)
    }
}
