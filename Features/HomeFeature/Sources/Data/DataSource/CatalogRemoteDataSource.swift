//
//  CatalogRemoteDataSource.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

protocol CatalogRemoteDataSource {
    func fetchBanners() async throws -> BannerListResponseDTO
    func fetchCategories() async throws -> CategoryListResponseDTO
    /// `storeID` nil = stok pusat.
    func fetchProducts(storeID: String?) async throws -> ProductListResponseDTO
    func fetchStores(near point: GeoPoint?) async throws -> StoreListResponseDTO
    func fetchPromoPopup() async throws -> PromoPopupResponseDTO
    func fetchFavorites() async throws -> ProductListResponseDTO
    func setFavorite(productID: String, isFavorite: Bool) async throws
}

/// Backend asli (Go). Kontrak: API_PLAN.md → `GET /v1/banners`, `/v1/categories`, `/v1/products`,
/// `/v1/stores`, `/v1/promotions/popup`.
struct CatalogAPIDataSource: CatalogRemoteDataSource {
    var api: APIManager = .shared

    func fetchBanners() async throws -> BannerListResponseDTO {
        try await api.request(.banners)
    }

    func fetchCategories() async throws -> CategoryListResponseDTO {
        try await api.request(.categories)
    }

    func fetchProducts(storeID: String?) async throws -> ProductListResponseDTO {
        try await api.request(.products(storeID: storeID))
    }

    func fetchStores(near point: GeoPoint?) async throws -> StoreListResponseDTO {
        try await api.request(.stores(lat: point?.lat, lng: point?.lng))
    }

    func fetchPromoPopup() async throws -> PromoPopupResponseDTO {
        try await api.request(.popupPromotion)
    }

    func fetchFavorites() async throws -> ProductListResponseDTO {
        try await api.request(.favorites)
    }

    func setFavorite(productID: String, isFavorite: Bool) async throws {
        let _: APIEnvelope<EmptyDTO> = try await api.request(.setFavorite(productID: productID, isFavorite: isFavorite))
    }
}

/// Mock: JSON fixture berbentuk sama dengan backend (lihat `CatalogFixtures`).
struct CatalogMockDataSource: CatalogRemoteDataSource {
    var latency: Duration = .milliseconds(600)

    func fetchBanners() async throws -> BannerListResponseDTO {
        try await decode(CatalogFixtures.banners)
    }

    func fetchCategories() async throws -> CategoryListResponseDTO {
        try await decode(CatalogFixtures.categories)
    }

    func fetchProducts(storeID: String?) async throws -> ProductListResponseDTO {
        try await decode(CatalogFixtures.productsJSON(storeID: storeID))
    }

    func fetchStores(near point: GeoPoint?) async throws -> StoreListResponseDTO {
        try await decode(CatalogFixtures.stores)
    }

    func fetchPromoPopup() async throws -> PromoPopupResponseDTO {
        try await decode(CatalogFixtures.promoPopup)
    }

    /// Favorit mock hanya di memori (hilang saat app ditutup).
    nonisolated(unsafe) private static var favoriteIDs: Set<String> = ["P01"]

    func fetchFavorites() async throws -> ProductListResponseDTO {
        let all: ProductListResponseDTO = try await decode(CatalogFixtures.products)
        return ProductListResponseDTO(code: all.code, message: all.message,
                                      data: all.data?.filter { Self.favoriteIDs.contains($0.id ?? "") })
    }

    func setFavorite(productID: String, isFavorite: Bool) async throws {
        try await Task.sleep(for: latency)
        if isFavorite { Self.favoriteIDs.insert(productID) } else { Self.favoriteIDs.remove(productID) }
    }

    private func decode<T: Decodable>(_ json: String) async throws -> T {
        try await Task.sleep(for: latency)
        return try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
