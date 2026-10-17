//
//  CatalogUseCases.swift
//  HomeFeature · Domain
//
import Foundation

struct HomeContent: Equatable {
    let banners: [Banner]
    let categories: [MenuCategory]
    let bestSellers: [Product]
    let recommended: [Product]
}

struct MenuContent: Equatable {
    let categories: [MenuCategory]
    let products: [Product]
}

/// Beranda: banner, kategori, best seller (terlaris), dan rekomendasi (rating tertinggi).
struct GetHomeContentUseCase {
    let repository: CatalogRepository

    func execute() async throws -> HomeContent {
        async let banners = repository.fetchBanners()
        async let categories = repository.fetchCategories()
        async let products = repository.fetchProducts()

        let available = try await products.filter(\.isAvailable)
        return try await HomeContent(
            banners: banners,
            categories: categories,
            bestSellers: Array(available.sorted { $0.soldCount > $1.soldCount }.prefix(6)),
            recommended: Array(available.sorted { $0.rating > $1.rating }.prefix(5))
        )
    }
}

/// Tab Menu: semua kategori & produk.
struct GetMenuUseCase {
    let repository: CatalogRepository

    func execute() async throws -> MenuContent {
        async let categories = repository.fetchCategories()
        async let products = repository.fetchProducts()
        return try await MenuContent(categories: categories, products: products)
    }
}

/// Aturan bisnis tambah ke keranjang.
struct AddToCartUseCase {
    let cart: CartRepository
    static let quantityRange = 1...20

    func execute(product: Product, option: ProductOption?, quantity: Int, note: String = "") async throws {
        guard product.isAvailable else { throw CartError.productUnavailable }
        guard Self.quantityRange.contains(quantity) else { throw CartError.invalidQuantity }
        let item = CartItem(product: product,
                            option: option ?? product.defaultOption,
                            quantity: quantity,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        try await cart.add(item)
    }
}
