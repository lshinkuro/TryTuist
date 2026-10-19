//
//  GetOrdersUseCase.swift
//  FocuseFeature · Domain
//
import Foundation

struct GetOrdersUseCase {
    let repository: OrderRepository

    /// Urutan & filter sudah dikerjakan server sesuai `query`.
    func execute(_ query: OrderListQuery) async throws -> [Order] {
        try await repository.fetchOrders(query)
    }
}

struct GetOrderDetailUseCase {
    let repository: OrderRepository

    func execute(id: String) async throws -> OrderDetail {
        try await repository.fetchOrderDetail(id: id)
    }
}

struct CancelOrderUseCase {
    let repository: OrderRepository

    func execute(id: String) async throws -> OrderDetail {
        try await repository.cancel(orderID: id)
    }
}

struct RateOrderUseCase {
    let repository: OrderRepository
    static let ratingRange = 1...5
    static let maxCommentLength = 500

    func execute(orderID: String, rating: Int, comment: String) async throws {
        guard Self.ratingRange.contains(rating) else { throw OrderError.invalidRating }
        let comment = String(comment.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxCommentLength))
        try await repository.rate(orderID: orderID, rating: rating, comment: comment)
    }
}
