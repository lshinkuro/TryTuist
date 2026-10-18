//
//  TokenRefresher.swift
//  NetworkManager
//
//  Memperbarui access token lewat `POST /v1/auth/refresh` (API_PLAN.md §5.4).
//  Backend merotasi refresh token, jadi request yang butuh refresh bersamaan harus
//  menunggu SATU refresh yang sama; refresh kedua dengan token lama akan ditolak.
//
import Foundation
import Utility

final class TokenRefresher {
    static let shared = TokenRefresher()

    enum Outcome {
        /// Token baru sudah disimpan di TokenStorage.
        case refreshed
        /// Server menolak refresh token (kedaluwarsa / dicabut) → sesi benar-benar habis.
        case rejected
        /// Gagal karena jaringan / server error; sesi tetap disimpan, coba lagi nanti.
        case failed
    }

    private let lock = NSLock()
    private var waiting: [(Outcome) -> Void] = []
    private var isRefreshing = false
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Completion dipanggil di thread background.
    func refresh(completion: @escaping (Outcome) -> Void) {
        lock.lock()
        waiting.append(completion)
        if isRefreshing {
            lock.unlock()
            return
        }
        isRefreshing = true
        lock.unlock()

        guard let refreshToken = TokenStorage.refreshToken else {
            finish(.rejected)
            return
        }
        let endpoint = EndpointAPI.refreshToken(refreshToken: refreshToken)
        guard let request = try? endpoint.makeRequest() else {
            finish(.failed)
            return
        }
        let logID = NetworkLogger.logRequest(request)
        let startedAt = Date()
        session.dataTask(with: request) { [weak self] data, response, error in
            NetworkLogger.logResponse(id: logID, request: request, response: response,
                                      data: data, error: error, startedAt: startedAt)
            guard let self else { return }
            guard error == nil, let http = response as? HTTPURLResponse else {
                self.finish(.failed)
                return
            }
            switch http.statusCode {
            case 200..<300:
                guard let data,
                      let session = try? JSONDecoder().decode(APIEnvelope<RefreshedSession>.self, from: data).data,
                      let access = session.accessToken, !access.isEmpty else {
                    self.finish(.failed)
                    return
                }
                TokenStorage.saveSession(
                    accessToken: access,
                    refreshToken: session.refreshToken ?? refreshToken,
                    expiresAt: session.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? .distantFuture
                )
                self.finish(.refreshed)
            case 400, 401, 403:
                self.finish(.rejected)
            default:
                self.finish(.failed)
            }
        }.resume()
    }

    private func finish(_ outcome: Outcome) {
        lock.lock()
        let callbacks = waiting
        waiting = []
        isRefreshing = false
        lock.unlock()
        callbacks.forEach { $0(outcome) }
    }

    private struct RefreshedSession: Decodable {
        let accessToken: String?
        let refreshToken: String?
        let expiresAt: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
        }
    }
}
