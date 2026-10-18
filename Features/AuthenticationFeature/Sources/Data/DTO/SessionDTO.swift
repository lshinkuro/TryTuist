//
//  SessionDTO.swift
//  AuthenticationFeature · Data
//
//  DTO = cermin 1:1 JSON backend. Semua field optional supaya response
//  yang kurang lengkap tidak membuat decode gagal; validasi dilakukan di Mapper.
//
//  {
//    "code": 200,
//    "message": "success",
//    "data": {
//      "user_name": "Kholis",
//      "user_image": "https://...",
//      "access_token": "eyJ...",
//      "refresh_token": "eyJ...",
//      "expires_at": 1729152000,
//      "is_new_user": false
//    }
//  }
//
import Foundation
import NetworkManager

struct SessionDTO: Decodable {
    let userName: String?
    let userImage: String?
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: Int?
    /// Dari register & `/v1/auth/google` (true = akun baru dibuat).
    let isNewUser: Bool?

    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case userImage = "user_image"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case isNewUser = "is_new_user"
    }
}

typealias SessionResponseDTO = APIEnvelope<SessionDTO>
