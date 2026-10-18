//
//  DefaultPaymentRepository.swift
//  HomeFeature · Data
//
import Foundation

struct DefaultPaymentRepository: PaymentRepository {
    let remote: PaymentRemoteDataSource

    func status(id: String) async throws -> PaymentSession {
        try await map { try await remote.status(id: id) }
    }

    func cancel(id: String) async throws -> PaymentSession {
        try await map { try await remote.cancel(id: id) }
    }

    func pending() async throws -> [PaymentSession] {
        do {
            return (try await remote.pending().data ?? []).compactMap(PaymentMapper.session(from:))
        } catch {
            throw PaymentMapper.toDomainError(error)
        }
    }

    private func map(_ call: () async throws -> PaymentResponseDTO) async throws -> PaymentSession {
        do {
            guard let dto = try await call().data, let session = PaymentMapper.session(from: dto) else {
                throw PaymentError.notFound
            }
            return session
        } catch {
            throw PaymentMapper.toDomainError(error)
        }
    }
}
