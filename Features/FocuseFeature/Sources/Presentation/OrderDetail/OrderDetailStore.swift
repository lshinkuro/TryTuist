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
    case rateTapped
    /// Rating terkirim → muat ulang supaya nilai tampil.
    case ratingSubmitted
}

enum OrderDetailRoute {
    case rate(RatingTarget)
}

final class OrderDetailStore: Store<OrderDetailState, OrderDetailAction> {
    private let getDetail: GetOrderDetailUseCase
    var onRoute: ((OrderDetailRoute) -> Void)?

    init(orderID: String, getDetail: GetOrderDetailUseCase) {
        self.getDetail = getDetail
        super.init(initialState: OrderDetailState(orderID: orderID))
    }

    override func reduce(state: inout OrderDetailState, action: OrderDetailAction) -> Effect<OrderDetailAction>? {
        switch action {
        case .onAppear:
            guard state.detail.isIdle else { return nil }
            return load(&state)

        case .retryTapped, .ratingSubmitted:
            return load(&state)

        case .rateTapped:
            guard let detail = state.detail.value else { return nil }
            let target = RatingTarget(orderID: detail.id, title: detail.orderNumber, createdAt: detail.createdAt)
            return .run { [weak self] in self?.onRoute?(.rate(target)) }

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
