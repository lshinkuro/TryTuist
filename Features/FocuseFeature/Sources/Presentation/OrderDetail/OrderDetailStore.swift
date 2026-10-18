//
//  OrderDetailStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import Utility

struct OrderDetailState: Equatable {
    let orderID: String
    var detail: Loadable<OrderDetail> = .idle
}

enum OrderDetailAction {
    case onAppear
    case retryTapped
    case detailResponse(Result<OrderDetail, OrderError>)
}

final class OrderDetailStore: Store<OrderDetailState, OrderDetailAction> {
    private let getDetail: GetOrderDetailUseCase

    init(orderID: String, getDetail: GetOrderDetailUseCase) {
        self.getDetail = getDetail
        super.init(initialState: OrderDetailState(orderID: orderID))
    }

    override func reduce(state: inout OrderDetailState, action: OrderDetailAction) -> Effect<OrderDetailAction>? {
        switch action {
        case .onAppear:
            guard state.detail.isIdle else { return nil }
            return load(&state)

        case .retryTapped:
            return load(&state)

        case .detailResponse(.success(let detail)):
            state.detail = .loaded(detail)
            return nil

        case .detailResponse(.failure(let error)):
            state.detail = .failed(error.errorDescription ?? "")
            return nil
        }
    }

    private func load(_ state: inout OrderDetailState) -> Effect<OrderDetailAction> {
        state.detail = .loading
        let getDetail = self.getDetail
        let id = state.orderID
        return .task {
            do {
                return .detailResponse(.success(try await getDetail.execute(id: id)))
            } catch {
                return .detailResponse(.failure(error as? OrderError ?? .unknown))
            }
        }
    }
}
