//
//  ProfileRemoteDataSource.swift
//  ProfileFeature · Data
//
//  Hanya bicara DTO. Kontrak: API_PLAN.md §5.16, §5.17, §5.21–5.23.
//
import Foundation
import NetworkManager

protocol ProfileRemoteDataSource {
    func fetchProfile() async throws -> UserProfileResponseDTO
    func updateProfile(_ param: UpdateProfileParam) async throws -> UserProfileResponseDTO

    func fetchAddresses() async throws -> AddressListResponseDTO
    func createAddress(_ param: AddressParam) async throws -> AddressResponseDTO
    func updateAddress(id: String, _ param: AddressParam) async throws -> AddressResponseDTO
    func deleteAddress(id: String) async throws -> EmptyResponseDTO

    func fetchPaymentOverview() async throws -> PaymentOverviewResponseDTO
    func addEWallet(_ param: AddEWalletParam) async throws -> PaymentOverviewResponseDTO
    func setDefaultPaymentMethod(id: String) async throws -> PaymentOverviewResponseDTO
    func deletePaymentMethod(id: String) async throws -> PaymentOverviewResponseDTO

    func fetchHelpCenter(query: String?) async throws -> HelpCenterResponseDTO
    func fetchLegalDocument(slug: String) async throws -> LegalDocumentResponseDTO

    func changePassword(current: String, new: String) async throws -> PasswordSessionResponseDTO
    func sendEmailVerification() async throws -> EmptyResponseDTO
    func verifyEmail(code: String) async throws -> EmptyResponseDTO
}

/// Backend asli (Go). Pakai `send` supaya pesan validasi & tipe error dari server ikut terbawa.
struct ProfileAPIDataSource: ProfileRemoteDataSource {
    var api: APIManager = .shared

    func fetchProfile() async throws -> UserProfileResponseDTO {
        try await api.send(.profile)
    }

    func updateProfile(_ param: UpdateProfileParam) async throws -> UserProfileResponseDTO {
        try await api.send(.updateProfile(param: param))
    }

    func fetchAddresses() async throws -> AddressListResponseDTO {
        try await api.send(.addresses)
    }

    func createAddress(_ param: AddressParam) async throws -> AddressResponseDTO {
        try await api.send(.createAddress(param: param))
    }

    func updateAddress(id: String, _ param: AddressParam) async throws -> AddressResponseDTO {
        try await api.send(.updateAddress(id: id, param: param))
    }

    func deleteAddress(id: String) async throws -> EmptyResponseDTO {
        try await api.send(.deleteAddress(id: id))
    }

    func fetchPaymentOverview() async throws -> PaymentOverviewResponseDTO {
        try await api.send(.paymentMethods)
    }

    func addEWallet(_ param: AddEWalletParam) async throws -> PaymentOverviewResponseDTO {
        try await api.send(.addEWallet(param: param))
    }

    func setDefaultPaymentMethod(id: String) async throws -> PaymentOverviewResponseDTO {
        try await api.send(.setDefaultPaymentMethod(id: id))
    }

    func deletePaymentMethod(id: String) async throws -> PaymentOverviewResponseDTO {
        try await api.send(.deletePaymentMethod(id: id))
    }

    func fetchHelpCenter(query: String?) async throws -> HelpCenterResponseDTO {
        try await api.send(.helpCenter(query: query))
    }

    func fetchLegalDocument(slug: String) async throws -> LegalDocumentResponseDTO {
        try await api.send(.legalDocument(slug: slug))
    }

    func changePassword(current: String, new: String) async throws -> PasswordSessionResponseDTO {
        try await api.send(.changePassword(current: current, new: new))
    }

    func sendEmailVerification() async throws -> EmptyResponseDTO {
        try await api.send(.sendEmailVerification)
    }

    func verifyEmail(code: String) async throws -> EmptyResponseDTO {
        try await api.send(.verifyEmail(code: code))
    }
}
