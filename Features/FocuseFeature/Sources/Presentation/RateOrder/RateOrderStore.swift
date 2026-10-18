//
//  RateOrderStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import Utility

struct RateOrderState: Equatable {
    let order: Order
    /// 0 = belum dipilih.
    var rating = 0
    var comment = ""
    var isSubmitting = false
    var errorMessage: String?
}

enum RateOrderAction {
    case starTapped(Int)
    case commentChanged(String)
    case submitTapped
    case submitResponse(Result<Void, OrderError>)
}

enum RateOrderRoute {
    case submitted(orderID: String)
}

final class RateOrderStore: Store<RateOrderState, RateOrderAction> {
    private let rateOrder: RateOrderUseCase
    var onRoute: ((RateOrderRoute) -> Void)?

    init(order: Order, rateOrder: RateOrderUseCase) {
        self.rateOrder = rateOrder
        super.init(initialState: RateOrderState(order: order))
    }

    override func reduce(state: inout RateOrderState, action: RateOrderAction) -> Effect<RateOrderAction>? {
        switch action {
        case .starTapped(let rating):
            state.rating = rating
            state.errorMessage = nil
            return nil

        case .commentChanged(let comment):
            state.comment = String(comment.prefix(RateOrderUseCase.maxCommentLength))
            return nil

        case .submitTapped:
            guard !state.isSubmitting else { return nil }
            state.isSubmitting = true
            state.errorMessage = nil
            let rateOrder = self.rateOrder
            let (id, rating, comment) = (state.order.id, state.rating, state.comment)
            return .task {
                do {
                    try await rateOrder.execute(orderID: id, rating: rating, comment: comment)
                    return .submitResponse(.success(()))
                } catch {
                    return .submitResponse(.failure(error as? OrderError ?? .unknown))
                }
            }

        case .submitResponse(.success):
            state.isSubmitting = false
            let id = state.order.id
            return .run { [weak self] in self?.onRoute?(.submitted(orderID: id)) }

        case .submitResponse(.failure(let error)):
            state.isSubmitting = false
            state.errorMessage = error.errorDescription
            return nil
        }
    }
}
