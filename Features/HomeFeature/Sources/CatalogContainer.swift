//
//  CatalogContainer.swift
//  HomeFeature
//
//  Dependency bersama untuk tab Beranda & Menu: satu repository katalog
//  dan SATU keranjang, supaya isi keranjang sama di semua screen.
//
import Foundation
import Utility

@MainActor
final class CatalogContainer {
    static let shared = CatalogContainer()

    let catalogRepository: CatalogRepository
    let cartRepository: CartRepository

    private init() {
        catalogRepository = DefaultCatalogRepository(remote: Self.makeRemoteDataSource())
        cartRepository = InMemoryCartRepository()
    }

    private static func makeRemoteDataSource() -> CatalogRemoteDataSource {
        if AppConfig.useMockData { return CatalogMockDataSource() }
        return CatalogAPIDataSource()
    }

    // MARK: Use cases

    var getHomeContent: GetHomeContentUseCase { GetHomeContentUseCase(repository: catalogRepository) }
    var getMenu: GetMenuUseCase { GetMenuUseCase(repository: catalogRepository) }
    var addToCart: AddToCartUseCase { AddToCartUseCase(cart: cartRepository) }
}
