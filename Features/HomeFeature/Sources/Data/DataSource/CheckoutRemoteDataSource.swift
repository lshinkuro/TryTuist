//
//  CheckoutRemoteDataSource.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

protocol CheckoutRemoteDataSource {
    func createOrder(_ request: CreateOrderParam, idempotencyKey: String) async throws -> PlacedOrderResponseDTO
}

/// Backend asli: `POST /v1/orders` (butuh login). Harga dihitung ulang di server.
/// Pakai `send` supaya tipe & pesan error server (mis. metode bayar tidak tersedia) ikut terbawa.
struct CheckoutAPIDataSource: CheckoutRemoteDataSource {
    var api: APIManager = .shared

    func createOrder(_ request: CreateOrderParam, idempotencyKey: String) async throws -> PlacedOrderResponseDTO {
        try await api.send(.createOrder(param: request, idempotencyKey: idempotencyKey))
    }
}

/// Mock: meniru response server tanpa network.
struct CheckoutMockDataSource: CheckoutRemoteDataSource {
    var latency: Duration = .seconds(1)

    func createOrder(_ request: CreateOrderParam, idempotencyKey: String) async throws -> PlacedOrderResponseDTO {
        try await Task.sleep(for: latency)
        let json: [String: Any] = [
            "code": 201,
            "message": "Pesanan diterima",
            "data": [
                "order_id": UUID().uuidString,
                "order_number": "ORD-MOCK-\(Int.random(in: 1000...9999))",
                "status": "PENDING"
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(PlacedOrderResponseDTO.self, from: data)
    }
}
