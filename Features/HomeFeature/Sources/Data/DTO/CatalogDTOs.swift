//
//  CatalogDTOs.swift
//  HomeFeature · Data
//
//  DTO = cermin JSON backend (snake_case). Semua field optional;
//  CatalogMapper yang memutuskan data mana yang valid.
//
import Foundation
import NetworkManager

struct ProductDTO: Decodable {
    let id: String?
    let name: String?
    let description: String?
    let categoryID: String?
    let price: Int?
    /// Harga normal; hanya ada bila produk sedang promo (§5.24).
    let originalPrice: Int?
    let discountPercent: Int?
    let imageURL: String?
    let rating: Double?
    let soldCount: Int?
    let isAvailable: Bool?
    let tags: [String]?
    let options: [ProductOptionDTO]?

    enum CodingKeys: String, CodingKey {
        case id = "product_id"
        case name = "product_name"
        case description
        case categoryID = "category_id"
        case price
        case originalPrice = "original_price"
        case discountPercent = "discount_percent"
        case imageURL = "image_url"
        case rating
        case soldCount = "sold_count"
        case isAvailable = "is_available"
        case tags
        case options
    }
}

struct ProductOptionDTO: Decodable {
    let id: String?
    let name: String?
    let extraPrice: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case extraPrice = "extra_price"
    }
}

struct CategoryDTO: Decodable {
    let id: String?
    let name: String?
    let icon: String?
}

struct BannerDTO: Decodable {
    let id: String?
    let title: String?
    let subtitle: String?
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case imageURL = "image_url"
    }
}

/// `GET /v1/promotions/popup` (§5.24).
struct PromoPopupDTO: Decodable {
    let id: String?
    let title: String?
    let subtitle: String?
    let badge: String?
    let imageURL: String?
    let endsAt: String?
    let product: ProductDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case badge
        case imageURL = "image_url"
        case endsAt = "ends_at"
        case product
    }
}

/// `GET /v1/stores` (§5.26).
struct StoreDTO: Decodable {
    let id: String?
    let name: String?
    let address: String?
    let isOpen: Bool?
    let hoursLabel: String?
    let closedNote: String?
    let deliveryRadiusKM: Double?
    let distanceKM: Double?
    let isDeliverable: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, address
        case isOpen = "is_open"
        case hoursLabel = "hours_label"
        case closedNote = "closed_note"
        case deliveryRadiusKM = "delivery_radius_km"
        case distanceKM = "distance_km"
        case isDeliverable = "is_deliverable"
    }
}

typealias StoreListResponseDTO = APIEnvelope<[StoreDTO]>
typealias PromoPopupResponseDTO = APIEnvelope<PromoPopupDTO>
typealias ProductListResponseDTO = APIEnvelope<[ProductDTO]>
typealias CategoryListResponseDTO = APIEnvelope<[CategoryDTO]>
typealias BannerListResponseDTO = APIEnvelope<[BannerDTO]>
