//
//  OrderRemoteDataSource.swift
//  FocuseFeature · Data
//
import Foundation
import NetworkManager

protocol OrderRemoteDataSource {
    func fetchOrders(_ query: OrderListQuery) async throws -> OrderListResponseDTO
    func fetchOrderDetail(id: String) async throws -> OrderDetailResponseDTO
    func rate(orderID: String, rating: Int, comment: String) async throws -> OrderDetailResponseDTO
    func cancel(orderID: String) async throws -> OrderDetailResponseDTO
}

/// Backend asli (Go). Kontrak: API_PLAN.md → `GET /v1/orders`.
struct OrderAPIDataSource: OrderRemoteDataSource {
    var api: APIManager = .shared

    func fetchOrders(_ query: OrderListQuery) async throws -> OrderListResponseDTO {
        try await api.request(.orders(statuses: OrderMapper.rawStatuses(for: query.status),
                                      from: query.from, to: query.to, oldestFirst: !query.newestFirst,
                                      page: query.page, limit: OrderListQuery.pageSize))
    }

    func fetchOrderDetail(id: String) async throws -> OrderDetailResponseDTO {
        try await api.request(.orderDetail(id: id))
    }

    /// `send`: 409 ALREADY_RATED / 422 ORDER_NOT_RATABLE membawa pesan dari server.
    func rate(orderID: String, rating: Int, comment: String) async throws -> OrderDetailResponseDTO {
        try await api.send(.rateOrder(id: orderID, rating: rating, comment: comment))
    }

    /// `send`: 422 ORDER_NOT_CANCELLABLE (mis. sudah diproses outlet) membawa pesan dari server.
    func cancel(orderID: String) async throws -> OrderDetailResponseDTO {
        try await api.send(.cancelOrder(id: orderID))
    }
}

/// Mock: JSON fixture dengan bentuk yang sama seperti backend.
struct OrderMockDataSource: OrderRemoteDataSource {
    var latency: Duration = .milliseconds(500)

    /// Meniru filter, urutan & paginasi server di atas fixture.
    func fetchOrders(_ query: OrderListQuery) async throws -> OrderListResponseDTO {
        try await Task.sleep(for: latency)
        let all = try JSONDecoder().decode(OrderListResponseDTO.self, from: Data(Self.ordersJSON.utf8))
        let statuses = OrderMapper.rawStatuses(for: query.status)
        let date = { (dto: OrderDTO) in dto.createdAt.flatMap { try? Date($0, strategy: .iso8601) } ?? .distantPast }
        let matching = (all.data ?? [])
            .filter { statuses.isEmpty || statuses.contains($0.status ?? "") }
            .filter { dto in query.from.map { date(dto) >= $0 } ?? true }
            .filter { dto in query.to.map { date(dto) < $0 } ?? true }
            .sorted { query.newestFirst ? date($0) > date($1) : date($0) < date($1) }
        let page = Array(matching.dropFirst((query.page - 1) * OrderListQuery.pageSize).prefix(OrderListQuery.pageSize))
        return OrderListResponseDTO(code: 200, message: "success", data: page)
    }

    func rate(orderID: String, rating: Int, comment: String) async throws -> OrderDetailResponseDTO {
        try await fetchOrderDetail(id: orderID)
    }

    func cancel(orderID: String) async throws -> OrderDetailResponseDTO {
        try await Task.sleep(for: latency)
        let json = Self.detailJSON.replacingOccurrences(of: "{{ID}}", with: orderID)
            .replacingOccurrences(of: "\"status\": \"PROCESSING\"", with: "\"status\": \"CANCELLED\", \"can_cancel\": false")
        return try JSONDecoder().decode(OrderDetailResponseDTO.self, from: Data(json.utf8))
    }

    /// Isi detail sama untuk semua id; cukup untuk mencoba layar Detail tanpa backend.
    func fetchOrderDetail(id: String) async throws -> OrderDetailResponseDTO {
        try await Task.sleep(for: latency)
        let json = Self.detailJSON.replacingOccurrences(of: "{{ID}}", with: id)
        return try JSONDecoder().decode(OrderDetailResponseDTO.self, from: Data(json.utf8))
    }

    private static let detailJSON = """
    {
      "code": 200,
      "message": "success",
      "data": {
        "order_id": "{{ID}}", "order_number": "{{ID}}", "status": "PROCESSING",
        "created_at": "2024-08-20T12:46:00+07:00",
        "subtotal": 40000, "delivery_fee": 10000, "discount": 4000, "total": 46000,
        "distance_km": 2.4, "eta_min_minutes": 25, "eta_max_minutes": 35,
        "payment_method": "COD", "payment_provider": null, "voucher_code": "HEMAT10",
        "items": [
          { "product_id": "P01", "option_id": "large", "product_name": "TOMORO Oat Latte", "option_name": "Large", "quantity": 2, "note": "less sugar", "subtotal": 30000 },
          { "product_id": "P11", "option_id": null, "product_name": "Croissant", "option_name": null, "quantity": 1, "note": "", "subtotal": 10000 }
        ],
        "store": { "id": "ST01", "name": "Gandaria City", "address": "Jl. Sultan Iskandar Muda" },
        "address": { "label": "Rumah", "recipient": "Kholis", "address": "Jl. Kebayoran Lama No. 1" },
        "status_history": [
          { "status": "PENDING", "at": "2024-08-20T12:46:00+07:00" },
          { "status": "PROCESSING", "at": "2024-08-20T12:50:00+07:00" }
        ]
      }
    }
    """

    /// Item terakhir punya status yang tidak dikenal → dibuang oleh Mapper.
    private static let ordersJSON = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "order_id": "ORD-001", "store_name": "Gandaria City", "product_name": "TOMORO Oat Latte",
          "created_at": "2024-08-20T12:46:00+07:00", "total_price": 15000, "qty": 1, "status": "PENDING" },
        { "order_id": "ORD-002", "store_name": "Gandaria City", "product_name": "Choco Oat Latte",
          "created_at": "2024-08-20T12:44:00+07:00", "total_price": 15000, "qty": 1, "status": "COMPLETED", "can_rate": true },
        { "order_id": "ORD-003", "store_name": "Gandaria City", "product_name": "Breve Latte",
          "created_at": "2024-08-07T12:21:00+07:00", "total_price": 9000, "qty": 1, "status": "COMPLETED", "rating": 5 },
        { "order_id": "ORD-004", "store_name": "Kemang Utara", "product_name": "TOMORO Oat Latte",
          "created_at": "2024-08-05T09:10:00+07:00", "total_price": 30000, "qty": 2, "status": "FAILED" },
        { "order_id": "ORD-005", "store_name": "Kemang Utara", "product_name": "Americano",
          "created_at": "2024-08-01T08:00:00+07:00", "total_price": 18000, "qty": 1, "status": "REFUNDED_V2" }
      ]
    }
    """
}
