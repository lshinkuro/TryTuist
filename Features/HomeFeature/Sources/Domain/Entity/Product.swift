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
    /// Harga dasar yang berlaku sekarang (tanpa opsi), sudah termasuk promo.
    /// Format "Rp" dilakukan di Presentation.
    let price: Decimal
    let imageURL: URL?
    let rating: Double
    let soldCount: Int
    let isAvailable: Bool
    let isBestSeller: Bool
    /// Pilihan ukuran/varian. Kosong = tidak ada pilihan.
    let options: [ProductOption]
    /// Harga normal sebelum promo; `nil` = tidak sedang promo (API_PLAN.md §5.24).
    var originalPrice: Decimal? = nil
    /// Paket combo: isi & hemat dibanding beli satuan; `nil` untuk produk biasa.
    var combo: Combo? = nil

    var defaultOption: ProductOption? { options.first }

    var isOnDeal: Bool { (originalPrice ?? 0) > price }

    /// Potongan dibulatkan ke bawah, sama dengan backend: 32.000 → 19.900 = 37%.
    var discountPercent: Int {
        guard let originalPrice, isOnDeal, originalPrice > 0 else { return 0 }
        let percent = (originalPrice - price) * 100 / originalPrice
        return Int(NSDecimalNumber(decimal: percent).doubleValue.rounded(.down))
    }
}

/// Isi paket combo (isi tetap, diatur admin).
struct Combo: Hashable {
    struct Item: Hashable {
        let name: String
        let optionName: String?
        let quantity: Int

        /// "1× Es Kopi Susu (Large)".
        var label: String { "\(quantity)× \(name)" + (optionName.map { " (\($0))" } ?? "") }
    }

    let items: [Item]
    /// Total bila isinya dibeli satuan.
    let separatePrice: Decimal
    let savings: Decimal

    var summary: String { items.map(\.label).joined(separator: ", ") }
}

struct ProductOption: Identifiable, Hashable {
    let id: String
    let name: String
    let extraPrice: Decimal
}
