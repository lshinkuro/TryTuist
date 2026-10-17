//
//  AuthRepository.swift
//  AuthenticationFeature · Domain
//
//  Kontrak yang dibutuhkan Domain. Implementasinya ada di layer Data.
//
import Foundation

protocol AuthRepository {
    func login(email: String, password: String) async throws -> UserSession
    func register(email: String, password: String) async throws -> UserSession
}

/// Error versi Domain — pesan siap ditampilkan, bebas dari detail HTTP/JSON.
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case invalidCredentials
    case emailAlreadyRegistered
    case invalidResponse
    case network
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Format email belum benar."
        case .weakPassword: return "Password minimal 8 karakter."
        case .invalidCredentials: return "Email atau password salah."
        case .emailAlreadyRegistered: return "Email ini sudah terdaftar. Silakan masuk."
        case .invalidResponse: return "Data dari server tidak valid. Coba lagi."
        case .network: return "Tidak ada koneksi internet."
        case .unknown: return "Terjadi kesalahan. Coba lagi beberapa saat lagi."
        }
    }
}
