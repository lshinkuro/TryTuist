//
//  OrderMapper.swift
//  FocuseFeature · Data
//
//  String tanggal → Date, string status → enum, Int harga → Decimal.
//  Order dengan field wajib yang hilang/tidak dikenal dibuang.
//
import Foundation

enum OrderMapper {
    static func orders(from response: OrderListResponseDTO) -> [Order] {
        (response.data ?? []).compactMap { order(from: $0) }
    }

    static func order(from dto: OrderDTO) -> Order? {
        guard let id = dto.orderID,
              let productName = dto.productName,
              let createdAt = dto.createdAt.flatMap({ OrderMapper.parseDate($0) }),
              let totalPrice = dto.totalPrice,
              let status = dto.status.flatMap({ OrderMapper.status(from: $0) }) else {
            return nil
        }
        return Order(
            id: id,
            storeName: dto.storeName ?? "-",
            productName: productName,
            createdAt: createdAt,
            totalPrice: Decimal(totalPrice),
            quantity: max(dto.qty ?? 1, 1),
            status: status
        )
    }

    static func status(from raw: String) -> OrderStatus? {
        switch raw.uppercased() {
        case "PENDING", "PAID", "PROCESSING", "DELIVERING": return .pending
        case "COMPLETED", "DONE": return .completed
        case "FAILED", "CANCELLED": return .failed
        default: return nil
        }
    }

    private static func parseDate(_ raw: String) -> Date? {
        try? Date(raw, strategy: .iso8601)
    }

    static func toDomainError(_ error: Error) -> OrderError {
        switch error {
        case let error as OrderError: return error
        case is URLError: return .network
        case is DecodingError: return .invalidResponse
        default: return .unknown
        }
    }
}
