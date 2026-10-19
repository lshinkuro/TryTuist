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

/// Rincian harga dari server (`POST /v1/orders/quote`): ongkir per jarak alamat → outlet.
struct CartQuote: Equatable {
    let subtotal: Decimal
    let deliveryFee: Decimal
    let discount: Decimal
    let total: Decimal
    /// `nil` bila alamat tidak punya koordinat (ongkir = tarif dasar).
    let distanceKm: Double?
    /// Estimasi tiba dalam menit, mis. 25...35.
    let eta: ClosedRange<Int>?
    /// `nil` bila server tidak mengirim (mis. backend lama).
    var freeDelivery: FreeDeliveryCoupon? = nil
}

/// Kupon gratis ongkir mingguan user (reset Senin 00:00 WIB).
struct FreeDeliveryCoupon: Equatable {
    let isEnabled: Bool
    let weeklyQuota: Int
    /// Sisa setelah pesanan ini (bila `isApplied`).
    let remaining: Int
    let isApplied: Bool
    /// Ongkir yang digratiskan.
    let feeWaived: Decimal
}

/// Pesanan yang sudah dibuat (COD, atau online setelah lunas).
struct PlacedOrder: Equatable {
    let orderNumber: String
    let total: Decimal
    var orderID: String? = nil
    /// Mis. "Dibayar via GoPay"; `nil` untuk COD.
    var paidVia: String? = nil
}
