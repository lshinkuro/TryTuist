//
//  OrderRepository.swift
//  FocuseFeature · Domain
//
import Foundation

protocol OrderRepository {
    func fetchOrders() async throws -> [Order]
}

enum OrderError: LocalizedError, Equatable {
    case network
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .network: return "Tidak ada koneksi internet."
        case .invalidResponse: return "Data pesanan tidak valid."
        case .unknown: return "Gagal memuat pesanan. Coba lagi."
        }
    }
}
