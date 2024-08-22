//
//  ParameterAPI.swift
//  NetworkManager
//
//  Created by Phincon on 19/08/24.
//

import Foundation

// MARK: - RegisterParam
public struct RegisterParam {
    public let email: String?
    public let password: String?
    public let firebaseToken: String?
    
    public init(email: String, password: String, firebaseToken: String = "") {
        self.email = email
        self.password = password
        self.firebaseToken = firebaseToken
    }
}

// MARK: - LoginParam
public struct LoginParam {
    public let email: String
    public let password: String
    public let firebaseToken: String

    
    public init(email: String, password: String, firebaseToken: String = "") {
        self.email = email
        self.password = password
        self.firebaseToken = firebaseToken
    }
}


// MARK: - BaseResponse
public struct BaseResponse: Codable {
    public let code: Int
    public let message: String
    public let data: LoginResponse?
}

// MARK: - LoginResponse
public struct LoginResponse: Codable {
    public let userName: String
    public let userImage: String
    public let accessToken, refreshToken: String
    public let expiresAt: Int
}
