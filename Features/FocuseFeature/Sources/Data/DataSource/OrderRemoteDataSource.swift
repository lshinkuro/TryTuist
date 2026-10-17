//
//  OrderRemoteDataSource.swift
//  FocuseFeature · Data
//
import Foundation
import NetworkManager

protocol OrderRemoteDataSource {
    func fetchOrders() async throws -> OrderListResponseDTO
}

/// Backend asli (Go). Kontrak: API_PLAN.md → `GET /v1/orders`.
struct OrderAPIDataSource: OrderRemoteDataSource {
    var api: APIManager = .shared

    func fetchOrders() async throws -> OrderListResponseDTO {
        try await api.request(.orders)
    }
}

/// Mock: JSON fixture dengan bentuk yang sama seperti backend.
struct OrderMockDataSource: OrderRemoteDataSource {
    var latency: Duration = .milliseconds(500)

    func fetchOrders() async throws -> OrderListResponseDTO {
        try await Task.sleep(for: latency)
        return try JSONDecoder().decode(OrderListResponseDTO.self, from: Data(Self.ordersJSON.utf8))
    }

    /// Item terakhir punya status yang tidak dikenal → dibuang oleh Mapper.
    private static let ordersJSON = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "order_id": "ORD-001", "store_name": "Gandaria City", "product_name": "TOMORO Oat Latte",
          "created_at": "2024-08-20T12:46:00+07:00", "total_price": 15000, "qty": 1, "status": "PENDING" },
        { "order_id": "ORD-002", "store_name": "Gandaria City", "product_name": "Choco Oat Latte",
          "created_at": "2024-08-20T12:44:00+07:00", "total_price": 15000, "qty": 1, "status": "COMPLETED" },
        { "order_id": "ORD-003", "store_name": "Gandaria City", "product_name": "Breve Latte",
          "created_at": "2024-08-07T12:21:00+07:00", "total_price": 9000, "qty": 1, "status": "COMPLETED" },
        { "order_id": "ORD-004", "store_name": "Kemang Utara", "product_name": "TOMORO Oat Latte",
          "created_at": "2024-08-05T09:10:00+07:00", "total_price": 30000, "qty": 2, "status": "FAILED" },
        { "order_id": "ORD-005", "store_name": "Kemang Utara", "product_name": "Americano",
          "created_at": "2024-08-01T08:00:00+07:00", "total_price": 18000, "qty": 1, "status": "REFUNDED_V2" }
      ]
    }
    """
}
