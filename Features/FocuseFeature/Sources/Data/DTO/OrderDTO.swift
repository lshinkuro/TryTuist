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

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case storeName = "store_name"
        case productName = "product_name"
        case createdAt = "created_at"
        case totalPrice = "total_price"
        case qty
        case status
    }
}

typealias OrderListResponseDTO = APIEnvelope<[OrderDTO]>
