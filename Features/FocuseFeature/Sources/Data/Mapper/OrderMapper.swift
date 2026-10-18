//
//  OrderMapper.swift
//  FocuseFeature · Data
//
//  String tanggal → Date, string status → enum, Int harga → Decimal.
//  Order dengan field wajib yang hilang/tidak dikenal dibuang.
//
import Foundation
import NetworkManager

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
            status: status,
            canRate: dto.canRate ?? false
        )
    }

    static func detail(from response: OrderDetailResponseDTO) -> OrderDetail? {
        guard let dto = response.data,
              let id = dto.orderID,
              let rawStatus = dto.status,
              let status = status(from: rawStatus),
              let createdAt = dto.createdAt.flatMap({ parseDate($0) }),
              let total = dto.total else {
            return nil
        }
        let items = (dto.items ?? []).compactMap { item -> OrderDetail.Item? in
            guard let productID = item.productID, let name = item.productName else { return nil }
            return OrderDetail.Item(
                productID: productID,
                optionID: item.optionID?.nonEmpty,
                name: name,
                optionName: item.optionName?.nonEmpty,
                quantity: max(item.quantity ?? 1, 1),
                note: item.note?.nonEmpty,
                subtotal: Decimal(item.subtotal ?? 0)
            )
        }
        let history = (dto.statusHistory ?? []).compactMap { event -> OrderDetail.StatusEvent? in
            guard let raw = event.status, let at = event.at.flatMap({ parseDate($0) }) else { return nil }
            return OrderDetail.StatusEvent(rawStatus: raw.uppercased(), at: at, note: event.note?.nonEmpty)
        }
        let address = dto.address.map { address in
            [address.label, address.recipient, address.address].compactMap { $0?.nonEmpty }.joined(separator: " · ")
        }
        return OrderDetail(
            id: id,
            orderNumber: dto.orderNumber ?? id,
            status: status,
            rawStatus: rawStatus.uppercased(),
            createdAt: createdAt,
            storeName: dto.store?.name ?? "-",
            storeAddress: dto.store?.address?.nonEmpty,
            deliveryAddress: address?.nonEmpty,
            paymentMethod: dto.paymentProvider?.nonEmpty ?? dto.paymentMethod ?? "-",
            items: items,
            subtotal: Decimal(dto.subtotal ?? 0),
            deliveryFee: Decimal(dto.deliveryFee ?? 0),
            discount: Decimal(dto.discount ?? 0),
            total: Decimal(total),
            voucherCode: dto.voucherCode?.nonEmpty,
            history: history.sorted { $0.at < $1.at }
        )
    }

    /// Kebalikan `status(from:)`: tab status → nilai `?status=` backend.
    static func rawStatuses(for status: OrderStatus?) -> [String] {
        switch status {
        case nil: return []
        case .pending: return ["PENDING", "PAID", "PROCESSING", "DELIVERING"]
        case .completed: return ["COMPLETED"]
        case .failed: return ["FAILED", "CANCELLED"]
        }
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
        case let error as APIServerError: return error.message.map(OrderError.rejected) ?? .unknown
        case is URLError: return .network
        case is DecodingError: return .invalidResponse
        default: return .unknown
        }
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
