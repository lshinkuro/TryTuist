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

    func fetchProducts(storeID: String?) async throws -> [Product] {
        do {
            return CatalogMapper.products(from: try await remote.fetchProducts(storeID: storeID))
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func fetchProduct(id: String, storeID: String?) async throws -> Product {
        let dto: ProductResponseDTO
        do {
            dto = try await remote.fetchProduct(id: id, storeID: storeID)
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
        guard let data = dto.data, let product = CatalogMapper.product(from: data) else { throw CatalogError.invalidResponse }
        return product
    }

    func fetchOutlets(near point: GeoPoint?) async throws -> [Outlet] {
        do {
            return CatalogMapper.outlets(from: try await remote.fetchStores(near: point))
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func fetchPromoPopup(storeID: String?) async throws -> PromoPopup? {
        do {
            return CatalogMapper.promoPopup(from: try await remote.fetchPromoPopup(storeID: storeID))
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func fetchFavorites(storeID: String?) async throws -> [Product] {
        do {
            return CatalogMapper.products(from: try await remote.fetchFavorites(storeID: storeID))
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func setFavorite(productID: String, isFavorite: Bool) async throws {
        do {
            try await remote.setFavorite(productID: productID, isFavorite: isFavorite)
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }
}
