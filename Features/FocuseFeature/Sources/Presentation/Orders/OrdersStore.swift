//
//  OrdersStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import Utility

struct OrdersState: Equatable {
    /// nil = "Semua"
    var filter: OrderStatus?
    var orders: Loadable<[Order]> = .idle

    var displayedOrders: [Order] {
        let all = orders.value ?? []
        guard let filter else { return all }
        return all.filter { $0.status == filter }
    }
}

enum OrdersAction {
    case onAppear
    case retryTapped
    case filterChanged(OrderStatus?)
    case ordersResponse(Result<[Order], OrderError>)
}

final class OrdersStore: Store<OrdersState, OrdersAction> {
    private let getOrders: GetOrdersUseCase

    init(getOrders: GetOrdersUseCase) {
        self.getOrders = getOrders
        super.init(initialState: OrdersState())
    }

    override func reduce(state: inout OrdersState, action: OrdersAction) -> Effect<OrdersAction>? {
        switch action {
        case .onAppear:
            guard state.orders.isIdle else { return nil }
            return load(&state)

        case .retryTapped:
            return load(&state)

        case .filterChanged(let filter):
            state.filter = filter
            return nil

        case .ordersResponse(.success(let orders)):
            state.orders = .loaded(orders)
            return nil

        case .ordersResponse(.failure(let error)):
            state.orders = .failed(error.errorDescription ?? "")
            return nil
        }
    }

    private func load(_ state: inout OrdersState) -> Effect<OrdersAction> {
        state.orders = .loading
        let getOrders = self.getOrders
        return .task {
            do {
                return .ordersResponse(.success(try await getOrders.execute()))
            } catch {
                return .ordersResponse(.failure(error as? OrderError ?? .unknown))
            }
        }
    }
}
