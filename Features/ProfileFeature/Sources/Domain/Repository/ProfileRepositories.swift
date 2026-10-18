//
//  ProfileRepositories.swift
//  ProfileFeature · Domain
//
//  Kontrak data fitur Profil. Implementasi ada di Data (API / Mock).
//
import Foundation

protocol ProfileRepository {
    func profile() async throws -> UserProfile
    func updateProfile(_ changes: ProfileChanges) async throws -> UserProfile
}

protocol AddressRepository {
    func addresses() async throws -> [Address]
    func createAddress(_ draft: AddressDraft) async throws -> Address
    func updateAddress(id: String, _ draft: AddressDraft) async throws -> Address
    func deleteAddress(id: String) async throws
}

protocol PaymentMethodRepository {
    func paymentOverview() async throws -> PaymentOverview
    func addEWallet(_ wallet: NewEWallet) async throws -> PaymentOverview
    func setDefaultPaymentMethod(id: String) async throws -> PaymentOverview
    func removePaymentMethod(id: String) async throws -> PaymentOverview
}

protocol SupportRepository {
    func helpCenter(query: String?) async throws -> HelpCenter
    func legalDocument(_ kind: LegalDocumentKind) async throws -> LegalDocument
}

/// Error domain fitur Profil. Store hanya mengenal tipe ini.
enum ProfileError: Error, Equatable, LocalizedError {
    /// Validasi (lokal atau dari server). `fields`: nama field backend → pesan.
    case validation(message: String, fields: [String: String])
    /// Data sudah ada, mis. e-wallet dengan nomor yang sama.
    case conflict(String)
    /// Ditolak aturan bisnis, mis. batas jumlah, metode tidak tersedia.
    case rejected(String)
    case notFound
    case sessionExpired
    case network
    case unknown

    var errorDescription: String? {
        switch self {
        case .validation(let message, _): return message
        case .conflict(let message), .rejected(let message): return message
        case .notFound: return String(localized: "Data tidak ditemukan. Coba muat ulang.")
        case .sessionExpired: return String(localized: "Sesi kamu sudah habis. Silakan masuk lagi.")
        case .network: return String(localized: "Tidak bisa terhubung. Periksa koneksi internetmu.")
        case .unknown: return String(localized: "Terjadi kesalahan. Coba lagi nanti.")
        }
    }

    var fieldErrors: [String: String] {
        if case .validation(_, let fields) = self { return fields }
        return [:]
    }

    /// Pesan untuk alert/toast: error per field sudah tampil di bawah input, jadi cukup pesan umum.
    var message: String { errorDescription ?? "" }
}
