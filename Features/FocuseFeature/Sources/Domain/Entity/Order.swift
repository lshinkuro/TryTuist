//
//  Order.swift
//  FocuseFeature · Domain
//
import Foundation

enum OrderStatus: CaseIterable, Equatable {
    case pending
    case completed
    case failed
}

struct Order: Identifiable, Equatable {
    let id: String
    let storeName: String
    let productName: String
    let createdAt: Date
    let totalPrice: Decimal
    let quantity: Int
    let status: OrderStatus
    /// Selesai & belum dinilai.
    var canRate = false
    /// Bintang 1–5 yang sudah diberikan; nil = belum.
    var rating: Int?
}

/// Filter + halaman riwayat pesanan; filter & urutan dikerjakan server.
struct OrderListQuery: Equatable {
    static let pageSize = 20

    /// nil = semua status.
    var status: OrderStatus?
    /// Rentang [from, to); nil = tanpa batas.
    var from: Date?
    var to: Date?
    var newestFirst = true
    var page = 1
}

/// `GET /v1/orders/{id}`: isi pesanan lengkap.
struct OrderDetail: Equatable {
    struct Item: Equatable {
        let productID: String
        let optionID: String?
        let name: String
        let optionName: String?
        let quantity: Int
        let note: String?
        let subtotal: Decimal
    }

    struct StatusEvent: Equatable {
        /// Status mentah backend (PENDING, PAID, PROCESSING, …), ditampilkan apa adanya oleh Presentation.
        let rawStatus: String
        let at: Date
        let note: String?
    }

    let id: String
    let orderNumber: String
    let status: OrderStatus
    let rawStatus: String
    let createdAt: Date
    let storeName: String
    let storeAddress: String?
    let deliveryAddress: String?
    let paymentMethod: String
    let items: [Item]
    let subtotal: Decimal
    let deliveryFee: Decimal
    let discount: Decimal
    let total: Decimal
    let voucherCode: String?
    let history: [StatusEvent]
    let canRate: Bool
    let rating: Int?
    let ratingComment: String?
}
