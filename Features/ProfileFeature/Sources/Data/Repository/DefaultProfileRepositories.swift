//
//  DefaultProfileRepositories.swift
//  ProfileFeature · Data
//
//  Repository: ambil DTO dari data source → map ke Entity → map error ke ProfileError.
//  Satu struct memenuhi keempat protocol karena semuanya memakai data source yang sama.
//
import Foundation

struct DefaultProfileRepository {
    let remote: ProfileRemoteDataSource

    private func run<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw ProfileMapper.toDomainError(error)
        }
    }
}

extension DefaultProfileRepository: ProfileRepository {
    func profile() async throws -> UserProfile {
        try await run { try ProfileMapper.profile(from: await remote.fetchProfile()) }
    }

    func updateProfile(_ changes: ProfileChanges) async throws -> UserProfile {
        try await run { try ProfileMapper.profile(from: await remote.updateProfile(ProfileMapper.param(from: changes))) }
    }
}

extension DefaultProfileRepository: AddressRepository {
    func addresses() async throws -> [Address] {
        try await run { ProfileMapper.addresses(from: try await remote.fetchAddresses()) }
    }

    func createAddress(_ draft: AddressDraft) async throws -> Address {
        try await run { try ProfileMapper.address(from: await remote.createAddress(ProfileMapper.param(from: draft))) }
    }

    func updateAddress(id: String, _ draft: AddressDraft) async throws -> Address {
        try await run { try ProfileMapper.address(from: await remote.updateAddress(id: id, ProfileMapper.param(from: draft))) }
    }

    func deleteAddress(id: String) async throws {
        try await run { _ = try await remote.deleteAddress(id: id) }
    }
}

extension DefaultProfileRepository: PaymentMethodRepository {
    func paymentOverview() async throws -> PaymentOverview {
        try await run { try ProfileMapper.paymentOverview(from: await remote.fetchPaymentOverview()) }
    }

    func addEWallet(_ wallet: NewEWallet) async throws -> PaymentOverview {
        try await run { try ProfileMapper.paymentOverview(from: await remote.addEWallet(ProfileMapper.param(from: wallet))) }
    }

    func setDefaultPaymentMethod(id: String) async throws -> PaymentOverview {
        try await run { try ProfileMapper.paymentOverview(from: await remote.setDefaultPaymentMethod(id: id)) }
    }

    func removePaymentMethod(id: String) async throws -> PaymentOverview {
        try await run { try ProfileMapper.paymentOverview(from: await remote.deletePaymentMethod(id: id)) }
    }
}

extension DefaultProfileRepository: SupportRepository {
    func helpCenter(query: String?) async throws -> HelpCenter {
        try await run { try ProfileMapper.helpCenter(from: await remote.fetchHelpCenter(query: query)) }
    }

    func legalDocument(_ kind: LegalDocumentKind) async throws -> LegalDocument {
        try await run { try ProfileMapper.legalDocument(kind, from: await remote.fetchLegalDocument(slug: kind.rawValue)) }
    }
}
