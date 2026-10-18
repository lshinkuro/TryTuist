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
    /// Daftar & masuk dengan Google: kirim ID token ke backend → sesi app.
    func signInWithGoogle(idToken: String) async throws -> UserSession
}

/// Hasil Google Sign-In di device (sebelum dikirim ke backend).
struct GoogleAccount: Equatable {
    let idToken: String
    let email: String?
    let name: String?
}

/// Menampilkan sheet Google & mengembalikan ID token. Implementasi: SDK GoogleSignIn atau Mock.
protocol GoogleSignInClient {
    @MainActor func signIn() async throws -> GoogleAccount
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
    /// User menutup sheet Google — bukan error, tidak perlu pesan.
    case googleCancelled
    /// GOOGLE_CLIENT_ID belum diisi di xcconfig, atau backend belum mengaktifkan Google.
    case googleNotConfigured
    /// Token Google ditolak / sheet Google gagal.
    case googleFailed
    /// Akun dibuat lewat Google (tanpa password) lalu dicoba masuk pakai password.
    case useGoogleSignIn
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Format email belum benar."
        case .weakPassword: return "Password minimal 8 karakter."
        case .invalidCredentials: return "Email atau password salah."
        case .emailAlreadyRegistered: return "Email ini sudah terdaftar. Silakan masuk."
        case .invalidResponse: return "Data dari server tidak valid. Coba lagi."
        case .network: return "Tidak ada koneksi internet."
        case .unknown: return "Terjadi kesalahan. Coba lagi beberapa saat lagi."
        case .googleCancelled: return nil
        case .googleNotConfigured: return "Masuk dengan Google belum tersedia. Gunakan email dan password."
        case .googleFailed: return "Login Google gagal. Coba lagi."
        case .useGoogleSignIn: return "Akun ini terdaftar dengan Google. Silakan pakai tombol Google."
        case .rateLimited: return "Terlalu banyak percobaan. Coba lagi dalam 1 menit."
        }
    }
}
