//
//  DefaultCatalogRepository.swift
//  HomeFeature · Data
//
import Foundation

struct DefaultCatalogRepository: CatalogRepository {
    let remote: CatalogRemoteDataSource

    func fetchBanners() async throws -> [Banner] {
        do {
            return CatalogMapper.banners(from: try await remote.fetchBanners())
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func fetchCategories() async throws -> [MenuCategory] {
        do {
            return CatalogMapper.categories(from: try await remote.fetchCategories())
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func fetchProducts() async throws -> [Product] {
        do {
            return CatalogMapper.products(from: try await remote.fetchProducts())
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }
}
