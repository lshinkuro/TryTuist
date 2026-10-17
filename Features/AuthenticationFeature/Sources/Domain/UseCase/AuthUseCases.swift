//
//  AuthUseCases.swift
//  AuthenticationFeature · Domain
//
//  Use case = satu aturan bisnis. Validasi input, panggil repository, simpan sesi.
//
import Foundation
import Utility

enum CredentialValidator {
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    static func isStrongPassword(_ password: String) -> Bool {
        password.count >= 8
    }
}

struct LoginUseCase {
    private let repository: AuthRepository
    private let saveToken: (String) -> Void

    init(repository: AuthRepository, saveToken: @escaping (String) -> Void = { _ = TokenStorage.save($0) }) {
        self.repository = repository
        self.saveToken = saveToken
    }

    func execute(email: String, password: String) async throws -> UserSession {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else { throw AuthError.invalidCredentials }

        let session = try await repository.login(email: email, password: password)
        saveToken(session.accessToken)
        return session
    }
}

struct RegisterUseCase {
    private let repository: AuthRepository
    private let saveToken: (String) -> Void

    init(repository: AuthRepository, saveToken: @escaping (String) -> Void = { _ = TokenStorage.save($0) }) {
        self.repository = repository
        self.saveToken = saveToken
    }

    func execute(email: String, password: String) async throws -> UserSession {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard CredentialValidator.isValidEmail(email) else { throw AuthError.invalidEmail }
        guard CredentialValidator.isStrongPassword(password) else { throw AuthError.weakPassword }

        let session = try await repository.register(email: email, password: password)
        saveToken(session.accessToken)
        return session
    }
}
