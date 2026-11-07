//
//  AppleIntelligenceOrderAssistant.swift
//  FocuseFeature · Data
//
//  Ringkasan belanja & chat bantuan pakai model on-device Apple Intelligence (iOS 26+).
//  Data pesanan diambil model lewat tool calling; tidak ada yang dikirim ke server AI.
//
import Foundation
import TTUI
import Utility
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppleIntelligenceOrderAssistant: OrderAssistant {
    let repository: OrderRepository

    var isAvailable: Bool { OnDeviceAI.isAvailable }

    func describe(_ spending: MonthlySpending) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
            You are a friendly shopping assistant in a grocery store app. Write ONE short sentence (max 25 words) \
            about the shopper's spending this month, with a practical saving tip if it fits. Use only the numbers \
            given; never invent numbers. Reply in \(OnDeviceAI.replyLanguage).
            """)
        let prompt = """
            Orders this month: \(spending.orderCount)
            Total spent: \(spending.total.rupiahFormatted)
            Most ordered: \(spending.topProducts.joined(separator: ", "))
            """
        return try? await session.respond(to: prompt).content
        #else
        return nil
        #endif
    }

    func makeChat() -> SupportChat {
        AppleIntelligenceSupportChat(repository: repository)
    }
}

final class AppleIntelligenceSupportChat: SupportChat {
    private let repository: OrderRepository
    /// `LanguageModelSession` (iOS 26+), dibuat saat pesan pertama; menyimpan riwayat percakapan.
    private var session: AnyObject?

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func reply(to message: String) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), OnDeviceAI.isAvailable else { return nil }
        let session = self.session as? LanguageModelSession ?? makeSession()
        self.session = session
        do {
            return try await session.respond(to: message).content
        } catch {
            // Mis. konteks penuh: pesan berikutnya mulai sesi baru.
            self.session = nil
            return nil
        }
        #else
        return nil
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private func makeSession() -> LanguageModelSession {
        LanguageModelSession(tools: [RecentOrdersTool(repository: repository), OrderDetailTool(repository: repository)],
                             instructions: """
            You are the customer support assistant of a grocery cooperative app. Reply in the shopper's language \
            (default \(OnDeviceAI.replyLanguage)), briefly (max 5 sentences), friendly and clear.
            Use the tools to look up the shopper's orders. Never guess order status, totals, dates or arrival times.
            Store facts:
            - Free delivery coupon: shoppers get free-delivery coupons every week. Turn on "Use free delivery coupon" \
            in the cart at checkout; the remaining coupons are shown there. New quota every Monday.
            - Payment: cash on delivery (COD) or online (e-wallet / QRIS). Unfinished online payments appear on the \
            Home screen as "Waiting for payment".
            - Cancelling: an order can be cancelled from its Order Detail as long as the outlet has not processed it. \
            Online payments of cancelled or failed orders are refunded by the store.
            - "Order again" on an order puts its items back in the cart. Completed orders can be rated 1–5 stars.
            If you cannot help, suggest contacting the outlet directly. Do not answer topics unrelated to shopping.
            """)
    }
    #endif
}

#if canImport(FoundationModels)
@available(iOS 26, *)
private struct RecentOrdersTool: Tool {
    let name = "getRecentOrders"
    let description = "Get the shopper's most recent orders (id, items, date, status, total)."
    let repository: OrderRepository

    @Generable
    struct Arguments {
        @Guide(description: "How many recent orders to fetch", .range(1...5))
        let count: Int
    }

    func call(arguments: Arguments) async throws -> String {
        guard let orders = try? await repository.fetchOrders(OrderListQuery()) else {
            return "Could not load orders (no internet connection or not signed in)."
        }
        guard !orders.isEmpty else { return "The shopper has no orders yet." }
        return orders.prefix(min(max(arguments.count, 1), 5)).map { order in
            "id \(order.id) | \(order.productName) | \(order.createdAt.formatted(date: .abbreviated, time: .shortened)) "
                + "| status \(order.status.toolDescription) | \(order.totalPrice.rupiahFormatted)"
        }.joined(separator: "\n")
    }
}

@available(iOS 26, *)
private struct OrderDetailTool: Tool {
    let name = "getOrderDetail"
    let description = """
        Get full details of one order by the id from getRecentOrders: status history, estimated arrival, \
        payment, whether it can be cancelled, refund.
        """
    let repository: OrderRepository

    @Generable
    struct Arguments {
        @Guide(description: "Order id from getRecentOrders")
        let orderID: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard let detail = try? await repository.fetchOrderDetail(id: arguments.orderID) else {
            return "Could not load that order. Make sure the id comes from getRecentOrders."
        }
        var lines = [
            "Order \(detail.orderNumber) from \(detail.storeName), placed \(detail.createdAt.formatted(date: .abbreviated, time: .shortened))",
            "Status: \(detail.rawStatus)",
            "Items: " + detail.items.map { "\($0.quantity)× \($0.name)" }.joined(separator: ", "),
            "Total: \(detail.total.rupiahFormatted) (delivery fee \(detail.deliveryFee.rupiahFormatted))",
            "Payment: \(detail.paymentMethod)",
            "Can still be cancelled: \(detail.canCancel ? "yes" : "no")",
            "Free delivery coupon used: \(detail.freeDeliveryCoupon ? "yes" : "no")",
        ]
        if let arrival = detail.estimatedArrival {
            lines.append("Estimated arrival: \(arrival.lowerBound.formatted(date: .omitted, time: .shortened))–\(arrival.upperBound.formatted(date: .omitted, time: .shortened))")
        }
        if let note = detail.closingNote { lines.append("Reason from outlet: \(note)") }
        switch detail.refund {
        case .pending: lines.append("Refund: not yet returned by the store")
        case .partial(let amount): lines.append("Refund: \(amount.rupiahFormatted) returned so far")
        case .completed(let amount): lines.append("Refund: \(amount.rupiahFormatted) fully returned")
        case nil: break
        }
        if let last = detail.history.last {
            lines.append("Last update: \(last.rawStatus) at \(last.at.formatted(date: .abbreviated, time: .shortened))")
        }
        return lines.joined(separator: "\n")
    }
}

private extension OrderStatus {
    var toolDescription: String {
        switch self {
        case .pending: return "in progress"
        case .completed: return "completed"
        case .failed: return "cancelled/failed"
        }
    }
}
#endif
