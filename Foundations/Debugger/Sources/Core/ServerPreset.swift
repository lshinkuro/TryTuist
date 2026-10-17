//
//  ServerPreset.swift
//  Debugger
//
//  Daftar server yang bisa dipilih di tab "Server".
//  Samakan dengan Configs/<Env>.xcconfig bila domain / API key berubah.
//
import Foundation
import Utility

public struct ServerPreset: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let environment: AppEnvironment
    public let baseURL: String
    public let apiKey: String

    public init(id: String, title: String, environment: AppEnvironment, baseURL: String, apiKey: String) {
        self.id = id
        self.title = title
        self.environment = environment
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    public static let all: [ServerPreset] = [
        ServerPreset(id: "dev-localhost",
                     title: "Dev · 172.20.10.3:8080",
                     environment: .dev,
                     baseURL: "http://172.20.10.3:8080",
                     apiKey: "dev-local-api-key"),
        ServerPreset(id: "staging",
                     title: "Staging",
                     environment: .staging,
                     baseURL: "https://staging-api.trytuist.com",
                     apiKey: "staging-api-key-change-me"),
        ServerPreset(id: "prod",
                     title: "Prod",
                     environment: .prod,
                     baseURL: "https://api.trytuist.com",
                     apiKey: "prod-api-key-change-me")
    ]
}
