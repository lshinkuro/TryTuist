//
//  CheckoutRemoteDataSource.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

protocol CheckoutRemoteDataSource {
    /// `POST /v1/checkout`: COD → pesanan; Bayar Online → sesi Midtrans (§5.27).
    /// `expectedTotal` hanya dipakai mock (server selalu menghitung ulang).
    func checkout(_ request: CreateOrderParam, idempotencyKey: String, expectedTotal: Int) async throws -> CheckoutResponseDTO
}

/// Backend asli (butuh login). Harga dihitung ulang di server.
/// Pakai `send` supaya tipe & pesan error server (mis. metode bayar tidak tersedia) ikut terbawa.
struct CheckoutAPIDataSource: CheckoutRemoteDataSource {
    var api: APIManager = .shared

    func checkout(_ request: CreateOrderParam, idempotencyKey: String, expectedTotal: Int) async throws -> CheckoutResponseDTO {
        try await api.send(.checkout(param: request, idempotencyKey: idempotencyKey))
    }
}

/// Mock: meniru response server tanpa network. Bayar Online → sesi di `PaymentMockStore`
/// yang otomatis lunas beberapa detik kemudian.
struct CheckoutMockDataSource: CheckoutRemoteDataSource {
    var latency: Duration = .seconds(1)

    func checkout(_ request: CreateOrderParam, idempotencyKey: String, expectedTotal: Int) async throws -> CheckoutResponseDTO {
        try await Task.sleep(for: latency)
        let data: [String: Any]
        if request.paymentMethodID == "ONLINE" {
            let payment = await PaymentMockStore.shared.create(amount: expectedTotal)
            data = ["next": "PAYMENT", "payment": payment]
        } else {
            data = ["next": "ORDER", "order": [
                "order_id": UUID().uuidString,
                "order_number": "ORD-MOCK-\(Int.random(in: 1000...9999))",
                "status": "PENDING"
            ]]
        }
        let json: [String: Any] = ["code": 201, "message": "Pesanan diterima", "data": data]
        return try JSONDecoder().decode(CheckoutResponseDTO.self, from: JSONSerialization.data(withJSONObject: json))
    }
}
