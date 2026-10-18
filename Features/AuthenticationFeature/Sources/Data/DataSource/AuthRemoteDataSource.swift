//
//  AuthRemoteDataSource.swift
//  AuthenticationFeature · Data
//
//  Data source hanya bicara DTO. Ada dua implementasi: API (backend asli) & Mock.
//
import Foundation
import NetworkManager

protocol AuthRemoteDataSource {
    func login(email: String, password: String) async throws -> SessionResponseDTO
    func register(email: String, password: String) async throws -> SessionResponseDTO
    func google(idToken: String) async throws -> SessionResponseDTO
}

/// Pakai `send` supaya tipe error server (mis. `USE_GOOGLE_SIGN_IN`, `INVALID_GOOGLE_TOKEN`) ikut terbawa.
struct AuthAPIDataSource: AuthRemoteDataSource {
    var api: APIManager = .shared

    func login(email: String, password: String) async throws -> SessionResponseDTO {
        try await api.send(.login(param: LoginParam(email: email, password: password)))
    }

    func register(email: String, password: String) async throws -> SessionResponseDTO {
        try await api.send(.register(param: RegisterParam(email: email, password: password)))
    }

    func google(idToken: String) async throws -> SessionResponseDTO {
        try await api.send(.googleSignIn(param: GoogleSignInParam(idToken: idToken)))
    }
}
