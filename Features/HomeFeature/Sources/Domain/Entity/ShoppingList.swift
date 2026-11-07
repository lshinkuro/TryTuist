//
//  ShoppingList.swift
//  HomeFeature · Domain
//
import Foundation

/// Satu baris hasil "Daftar Belanja" (dari teks, resep, atau foto catatan).
struct ShoppingListItem: Identifiable, Equatable {
    let product: Product
    var quantity: Int
    var isSelected = true

    var id: String { product.id }
}

/// Produk + jumlah yang dipilih AI dari katalog.
struct PlannedItem: Equatable {
    let productID: String
    let quantity: Int
}

/// Riwayat beli per produk (lokal), dasar pengingat beli ulang.
struct PurchaseRecord: Codable, Equatable {
    let productID: String
    var name: String
    /// Satu tanggal per hari pembelian, terlama dulu.
    var dates: [Date]
}

struct RestockReminder: Equatable {
    let productID: String
    let name: String
    let date: Date
}
