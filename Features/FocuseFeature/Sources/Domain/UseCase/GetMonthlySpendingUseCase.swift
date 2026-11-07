//
//  GetMonthlySpendingUseCase.swift
//  FocuseFeature · Domain
//
import Foundation

struct GetMonthlySpendingUseCase {
    // shortcut: maks 5 halaman (100 pesanan) per bulan; kalau user bisa lebih dari itu, minta endpoint ringkasan ke backend.
    static let maxPages = 5
    let repository: OrderRepository

    func execute(now: Date = Date(), calendar: Calendar = .current) async throws -> MonthlySpending {
        let start = calendar.dateInterval(of: .month, for: now)?.start ?? calendar.startOfDay(for: now)
        var orders: [Order] = []
        for page in 1...Self.maxPages {
            let batch = try await repository.fetchOrders(OrderListQuery(from: start, page: page))
            orders += batch
            if batch.count < OrderListQuery.pageSize { break }
        }
        return Self.summarize(orders, month: start)
    }

    /// Pesanan gagal/batal tidak dihitung.
    static func summarize(_ orders: [Order], month: Date) -> MonthlySpending {
        let counted = orders.filter { $0.status != .failed }
        let quantities = Dictionary(counted.map { ($0.productName, $0.quantity) }, uniquingKeysWith: +)
        let top = quantities.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.prefix(3).map(\.key)
        return MonthlySpending(month: month,
                               total: counted.reduce(0) { $0 + $1.totalPrice },
                               orderCount: counted.count,
                               topProducts: top)
    }
}
