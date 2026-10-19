//
//  AuthMockDataSource.swift
//  AuthenticationFeature · Data
//
//  Meniru backend: menghasilkan JSON yang sama bentuknya dengan API asli,
//  lalu di-decode ke DTO. Jadi Mapper & Repository ikut teruji walau tanpa server.
//  Error dikirim sebagai status HTTP (401/409) seperti backend sungguhan.
//
import Foundation
import NetworkManager

final class AuthMockDataSource: AuthRemoteDataSource {
    struct Account: Codable {
        let name: String
        let email: String
        let password: String
    }

    /// Akun bawaan untuk testing.
    static let defaultAccounts: [Account] = [
        Account(name: "Kholis", email: "kholis@gmail.com", password: "12345678"),
        Account(name: "Demo User", email: "demo@trytuist.com", password: "password123")
    ]

    private let latency: Duration
    private let defaults: UserDefaults
    private let storageKey = "mock.registeredAccounts"

    init(latency: Duration = .milliseconds(800), defaults: UserDefaults = .standard) {
        self.latency = latency
        self.defaults = defaults
    }

    func login(email: String, password: String) async throws -> SessionResponseDTO {
        try await Task.sleep(for: latency)
        let email = normalized(email)
        guard let account = allAccounts.first(where: { normalized($0.email) == email && $0.password == password }) else {
            throw APIManager.APIError.invalidStatusCode(401)
        }
        return try successResponse(for: account)
    }

    func register(email: String, password: String) async throws -> SessionResponseDTO {
        try await Task.sleep(for: latency)
        let email = normalized(email)
        guard !allAccounts.contains(where: { normalized($0.email) == email }) else {
            throw APIManager.APIError.invalidStatusCode(409)
        }
        let name = email.split(separator: "@").first.map { String($0).capitalized } ?? "User"
        let account = Account(name: name, email: email, password: password)
        registeredAccounts.append(account)
        return try successResponse(for: account, isNewUser: true)
    }

    /// Meniru `/v1/auth/google`: token dari `MockGoogleSignInClient` → akun Kholis (sudah ada).
    func google(idToken: String) async throws -> SessionResponseDTO {
        try await Task.sleep(for: latency)
        guard idToken == MockGoogleSignInClient.token, let account = Self.defaultAccounts.first else {
            throw APIServerError(statusCode: 401, type: "INVALID_GOOGLE_TOKEN", message: "Login Google gagal diverifikasi.")
        }
        return try successResponse(for: account)
    }

    func forgotPassword(email: String) async throws {
        try await Task.sleep(for: latency)
    }

    /// Kode mock selalu `123456`.
    func resetPassword(email: String, code: String, newPassword: String) async throws -> SessionResponseDTO {
        try await Task.sleep(for: latency)
        let email = normalized(email)
        guard code == "123456", let account = allAccounts.first(where: { normalized($0.email) == email }) else {
            throw APIServerError(statusCode: 422, type: "INVALID_CODE", message: "Kode salah atau sudah kedaluwarsa.")
        }
        return try successResponse(for: account)
    }

    // MARK: - Fixture

    private func successResponse(for account: Account, isNewUser: Bool = false) throws -> SessionResponseDTO {
        let expiresAt = Int(Date().addingTimeInterval(7 * 24 * 60 * 60).timeIntervalSince1970)
        let json: [String: Any] = [
            "code": 200,
            "message": "success",
            "data": [
                "user_name": account.name,
                "user_image": "",
                "access_token": "mock-access-\(UUID().uuidString)",
                "refresh_token": "mock-refresh-\(UUID().uuidString)",
                "expires_at": expiresAt,
                "is_new_user": isNewUser
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(SessionResponseDTO.self, from: data)
    }

    // MARK: - Storage akun hasil Sign Up

    private var allAccounts: [Account] { Self.defaultAccounts + registeredAccounts }

    private var registeredAccounts: [Account] {
        get {
            guard let data = defaults.data(forKey: storageKey) else { return [] }
            return (try? JSONDecoder().decode([Account].self, from: data)) ?? []
        }
        set {
            defaults.set(try? JSONEncoder().encode(newValue), forKey: storageKey)
        }
    }

    private func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
