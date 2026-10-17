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
            expiresAt: dto.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? .distantFuture
        )
    }

    static func toDomainError(_ error: Error) -> AuthError {
        switch error {
        case let error as AuthError:
            return error
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
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
