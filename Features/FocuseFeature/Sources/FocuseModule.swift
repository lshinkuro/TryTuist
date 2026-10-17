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
    public let tabItem = TabItem(title: "Pesanan", systemImage: "clock.arrow.circlepath", selectedSystemImage: "clock.arrow.circlepath")

    public init() {}

    public func start(router: Router) {
        let repository = DefaultOrderRepository(remote: Self.makeRemoteDataSource())
        let store = OrdersStore(getOrders: GetOrdersUseCase(repository: repository))
        router.setRoot(FocusesView(store: store), hidesNavigationBar: true)
    }

    private static func makeRemoteDataSource() -> OrderRemoteDataSource {
        if AppConfig.useMockData { return OrderMockDataSource() }
        return OrderAPIDataSource()
    }
}
