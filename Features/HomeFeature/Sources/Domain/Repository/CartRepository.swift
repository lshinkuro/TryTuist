//
//  CartRepository.swift
//  HomeFeature · Domain
//
//  Keranjang adalah state bersama antar-screen (Beranda, Menu, Detail, Keranjang).
//  Store berlangganan `summaryPublisher` lewat `Store.bind`.
//
import Combine
import Foundation

@MainActor
protocol CartRepository: AnyObject {
    var summaryPublisher: AnyPublisher<CartSummary, Never> { get }
    var itemsPublisher: AnyPublisher<[CartItem], Never> { get }

    func add(_ item: CartItem) async throws
    func updateQuantity(itemID: String, quantity: Int) async
    func remove(itemID: String) async
    func checkout() async throws -> PlacedOrder
}

enum CartError: LocalizedError, Equatable {
    case productUnavailable
    case invalidQuantity
    case emptyCart
    case checkoutFailed

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return "Maaf, menu ini sedang habis."
        case .invalidQuantity: return "Jumlah pesanan harus 1–20."
        case .emptyCart: return "Keranjang masih kosong."
        case .checkoutFailed: return "Pesanan gagal dibuat. Coba lagi."
        }
    }
}
