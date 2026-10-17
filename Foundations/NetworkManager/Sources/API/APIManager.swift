//
//  APIManager.swift
//  NetworkManager
//
//  Dua cara memanggil API:
//  - `request` / `fetchRequest`: status non-2xx → `APIError.invalidStatusCode(code)` (dipakai Auth, Katalog, Order).
//  - `send`: status non-2xx → `APIServerError` berisi `type`, `message`, dan error per field dari backend.
//    Pakai untuk form yang perlu menampilkan pesan validasi server (Profil, Alamat, Pembayaran).
//

import Foundation
import Utility

public final class APIManager {
    public static let shared = APIManager()
    private let session: URLSession
    private let decoder = JSONDecoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    public enum APIError: Error {
        case failedToCreateRequest
        case failedToGetData
        case invalidStatusCode(Int)
    }

    /// Cara memetakan status non-2xx menjadi Error.
    enum ErrorStyle {
        case statusCode
        case serverBody
    }
}

/// Error dari backend: `{ "code": 400, "message": "...", "error": { "type": "...", "details": [{ "field", "message" }] } }`.
public struct APIServerError: Error, LocalizedError, Equatable {
    public let statusCode: Int
    /// Mis. `VALIDATION_ERROR`, `PAYMENT_METHOD_EXISTS`, `NOT_FOUND`.
    public let type: String?
    public let message: String?
    /// field → pesan, mis. `["phone": "nomor HP tidak valid"]`.
    public let fieldErrors: [String: String]

    public init(statusCode: Int, type: String? = nil, message: String? = nil, fieldErrors: [String: String] = [:]) {
        self.statusCode = statusCode
        self.type = type
        self.message = message
        self.fieldErrors = fieldErrors
    }

    public var errorDescription: String? { message }

    init(statusCode: Int, body: Data?) {
        let decoded = body.flatMap({ try? JSONDecoder().decode(ErrorEnvelope.self, from: $0) })
        var fields: [String: String] = [:]
        for detail in decoded?.error?.details ?? [] {
            guard let field = detail.field, let message = detail.message, fields[field] == nil else { continue }
            fields[field] = message
        }
        self.init(statusCode: statusCode, type: decoded?.error?.type, message: decoded?.message, fieldErrors: fields)
    }

    private struct ErrorEnvelope: Decodable {
        struct Body: Decodable {
            let type: String?
            let details: [Detail]?
        }
        struct Detail: Decodable {
            let field: String?
            let message: String?
        }
        let message: String?
        let error: Body?
    }
}

public extension APIManager {
    /// Request generik berbasis URLSession. Completion selalu dipanggil di main thread.
    func fetchRequest<T: Decodable>(endpoint: EndpointAPI,
                                    expecting type: T.Type,
                                    completion: @escaping (Result<T, Error>) -> Void) {
        perform(endpoint, expecting: type, errorStyle: .statusCode, completion: completion)
    }
}

extension APIManager {
    func perform<T: Decodable>(_ endpoint: EndpointAPI,
                               expecting type: T.Type,
                               errorStyle: ErrorStyle,
                               completion: @escaping (Result<T, Error>) -> Void) {
        let finish: (Result<T, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        let request: URLRequest
        do {
            request = try endpoint.makeRequest()
        } catch {
            // Pakai path, bukan "\(endpoint)": associated value bisa berisi password.
            NetworkLogger.logBuildFailure(endpoint: endpoint.path, error: error)
            finish(.failure(error))
            return
        }

        let logID = NetworkLogger.logRequest(request)
        let startedAt = Date()

        session.dataTask(with: request) { [decoder] data, response, error in
            NetworkLogger.logResponse(id: logID, request: request, response: response,
                                      data: data, error: error, startedAt: startedAt)
            if let error {
                finish(.failure(error))
                return
            }
            // Setara dengan `.validate()` Alamofire: hanya status 2xx yang sukses.
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                // Token kedaluwarsa / tidak valid di endpoint yang butuh login → sesi habis (global).
                if http.statusCode == 401, endpoint.requiresAuth {
                    SessionEvents.postExpired(path: endpoint.path)
                }
                switch errorStyle {
                case .statusCode:
                    finish(.failure(APIError.invalidStatusCode(http.statusCode)))
                case .serverBody:
                    finish(.failure(APIServerError(statusCode: http.statusCode, body: data)))
                }
                return
            }
            guard let data else {
                finish(.failure(APIError.failedToGetData))
                return
            }
            do {
                finish(.success(try decoder.decode(T.self, from: data)))
            } catch {
                NetworkLogger.logDecodingFailure(id: logID, type: T.self, error: error)
                finish(.failure(error))
            }
        }.resume()
    }
}
