//
//  DefaultOrderRepository.swift
//  FocuseFeature · Data
//
import Foundation

struct DefaultOrderRepository: OrderRepository {
    let remote: OrderRemoteDataSource

    func fetchOrders(_ query: OrderListQuery) async throws -> [Order] {
        do {
            return OrderMapper.orders(from: try await remote.fetchOrders(query))
        } catch {
            throw OrderMapper.toDomainError(error)
        }
    }

    func fetchOrderDetail(id: String) async throws -> OrderDetail {
        let dto: OrderDetailResponseDTO
        do {
            dto = try await remote.fetchOrderDetail(id: id)
        } catch {
            throw OrderMapper.toDomainError(error)
        }
        guard let detail = OrderMapper.detail(from: dto) else { throw OrderError.invalidResponse }
        return detail
    }

    func cancel(orderID: String) async throws -> OrderDetail {
        let dto: OrderDetailResponseDTO
        do {
            dto = try await remote.cancel(orderID: orderID)
        } catch {
            throw OrderMapper.toDomainError(error)
        }
        guard let detail = OrderMapper.detail(from: dto) else { throw OrderError.invalidResponse }
        return detail
    }

    func rate(orderID: String, rating: Int, comment: String) async throws {
        do {
            _ = try await remote.rate(orderID: orderID, rating: rating, comment: comment)
        } catch {
            throw OrderMapper.toDomainError(error)
        }
    }
}
