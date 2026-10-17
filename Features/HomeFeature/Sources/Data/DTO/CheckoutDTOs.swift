//
//  CheckoutDTOs.swift
//  HomeFeature · Data
//
//  Response `POST /v1/orders` (API_PLAN.md §5.11). Hanya field yang dipakai app.
//
import Foundation
import NetworkManager

struct PlacedOrderDTO: Decodable {
    let orderID: String?
    let orderNumber: String?
    let status: String?
    let total: Int?

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case orderNumber = "order_number"
        case status
        case total
    }
}

typealias PlacedOrderResponseDTO = APIEnvelope<PlacedOrderDTO>
