//
//  CatalogRepository.swift
//  HomeFeature · Domain
//
import Foundation

protocol CatalogRepository {
    func fetchBanners() async throws -> [Banner]
    func fetchCategories() async throws -> [MenuCategory]
    func fetchProducts() async throws -> [Product]
}

enum CatalogError: LocalizedError, Equatable {
    case network
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .network: return "Tidak ada koneksi internet."
        case .invalidResponse: return "Data menu dari server tidak valid."
        case .unknown: return "Gagal memuat menu. Coba lagi."
        }
    }
}
