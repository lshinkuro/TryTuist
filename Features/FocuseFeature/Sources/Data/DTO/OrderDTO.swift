//
//  OrderDTO.swift
//  FocuseFeature · Data
//
import Foundation
import NetworkManager

struct OrderDTO: Decodable {
    let orderID: String?
    let storeName: String?
    let productName: String?
    /// ISO-8601, mis. "2024-08-20T12:46:00+07:00"
    let createdAt: String?
    let totalPrice: Int?
    let qty: Int?
    /// "PENDING" | "COMPLETED" | "FAILED"
    let status: String?
    let canRate: Bool?
    let rating: Int?

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case canRate = "can_rate"
        case rating
        case storeName = "store_name"
        case productName = "product_name"
        case createdAt = "created_at"
        case totalPrice = "total_price"
        case qty
        case status
    }
}

typealias OrderListResponseDTO = APIEnvelope<[OrderDTO]>

/// `GET /v1/orders/{id}` (API_PLAN.md §5.13). Hanya field yang ditampilkan di Detail.
struct OrderDetailDTO: Decodable {
    let orderID: String?
    let orderNumber: String?
    let status: String?
    let createdAt: String?
    let subtotal: Int?
    let deliveryFee: Int?
    let discount: Int?
    let total: Int?
    let paymentMethod: String?
    let paymentProvider: String?
    let voucherCode: String?
    let items: [ItemDTO]?
    let store: StoreDTO?
    let address: AddressDTO?
    let statusHistory: [StatusEventDTO]?
    let canRate: Bool?
    let rating: RatingDTO?
    let distanceKm: Double?
    let etaMinMinutes: Int?
    let etaMaxMinutes: Int?
    let canCancel: Bool?
    let freeDeliveryCoupon: Bool?
    let deliveryFeeWaived: Int?
    let refund: RefundDTO?

    struct RefundDTO: Decodable {
        let status: String?
        let amount: Int?
    }

    struct RatingDTO: Decodable {
        let rating: Int?
        let comment: String?
    }

    struct ItemDTO: Decodable {
        let productID: String?
        let optionID: String?
        let productName: String?
        let optionName: String?
        let quantity: Int?
        let note: String?
        let subtotal: Int?
        /// Isi combo (per 1 paket); nil untuk produk biasa.
        let bundleItems: [BundleItemDTO]?

        struct BundleItemDTO: Decodable {
            let productName: String?
            let optionName: String?
            let quantity: Int?

            enum CodingKeys: String, CodingKey {
                case productName = "product_name"
                case optionName = "option_name"
                case quantity
            }
        }

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case optionID = "option_id"
            case productName = "product_name"
            case optionName = "option_name"
            case quantity, note, subtotal
            case bundleItems = "bundle_items"
        }
    }

    struct StoreDTO: Decodable {
        let name: String?
        let address: String?
    }

    struct AddressDTO: Decodable {
        let label: String?
        let recipient: String?
        let address: String?
    }

    struct StatusEventDTO: Decodable {
        let status: String?
        let at: String?
        let note: String?
    }

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case orderNumber = "order_number"
        case status
        case createdAt = "created_at"
        case subtotal
        case deliveryFee = "delivery_fee"
        case discount, total
        case paymentMethod = "payment_method"
        case paymentProvider = "payment_provider"
        case voucherCode = "voucher_code"
        case items, store, address
        case statusHistory = "status_history"
        case canRate = "can_rate"
        case rating
        case distanceKm = "distance_km"
        case etaMinMinutes = "eta_min_minutes"
        case etaMaxMinutes = "eta_max_minutes"
        case canCancel = "can_cancel"
        case freeDeliveryCoupon = "free_delivery_coupon"
        case deliveryFeeWaived = "delivery_fee_waived"
        case refund
    }
}

typealias OrderDetailResponseDTO = APIEnvelope<OrderDetailDTO>
