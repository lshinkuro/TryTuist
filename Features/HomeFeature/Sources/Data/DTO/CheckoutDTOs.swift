//
//  CheckoutDTOs.swift
//  HomeFeature · Data
//
//  Response `POST /v1/orders` (§5.11), `POST /v1/checkout` & `/v1/payments` (§5.27). Hanya field yang dipakai app.
//
import Foundation
import NetworkManager

struct PlacedOrderDTO: Decodable {
    let orderID: String?
    let orderNumber: String?
    let status: String?
    let total: Int?
    let paymentProvider: String?

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case orderNumber = "order_number"
        case status
        case total
        case paymentProvider = "payment_provider"
    }
}

typealias PlacedOrderResponseDTO = APIEnvelope<PlacedOrderDTO>

struct PaymentOrderRefDTO: Decodable {
    let id: String?
    let orderNumber: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber = "order_number"
        case status
    }
}

struct PaymentStoreDTO: Decodable {
    let id: String?
    let name: String?
}

struct PaymentDTO: Decodable {
    let id: String?
    let status: String?
    let amount: Int?
    let expiresAt: String?
    let redirectURL: String?
    let finishURLPrefix: String?
    let paymentType: String?
    let statusMessage: String?
    let store: PaymentStoreDTO?
    let order: PaymentOrderRefDTO?

    enum CodingKeys: String, CodingKey {
        case id, status, amount, store, order
        case expiresAt = "expires_at"
        case redirectURL = "redirect_url"
        case finishURLPrefix = "finish_url_prefix"
        case paymentType = "payment_type"
        case statusMessage = "status_message"
    }
}

/// `data` dari `POST /v1/checkout`: `next` = "ORDER" (COD) | "PAYMENT" (Bayar Online).
struct CheckoutDTO: Decodable {
    let next: String?
    let order: PlacedOrderDTO?
    let payment: PaymentDTO?
}

typealias CheckoutResponseDTO = APIEnvelope<CheckoutDTO>
typealias PaymentResponseDTO = APIEnvelope<PaymentDTO>
typealias PaymentListResponseDTO = APIEnvelope<[PaymentDTO]>
