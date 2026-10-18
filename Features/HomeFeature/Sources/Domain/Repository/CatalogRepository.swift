//
//  CatalogRepository.swift
//  HomeFeature · Domain
//
import Foundation

protocol CatalogRepository {
    func fetchBanners() async throws -> [Banner]
    func fetchCategories() async throws -> [MenuCategory]
    /// `storeID` nil = stok pusat; diisi = ketersediaan mengikuti outlet itu (harga tetap sama).
    func fetchProducts(storeID: String?) async throws -> [Product]
    /// Outlet aktif, yang buka & menjangkau `point` lebih dulu.
    func fetchOutlets(near point: GeoPoint?) async throws -> [Outlet]
    /// `nil` = tidak ada promo popup yang berlaku.
    func fetchPromoPopup() async throws -> PromoPopup?
    func fetchFavorites() async throws -> [Product]
    func setFavorite(productID: String, isFavorite: Bool) async throws
}

/// Mengingat popup yang sudah ditutup supaya tidak muncul terus (sekali per hari per promo).
protocol PromoPopupDismissalStore {
    func isDismissed(promoID: String, on date: Date) -> Bool
    func markDismissed(promoID: String, on date: Date)
}

enum CatalogError: LocalizedError, Equatable {
    case network
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .network: return String(localized: "Tidak ada koneksi internet.")
        case .invalidResponse: return String(localized: "Data menu dari server tidak valid.")
        case .unknown: return String(localized: "Gagal memuat menu. Coba lagi.")
        }
    }
}
