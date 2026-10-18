//
//  Cart.swift
//  HomeFeature · Domain
//
import Foundation

struct CartItem: Identifiable, Equatable {
    /// Produk + opsi + catatan yang sama digabung jadi satu baris.
    var id: String { [product.id, option?.id ?? "-", note].joined(separator: "|") }
    let product: Product
    let option: ProductOption?
    var quantity: Int
    let note: String

    var unitPrice: Decimal { product.price + (option?.extraPrice ?? 0) }
    var subtotal: Decimal { unitPrice * Decimal(quantity) }
}

struct CartSummary: Equatable {
    let itemCount: Int
    let total: Decimal

    static let empty = CartSummary(itemCount: 0, total: 0)
    var isEmpty: Bool { itemCount == 0 }
}

/// Pesanan yang sudah dibuat (COD, atau online setelah lunas).
struct PlacedOrder: Equatable {
    let orderNumber: String
    let total: Decimal
    var orderID: String? = nil
    /// Mis. "Dibayar via GoPay"; `nil` untuk COD.
    var paidVia: String? = nil
}
