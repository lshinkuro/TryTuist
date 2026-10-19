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
    /// `POST /v1/orders/quote`. `localSubtotal` hanya dipakai mock.
    func quote(_ request: CreateOrderParam, localSubtotal: Int) async throws -> QuoteResponseDTO
}

/// Backend asli (butuh login). Harga dihitung ulang di server.
/// Pakai `send` supaya tipe & pesan error server (mis. metode bayar tidak tersedia) ikut terbawa.
struct CheckoutAPIDataSource: CheckoutRemoteDataSource {
    var api: APIManager = .shared

    func checkout(_ request: CreateOrderParam, idempotencyKey: String, expectedTotal: Int) async throws -> CheckoutResponseDTO {
        try await api.send(.checkout(param: request, idempotencyKey: idempotencyKey))
    }

    func quote(_ request: CreateOrderParam, localSubtotal: Int) async throws -> QuoteResponseDTO {
        try await api.send(.quote(param: request))
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

    /// Meniru aturan server dengan alamat ±2,4 km dari outlet: tarif dasar Rp 10.000.
    func quote(_ request: CreateOrderParam, localSubtotal: Int) async throws -> QuoteResponseDTO {
        try await Task.sleep(for: .milliseconds(300))
        let baseFee = 10000
        let fee = request.useFreeDelivery ? 0 : baseFee
        let hasAddress = request.addressID != nil
        var data: [String: Any] = ["subtotal": localSubtotal, "delivery_fee": fee, "discount": 0, "total": localSubtotal + fee]
        data["free_delivery"] = ["enabled": true, "weekly_quota": 2, "used": 0, "remaining": request.useFreeDelivery ? 1 : 2,
                                 "applied": request.useFreeDelivery, "fee_waived": request.useFreeDelivery ? baseFee : 0]
        if hasAddress {
            data["distance_km"] = 2.4
            data["eta_min_minutes"] = 25
            data["eta_max_minutes"] = 35
        }
        let json: [String: Any] = ["code": 200, "message": "success", "data": data]
        return try JSONDecoder().decode(QuoteResponseDTO.self, from: JSONSerialization.data(withJSONObject: json))
    }
}
