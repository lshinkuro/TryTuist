//
//  DefaultAuthRepository.swift
//  AuthenticationFeature · Data
//
//  Repository: ambil DTO dari data source → map ke Entity → map error ke AuthError.
//
import Foundation

struct DefaultAuthRepository: AuthRepository {
    let remote: AuthRemoteDataSource

    func login(email: String, password: String) async throws -> UserSession {
        do {
            let response = try await remote.login(email: email, password: password)
            return try AuthMapper.toEntity(response)
        } catch {
            throw AuthMapper.toDomainError(error)
        }
    }

    func register(email: String, password: String) async throws -> UserSession {
        do {
            let response = try await remote.register(email: email, password: password)
            return try AuthMapper.toEntity(response)
        } catch {
            throw AuthMapper.toDomainError(error)
        }
    }

    func signInWithGoogle(idToken: String) async throws -> UserSession {
        do {
            let response = try await remote.google(idToken: idToken)
            return try AuthMapper.toEntity(response)
        } catch {
            throw AuthMapper.toDomainError(error)
        }
    }
}
