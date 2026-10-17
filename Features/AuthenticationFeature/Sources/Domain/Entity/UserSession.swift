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

    var isExpired: Bool { expiresAt <= Date() }
}
