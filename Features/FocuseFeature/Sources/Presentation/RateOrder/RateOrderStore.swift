//
//  RateOrderStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import Utility

/// Pesanan yang dinilai; dibuka dari list maupun Detail.
struct RatingTarget: Equatable {
    let orderID: String
    let title: String
    let createdAt: Date
}

struct RateOrderState: Equatable {
    let target: RatingTarget
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
    case submitted(orderID: String, rating: Int)
}

final class RateOrderStore: Store<RateOrderState, RateOrderAction> {
    private let rateOrder: RateOrderUseCase
    var onRoute: ((RateOrderRoute) -> Void)?

    init(target: RatingTarget, rateOrder: RateOrderUseCase) {
        self.rateOrder = rateOrder
        super.init(initialState: RateOrderState(target: target))
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
            let (id, rating, comment) = (state.target.orderID, state.rating, state.comment)
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
            let (id, rating) = (state.target.orderID, state.rating)
            return .run { [weak self] in self?.onRoute?(.submitted(orderID: id, rating: rating)) }

        case .submitResponse(.failure(let error)):
            state.isSubmitting = false
            state.errorMessage = error.errorDescription
            return nil
        }
    }
}
