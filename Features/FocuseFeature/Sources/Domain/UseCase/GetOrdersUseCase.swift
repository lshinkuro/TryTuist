//
//  GetOrdersUseCase.swift
//  FocuseFeature · Domain
//
import Foundation

struct GetOrdersUseCase {
    let repository: OrderRepository

    /// Pesanan terbaru di atas.
    func execute() async throws -> [Order] {
        try await repository.fetchOrders().sorted { $0.createdAt > $1.createdAt }
    }
}
