//
//  AuthMapper.swift
//  AuthenticationFeature · Data
//
//  Mapper: DTO → Entity, dan error teknis → AuthError.
//
import Foundation
import NetworkManager

enum AuthMapper {
    static func toEntity(_ response: SessionResponseDTO) throws -> UserSession {
        guard let dto = response.data,
              let accessToken = dto.accessToken, !accessToken.isEmpty else {
            throw AuthError.invalidResponse
        }

        return UserSession(
            userName: dto.userName?.nonEmpty ?? "User",
            avatarURL: dto.userImage.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            accessToken: accessToken,
            refreshToken: dto.refreshToken ?? "",
            expiresAt: dto.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? .distantFuture,
            isNewUser: dto.isNewUser ?? false
        )
    }

    static func toDomainError(_ error: Error) -> AuthError {
        switch error {
        case let error as AuthError:
            return error
        case let server as APIServerError:
            return domainError(from: server)
        case APIManager.APIError.invalidStatusCode(let code) where code == 400 || code == 401:
            return .invalidCredentials
        case APIManager.APIError.invalidStatusCode(409):
            return .emailAlreadyRegistered
        case is URLError:
            return .network
        case is DecodingError:
            return .invalidResponse
        default:
            return .unknown
        }
    }

    /// Error dari backend (API_PLAN.md §5.2, §5.3, §5.3b).
    private static func domainError(from server: APIServerError) -> AuthError {
        switch server.type {
        case "USE_GOOGLE_SIGN_IN"?: return .useGoogleSignIn
        case "INVALID_GOOGLE_TOKEN"?: return .googleFailed
        case "GOOGLE_SIGN_IN_DISABLED"?: return .googleNotConfigured
        case "RATE_LIMITED"?: return .rateLimited
        case "INVALID_CODE"?, "CODE_LOCKED"?: return .server(server.message ?? AuthError.unknown.errorDescription ?? "")
        default: break
        }
        switch server.statusCode {
        case 400, 401: return .invalidCredentials
        case 409: return .emailAlreadyRegistered
        case 429: return .rateLimited
        default: return .unknown
        }
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
