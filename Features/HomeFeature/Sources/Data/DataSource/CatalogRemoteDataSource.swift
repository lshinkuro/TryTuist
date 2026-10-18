//
//  CatalogRemoteDataSource.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

protocol CatalogRemoteDataSource {
    func fetchBanners() async throws -> BannerListResponseDTO
    func fetchCategories() async throws -> CategoryListResponseDTO
    func fetchProducts() async throws -> ProductListResponseDTO
    func fetchPromoPopup() async throws -> PromoPopupResponseDTO
}

/// Backend asli (Go). Kontrak: API_PLAN.md → `GET /v1/banners`, `/v1/categories`, `/v1/products`,
/// `/v1/promotions/popup`.
struct CatalogAPIDataSource: CatalogRemoteDataSource {
    var api: APIManager = .shared

    func fetchBanners() async throws -> BannerListResponseDTO {
        try await api.request(.banners)
    }

    func fetchCategories() async throws -> CategoryListResponseDTO {
        try await api.request(.categories)
    }

    func fetchProducts() async throws -> ProductListResponseDTO {
        try await api.request(.products)
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

    func fetchProducts() async throws -> ProductListResponseDTO {
        try await decode(CatalogFixtures.products)
    }

    func fetchPromoPopup() async throws -> PromoPopupResponseDTO {
        try await decode(CatalogFixtures.promoPopup)
    }

    private func decode<T: Decodable>(_ json: String) async throws -> T {
        try await Task.sleep(for: latency)
        return try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
