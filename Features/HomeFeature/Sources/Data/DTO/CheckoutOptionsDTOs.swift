//
//  CheckoutOptionsDTOs.swift
//  HomeFeature · Data
//
//  Bagian dari `GET /v1/me/addresses` (§5.17) dan `GET /v1/me/payment-methods` (§5.21)
//  yang dibutuhkan Keranjang. Field lain dari response diabaikan.
//
import Foundation
import NetworkManager

struct CheckoutAddressDTO: Decodable {
    let id: String?
    let label: String?
    let recipient: String?
    let phone: String?
    let address: String?
    let isDefault: Bool?
    let lat: Double?
    let lng: Double?

    enum CodingKeys: String, CodingKey {
        case id, label, recipient, phone, address, lat, lng
        case isDefault = "is_default"
    }
}

struct CheckoutPaymentMethodDTO: Decodable {
    let id: String?
    let type: String?
    let name: String?
    let description: String?
    let icon: String?
    let accountMasked: String?
    let isEnabled: Bool?
    let isDefault: Bool?

    enum CodingKeys: String, CodingKey {
        case id, type, name, description, icon
        case accountMasked = "account_masked"
        case isEnabled = "is_enabled"
        case isDefault = "is_default"
    }
}

struct CheckoutPaymentOverviewDTO: Decodable {
    let defaultID: String?
    let methods: [CheckoutPaymentMethodDTO]?

    enum CodingKeys: String, CodingKey {
        case methods
        case defaultID = "default_id"
    }
}

typealias CheckoutAddressListResponseDTO = APIEnvelope<[CheckoutAddressDTO]>
typealias CheckoutPaymentOverviewResponseDTO = APIEnvelope<CheckoutPaymentOverviewDTO>
