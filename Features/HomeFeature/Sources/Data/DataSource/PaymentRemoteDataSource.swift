//
//  PaymentRemoteDataSource.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

protocol PaymentRemoteDataSource {
    func status(id: String) async throws -> PaymentResponseDTO
    func cancel(id: String) async throws -> PaymentResponseDTO
    func pending() async throws -> PaymentListResponseDTO
    /// `status`: transaction_status Midtrans (settlement | deny | expire | cancel).
    func simulate(id: String, status: String) async throws -> PaymentResponseDTO
}

/// Backend asli: `/v1/payments` (§5.27).
struct PaymentAPIDataSource: PaymentRemoteDataSource {
    var api: APIManager = .shared

    func status(id: String) async throws -> PaymentResponseDTO {
        try await api.send(.payment(id: id))
    }

    func cancel(id: String) async throws -> PaymentResponseDTO {
        try await api.send(.cancelPayment(id: id))
    }

    func pending() async throws -> PaymentListResponseDTO {
        try await api.send(.payments(status: "PENDING"))
    }

    func simulate(id: String, status: String) async throws -> PaymentResponseDTO {
        try await api.send(.simulatePayment(id: id, status: status))
    }
}

/// Mock: sesi tersimpan di memori, lunas otomatis `autoPayAfter` detik setelah dibuat.
actor PaymentMockStore {
    static let shared = PaymentMockStore()
    var autoPayAfter: TimeInterval = 4

    private struct Session {
        let id: String
        let amount: Int
        let createdAt: Date
        var status: String
        var orderNumber: String?
    }

    private var sessions: [String: Session] = [:]

    func create(amount: Int) -> [String: Any] {
        let id = UUID().uuidString
        sessions[id] = Session(id: id, amount: amount, createdAt: Date(), status: "PENDING")
        return json(sessions[id]!)
    }

    func status(id: String) -> [String: Any]? {
        guard var s = sessions[id] else { return nil }
        if s.status == "PENDING", Date().timeIntervalSince(s.createdAt) >= autoPayAfter {
            s.status = "PAID"
            s.orderNumber = "ORD-MOCK-\(Int.random(in: 1000...9999))"
            sessions[id] = s
        }
        return json(s)
    }

    func cancel(id: String) -> [String: Any]? {
        guard var s = sessions[id] else { return nil }
        if s.status == "PENDING" { s.status = "CANCELLED" }
        sessions[id] = s
        return json(s)
    }

    func simulate(id: String, status: String) -> [String: Any]? {
        guard var s = sessions[id], s.status == "PENDING" else { return nil }
        switch status {
        case "settlement":
            s.status = "PAID"
            s.orderNumber = "ORD-MOCK-\(Int.random(in: 1000...9999))"
        case "deny": s.status = "FAILED"
        case "expire": s.status = "EXPIRED"
        default: s.status = "CANCELLED"
        }
        sessions[id] = s
        return json(s)
    }

    func pending() -> [[String: Any]] {
        sessions.values.filter { $0.status == "PENDING" }.map(json)
    }

    private func json(_ s: Session) -> [String: Any] {
        let expires = ISO8601DateFormatter().string(from: s.createdAt.addingTimeInterval(15 * 60))
        var out: [String: Any] = [
            "id": s.id, "status": s.status, "amount": s.amount, "expires_at": expires,
            "store": ["id": "ST01", "name": "Gandaria City"]
        ]
        if s.status == "PAID", let number = s.orderNumber {
            out["payment_type"] = "gopay"
            out["order"] = ["id": UUID().uuidString, "order_number": number, "status": "PAID"]
        }
        if s.status == "CANCELLED" { out["status_message"] = "Pembayaran dibatalkan." }
        return out
    }
}

struct PaymentMockDataSource: PaymentRemoteDataSource {
    var latency: Duration = .milliseconds(300)

    func status(id: String) async throws -> PaymentResponseDTO {
        try await Task.sleep(for: latency)
        guard let data = await PaymentMockStore.shared.status(id: id) else { throw PaymentError.notFound }
        return try decode(data)
    }

    func cancel(id: String) async throws -> PaymentResponseDTO {
        try await Task.sleep(for: latency)
        guard let data = await PaymentMockStore.shared.cancel(id: id) else { throw PaymentError.notFound }
        return try decode(data)
    }

    func pending() async throws -> PaymentListResponseDTO {
        try await Task.sleep(for: latency)
        let list = await PaymentMockStore.shared.pending()
        return try decode(list)
    }

    func simulate(id: String, status: String) async throws -> PaymentResponseDTO {
        try await Task.sleep(for: latency)
        guard let data = await PaymentMockStore.shared.simulate(id: id, status: status) else { throw PaymentError.alreadyFinal }
        return try decode(data)
    }

    private func decode<T: Decodable>(_ data: Any) throws -> APIEnvelope<T> {
        let json: [String: Any] = ["code": 200, "message": "success", "data": data]
        return try JSONDecoder().decode(APIEnvelope<T>.self, from: JSONSerialization.data(withJSONObject: json))
    }
}
