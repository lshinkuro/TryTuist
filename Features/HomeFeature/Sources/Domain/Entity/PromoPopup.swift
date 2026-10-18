//
//  PromoPopup.swift
//  HomeFeature · Domain
//
//  Popup promo makanan/minuman murah di Beranda (API_PLAN.md §5.24).
//  Tap → Detail menu; harga di `product` sudah harga promo, jadi tambah ke keranjang
//  otomatis memakai potongan harga.
//
import Foundation

struct PromoPopup: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    /// Mis. "HEMAT 37%".
    let badge: String
    let imageURL: URL?
    let endsAt: Date?
    let product: Product
}
