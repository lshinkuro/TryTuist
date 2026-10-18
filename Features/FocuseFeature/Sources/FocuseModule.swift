//
//  FocuseModule.swift
//  FocuseFeature
//
//  Composition root + routing tab Pesanan.
//
import SwiftUI
import Navigation
import Utility

@MainActor
public final class FocusModule: TabFeature {
    public let tabItem = TabItem(title: String(localized: "Pesanan"), systemImage: "clock.arrow.circlepath", selectedSystemImage: "clock.arrow.circlepath")
    private let onReorder: ([OrderReorderItem]) -> Void

    /// - Parameter onReorder: "Pesan Lagi" → AppRouter memasukkan item ke keranjang Beranda.
    public init(onReorder: @escaping ([OrderReorderItem]) -> Void = { _ in }) {
        self.onReorder = onReorder
    }

    public func start(router: Router) {
        let repository = DefaultOrderRepository(remote: Self.makeRemoteDataSource())
        let getDetail = GetOrderDetailUseCase(repository: repository)
        let store = OrdersStore(getOrders: GetOrdersUseCase(repository: repository), getDetail: getDetail)
        let onReorder = self.onReorder
        let rateOrder = RateOrderUseCase(repository: repository)
        let presentRating = { [weak router] (target: RatingTarget, onSubmitted: @escaping (String, Int) -> Void) in
            let rateStore = RateOrderStore(target: target, rateOrder: rateOrder)
            rateStore.onRoute = { route in
                switch route {
                case .submitted(let orderID, let rating):
                    router?.dismiss()
                    onSubmitted(orderID, rating)
                }
            }
            router?.present(RateOrderView(store: rateStore), title: String(localized: "Beri Nilai"))
        }
        store.onRoute = { [weak router, weak store] route in
            switch route {
            case .detail(let id):
                let detailStore = OrderDetailStore(orderID: id, getDetail: getDetail)
                detailStore.onRoute = { [weak detailStore] route in
                    switch route {
                    case .rate(let target):
                        presentRating(target) { orderID, rating in
                            detailStore?.send(.ratingSubmitted)
                            store?.send(.ratingSubmitted(orderID: orderID, rating: rating))
                        }
                    }
                }
                router?.push(OrderDetailView(store: detailStore), title: String(localized: "Detail Pesanan"))
            case .rate(let target):
                presentRating(target) { orderID, rating in
                    store?.send(.ratingSubmitted(orderID: orderID, rating: rating))
                }
            case .reorder(let items):
                onReorder(items.map {
                    OrderReorderItem(productID: $0.productID, optionID: $0.optionID, name: $0.name,
                                     quantity: $0.quantity, note: $0.note ?? "")
                })
            }
        }
        router.setRoot(FocusesView(store: store), hidesNavigationBar: true)
    }

    private static func makeRemoteDataSource() -> OrderRemoteDataSource {
        if AppConfig.useMockData { return OrderMockDataSource() }
        return OrderAPIDataSource()
    }
}

/// Satu item pesanan untuk "Pesan Lagi". AppRouter meneruskannya ke feature katalog.
public struct OrderReorderItem {
    public let productID: String
    public let optionID: String?
    public let name: String
    public let quantity: Int
    public let note: String
}
