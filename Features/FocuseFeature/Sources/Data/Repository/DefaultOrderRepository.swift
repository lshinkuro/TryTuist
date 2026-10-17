//
//  DefaultOrderRepository.swift
//  FocuseFeature · Data
//
import Foundation

struct DefaultOrderRepository: OrderRepository {
    let remote: OrderRemoteDataSource

    func fetchOrders() async throws -> [Order] {
        do {
            return OrderMapper.orders(from: try await remote.fetchOrders())
        } catch {
            throw OrderMapper.toDomainError(error)
        }
    }
}
