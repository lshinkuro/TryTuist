//
//  OrderRepository.swift
//  FocuseFeature · Domain
//
import Foundation

protocol OrderRepository {
    func fetchOrders(_ query: OrderListQuery) async throws -> [Order]
    func fetchOrderDetail(id: String) async throws -> OrderDetail
    func rate(orderID: String, rating: Int, comment: String) async throws
}

enum OrderError: LocalizedError, Equatable {
    case network
    case invalidResponse
    case invalidRating
    /// Ditolak server dengan pesan sendiri (mis. sudah dinilai).
    case rejected(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .network: return "Tidak ada koneksi internet."
        case .invalidResponse: return "Data pesanan tidak valid."
        case .invalidRating: return "Pilih 1–5 bintang dulu ya."
        case .rejected(let message): return message
        case .unknown: return "Gagal memuat pesanan. Coba lagi."
        }
    }
}
