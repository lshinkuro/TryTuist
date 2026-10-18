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

    private func decode<T: Decodable>(_ json: String) async throws -> T {
        try await Task.sleep(for: latency)
        return try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
