//
//  OrderRepository.swift
//  FocuseFeature · Domain
//
import Combine
import Foundation

protocol OrderRepository {
    func fetchOrders(_ query: OrderListQuery) async throws -> [Order]
    func fetchOrderDetail(id: String) async throws -> OrderDetail
    func rate(orderID: String, rating: Int, comment: String) async throws
    /// Batalkan pesanan yang belum diproses outlet; mengembalikan detail terbaru.
    func cancel(orderID: String) async throws -> OrderDetail
}

/// Asisten AI on-device (Apple Intelligence) untuk tab Pesanan.
protocol OrderAssistant {
    var isAvailable: Bool { get }
    /// Satu kalimat tentang belanja bulan ini; `nil` = AI tidak tersedia / gagal.
    func describe(_ spending: MonthlySpending) async -> String?
    /// Percakapan bantuan baru; riwayat chat disimpan di objek ini.
    func makeChat() -> SupportChat
}

/// Membacakan teks (balasan asisten).
protocol SpeechSpeaker: AnyObject {
    var isSpeakingPublisher: AnyPublisher<Bool, Never> { get }
    func speak(_ text: String)
    func stop()
}

protocol SupportChat: AnyObject {
    /// `nil` = AI gagal menjawab.
    func reply(to message: String) async -> String?
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
        case .network: return String(localized: "Tidak ada koneksi internet.")
        case .invalidResponse: return String(localized: "Data pesanan tidak valid.")
        case .invalidRating: return String(localized: "Pilih 1–5 bintang dulu ya.")
        case .rejected(let message): return message
        case .unknown: return String(localized: "Gagal memuat pesanan. Coba lagi.")
        }
    }
}
