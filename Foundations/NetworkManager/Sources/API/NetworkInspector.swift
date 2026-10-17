//
//  NetworkInspector.swift
//  NetworkManager
//
//  Merekam setiap request/response API di memori untuk ditampilkan di Debugger (shake).
//  Dipanggil oleh NetworkLogger. Mati otomatis di build Prod.
//
import Combine
import Foundation
import Utility

public struct NetworkEntry: Identifiable, Equatable {
    public enum Phase: Equatable {
        case pending
        case success
        case failure
    }

    public struct Header: Equatable, Hashable {
        public let name: String
        public let value: String
    }

    public let id: String
    public let method: String
    public let url: String
    public let host: String
    public let path: String
    public let query: String?
    public let startedAt: Date
    /// Header & body sudah di-mask (password, token, API key).
    public let requestHeaders: [Header]
    public let requestBody: String?
    /// cURL ASLI (tanpa mask) supaya bisa langsung dijalankan ulang di terminal.
    public let curl: String

    public internal(set) var statusCode: Int?
    public internal(set) var durationMs: Int?
    public internal(set) var responseSize: Int?
    public internal(set) var responseHeaders: [Header] = []
    public internal(set) var responseBody: String?
    public internal(set) var errorMessage: String?

    public var phase: Phase {
        if errorMessage != nil { return .failure }
        guard let statusCode else { return .pending }
        return (200..<300).contains(statusCode) ? .success : .failure
    }
}

@MainActor
public final class NetworkInspector: ObservableObject {
    public static let shared = NetworkInspector()

    /// Terbaru di atas.
    @Published public private(set) var entries: [NetworkEntry] = []
    public var maxEntries = 300

    nonisolated static var isEnabled: Bool { AppEnvironment.isDebugToolsEnabled }
    /// Body yang disimpan boleh lebih panjang dari log console.
    nonisolated static let maxBodyLength = 60_000

    private init() {}

    public func clear() {
        entries.removeAll()
    }

    public func remove(id: String) {
        entries.removeAll { $0.id == id }
    }

    // MARK: - Dipanggil NetworkLogger (thread mana pun)

    nonisolated static func didStart(id: String, request: URLRequest) {
        guard isEnabled else { return }
        let url = request.url
        let entry = NetworkEntry(
            id: id,
            method: request.httpMethod ?? "GET",
            url: url?.absoluteString ?? "-",
            host: url.flatMap({ host(of: $0) }) ?? "-",
            path: url?.path ?? "-",
            query: url?.query,
            startedAt: Date(),
            requestHeaders: (request.allHTTPHeaderFields ?? [:])
                .sorted { $0.key < $1.key }
                .map { NetworkEntry.Header(name: $0.key, value: NetworkLogger.maskHeader($0.key, $0.value)) },
            requestBody: request.httpBody.flatMap({ $0.isEmpty ? nil : NetworkLogger.prettyJSON($0, limit: maxBodyLength) }),
            curl: curlCommand(for: request)
        )
        DispatchQueue.main.async {
            MainActor.assumeIsolated { shared.insert(entry) }
        }
    }

    nonisolated static func didFinish(id: String, response: URLResponse?, data: Data?, error: Error?, startedAt: Date) {
        guard isEnabled else { return }
        let duration = Int(Date().timeIntervalSince(startedAt) * 1000)
        let http = response as? HTTPURLResponse
        let headers = (http?.allHeaderFields ?? [:])
            .map { NetworkEntry.Header(name: "\($0.key)", value: "\($0.value)") }
            .sorted { $0.name < $1.name }
        let body = data.flatMap({ $0.isEmpty ? nil : NetworkLogger.prettyJSON($0, limit: maxBodyLength) })
        let errorMessage = error.map { NetworkLogger.describe($0) }

        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                shared.update(id) { entry in
                    entry.statusCode = http?.statusCode
                    entry.durationMs = duration
                    entry.responseSize = data?.count
                    entry.responseHeaders = headers
                    entry.responseBody = body
                    entry.errorMessage = errorMessage
                }
            }
        }
    }

    nonisolated static func didFailDecoding(id: String, typeName: String, message: String) {
        guard isEnabled else { return }
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                shared.update(id) { $0.errorMessage = "Gagal decode ke \(typeName): \(message)" }
            }
        }
    }

    // MARK: - Private

    private func insert(_ entry: NetworkEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    private func update(_ id: String, _ change: (inout NetworkEntry) -> Void) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        change(&entries[index])
    }

    nonisolated private static func host(of url: URL) -> String? {
        guard let host = url.host else { return nil }
        return url.port.map { "\(host):\($0)" } ?? host
    }

    nonisolated private static func curlCommand(for request: URLRequest) -> String {
        var parts = ["curl -i -X \(request.httpMethod ?? "GET")"]
        for (key, value) in (request.allHTTPHeaderFields ?? [:]).sorted(by: { $0.key < $1.key }) {
            parts.append("-H '\(key): \(value.replacingOccurrences(of: "'", with: "'\\''"))'")
        }
        if let body = request.httpBody, !body.isEmpty {
            let text = String(decoding: body, as: UTF8.self).replacingOccurrences(of: "'", with: "'\\''")
            parts.append("-d '\(text)'")
        }
        parts.append("'\(request.url?.absoluteString ?? "")'")
        return parts.joined(separator: " \\\n  ")
    }
}
