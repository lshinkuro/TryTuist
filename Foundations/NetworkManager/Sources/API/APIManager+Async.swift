//
//  APIManager+Async.swift
//  NetworkManager
//
import Foundation

public extension APIManager {
    /// Versi async/await dari `fetchRequest`. Dipakai oleh RemoteDataSource di layer Data.
    func request<T: Decodable>(_ endpoint: EndpointAPI, as type: T.Type = T.self) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            fetchRequest(endpoint: endpoint, expecting: type) { result in
                continuation.resume(with: result)
            }
        }
    }
}

/// Bungkus response standar dari backend: `{ "code": 200, "message": "...", "data": ... }`.
/// DTO feature cukup mendefinisikan isi `data`, mis. `APIEnvelope<SessionDTO>`.
public struct APIEnvelope<T: Decodable>: Decodable {
    public let code: Int
    public let message: String
    public let data: T?
}
