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

    func fetchOutlets(near point: GeoPoint?) async throws -> [Outlet] {
        do {
            return CatalogMapper.outlets(from: try await remote.fetchStores(near: point))
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }

    func fetchPromoPopup() async throws -> PromoPopup? {
        do {
            return CatalogMapper.promoPopup(from: try await remote.fetchPromoPopup())
        } catch {
            throw CatalogMapper.toDomainError(error)
        }
    }
}
