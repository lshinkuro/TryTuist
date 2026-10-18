//
//  UserSession.swift
//  AuthenticationFeature · Domain
//
//  Entity: model bersih yang dipakai app. Tidak tahu bentuk JSON backend.
//
import Foundation

struct UserSession: Equatable {
    let userName: String
    let avatarURL: URL?
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    /// true = akun baru dibuat (daftar email, atau masuk Google pertama kali).
    var isNewUser = false

    var isExpired: Bool { expiresAt <= Date() }
}
