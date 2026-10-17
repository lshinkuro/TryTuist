//
//  Product.swift
//  HomeFeature · Domain
//
import Foundation

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let categoryID: String
    /// Harga dasar (tanpa opsi). Format "Rp" dilakukan di Presentation.
    let price: Decimal
    let imageURL: URL?
    let rating: Double
    let soldCount: Int
    let isAvailable: Bool
    let isBestSeller: Bool
    /// Pilihan ukuran/varian. Kosong = tidak ada pilihan.
    let options: [ProductOption]

    var defaultOption: ProductOption? { options.first }
}

struct ProductOption: Identifiable, Hashable {
    let id: String
    let name: String
    let extraPrice: Decimal
}
