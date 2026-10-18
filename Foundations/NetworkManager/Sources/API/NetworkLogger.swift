//
//  NetworkLogger.swift
//  NetworkManager
//
//  Log setiap request/response API ke console Xcode.
//  Aktif di Dev & Staging, mati otomatis di Prod.
//  Setiap request juga diteruskan ke `NetworkInspector` (tab API di Debugger).
//  Pakai `print` supaya tetap tampil walau OS_ACTIVITY_MODE=disable.
//
//  Contoh output:
//  ┌──── 🚀 [A1B2] POST http://localhost:8080/v1/auth/login
//  │ Headers: X-API-Key: dev-l…, Content-Type: application/json
//  │ Body: { "email": "kholis@gmail.com", "password": "••••••" }
//  └────
//  ┌──── ✅ [A1B2] 200 POST /v1/auth/login · 42 ms · 512 B
//  │ { "code": 200, ... }
//  └────
//
import Foundation
import Utility

public enum NetworkLogger {
    /// Matikan manual bila terlalu ramai, mis. `NetworkLogger.isEnabled = false` di AppDelegate.
    nonisolated(unsafe) public static var isEnabled = !AppEnvironment.build.isProduction
    /// Batas panjang body yang dicetak (karakter).
    nonisolated(unsafe) public static var maxBodyLength = 4_000

    private static let sensitiveHeaders: Set<String> = ["authorization", "x-api-key", "cookie"]
    private static let sensitiveBodyKeys: Set<String> = ["password", "access_token", "refresh_token", "id_token"]

    // MARK: - Request

    @discardableResult
    static func logRequest(_ request: URLRequest) -> String {
        let id = String(UUID().uuidString.prefix(6))
        NetworkInspector.didStart(id: id, request: request)
        guard isEnabled else { return id }

        var lines = ["🚀 [\(id)] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "-")"]
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let text = headers
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \(maskHeader($0.key, $0.value))" }
                .joined(separator: ", ")
            lines.append("Headers: \(text)")
        }
        if let body = request.httpBody, !body.isEmpty {
            lines.append("Body: \(prettyJSON(body, maskSecrets: true))")
        }
        printBox(lines)
        return id
    }

    // MARK: - Response

    static func logResponse(id: String, request: URLRequest, response: URLResponse?,
                            data: Data?, error: Error?, startedAt: Date) {
        NetworkInspector.didFinish(id: id, response: response, data: data, error: error, startedAt: startedAt)
        guard isEnabled else { return }
        let ms = Int(Date().timeIntervalSince(startedAt) * 1000)
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? "-"

        if let error {
            printBox([
                "❌ [\(id)] \(method) \(path) · \(ms) ms",
                "Error: \(describe(error))"
            ])
            return
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let icon: String
        switch status {
        case 200..<300: icon = "✅"
        case 400..<500: icon = "⚠️"
        default: icon = "❌"
        }
        let size = ByteCountFormatter.string(fromByteCount: Int64(data?.count ?? 0), countStyle: .binary)
        var lines = ["\(icon) [\(id)] \(status) \(method) \(path) · \(ms) ms · \(size)"]
        if let data, !data.isEmpty {
            lines.append(prettyJSON(data, maskSecrets: true))
        }
        printBox(lines)
    }

    // MARK: - Error lain

    static func logDecodingFailure<T>(id: String, type: T.Type, error: Error) {
        NetworkInspector.didFailDecoding(id: id, typeName: "\(T.self)", message: describe(error))
        guard isEnabled else { return }
        printBox([
            "🧩 [\(id)] Gagal decode ke \(T.self)",
            describe(error)
        ])
    }

    static func logBuildFailure(endpoint: String, error: Error) {
        guard isEnabled else { return }
        printBox(["❌ Gagal membuat request \(endpoint): \(error)"])
    }

    // MARK: - Helpers

    private static func printBox(_ lines: [String]) {
        var output = "┌──── " + (lines.first ?? "")
        for line in lines.dropFirst() {
            for sub in line.split(separator: "\n", omittingEmptySubsequences: false) {
                output += "\n│ " + sub
            }
        }
        output += "\n└────"
        print(output)
    }

    static func maskHeader(_ key: String, _ value: String) -> String {
        guard sensitiveHeaders.contains(key.lowercased()) else { return value }
        return value.count > 12 ? String(value.prefix(12)) + "…" : "••••"
    }

    private static func prettyJSON(_ data: Data, maskSecrets: Bool) -> String {
        prettyJSON(data, limit: maxBodyLength, maskSecrets: maskSecrets)
    }

    /// JSON rapi + secret di-mask. Dipakai juga oleh NetworkInspector.
    static func prettyJSON(_ data: Data, limit: Int, maskSecrets: Bool = true) -> String {
        guard var object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return truncate(String(decoding: data, as: UTF8.self), limit: limit)
        }
        if maskSecrets { object = mask(object) }
        guard let pretty = try? JSONSerialization.data(withJSONObject: object,
                                                       options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]) else {
            return truncate(String(decoding: data, as: UTF8.self), limit: limit)
        }
        return truncate(String(decoding: pretty, as: UTF8.self), limit: limit)
    }

    private static func mask(_ object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                if sensitiveBodyKeys.contains(key.lowercased()), let text = value as? String {
                    result[key] = text.count > 10 ? String(text.prefix(10)) + "…" : "••••••"
                } else {
                    result[key] = mask(value)
                }
            }
            return result
        }
        if let array = object as? [Any] {
            return array.map { mask($0) }
        }
        return object
    }

    private static func truncate(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit)) + "\n… (dipotong, total \(text.count) karakter)"
    }

    static func describe(_ error: Error) -> String {
        switch error {
        case DecodingError.keyNotFound(let key, let context):
            return "Field '\(key.stringValue)' tidak ada · path: \(codingPath(context))"
        case DecodingError.typeMismatch(let type, let context):
            return "Tipe tidak cocok (\(type)) · path: \(codingPath(context)) · \(context.debugDescription)"
        case DecodingError.valueNotFound(let type, let context):
            return "Nilai \(type) kosong · path: \(codingPath(context))"
        case DecodingError.dataCorrupted(let context):
            return "Data rusak · path: \(codingPath(context)) · \(context.debugDescription)"
        case let urlError as URLError:
            return "URLError \(urlError.code.rawValue): \(urlError.localizedDescription)"
        default:
            return "\(error)"
        }
    }

    private static func codingPath(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? $0.stringValue }.joined(separator: ".")
        return path.isEmpty ? "(root)" : path
    }
}
