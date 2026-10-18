//
//  Payment.swift
//  HomeFeature · Domain
//
//  Pembayaran online (Midtrans Snap, API_PLAN.md §5.27). Checkout "Bayar Online" membuat
//  sesi pembayaran dulu; pesanan baru dibuat server setelah lunas.
//
import Foundation

enum PaymentStatus: String, Equatable {
    case pending = "PENDING"
    case paid = "PAID"
    case failed = "FAILED"
    case expired = "EXPIRED"
    case cancelled = "CANCELLED"

    var isFinal: Bool { self != .pending }
}

struct PaymentSession: Identifiable, Equatable {
    let id: String
    let status: PaymentStatus
    let amount: Decimal
    let expiresAt: Date
    /// Halaman Snap. `nil` setelah final, atau di mode mock.
    let redirectURL: URL?
    /// Navigasi WebView ke URL berawalan ini = user selesai di Snap → tutup WebView, lanjut cek status.
    let finishURLPrefix: String?
    let storeName: String
    /// Mis. "GoPay", "QRIS"; `nil` bila user belum memilih.
    let paymentTypeName: String?
    let statusMessage: String?
    /// Terisi setelah lunas.
    let order: PlacedOrder?

    func remaining(at now: Date = Date()) -> TimeInterval { max(0, expiresAt.timeIntervalSince(now)) }
}

/// Hasil tombol "Pesan Sekarang".
enum CheckoutOutcome: Equatable {
    /// COD: pesanan langsung dibuat.
    case placed(PlacedOrder)
    /// Bayar Online: selesaikan pembayaran dulu.
    case payment(PaymentSession)
}

/// Hasil layar pembayaran, diteruskan ke Keranjang / Beranda.
enum PaymentOutcome: Equatable {
    case paid(PlacedOrder)
    /// Gagal / kedaluwarsa / dibatalkan: keranjang tetap utuh.
    case notPaid(message: String)
    /// Ditutup tanpa membatalkan: sesi tetap menunggu (muncul di Beranda).
    case later
}

enum PaymentError: LocalizedError, Equatable {
    case network
    case notFound
    case alreadyFinal
    case gateway(String)
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .network: return "Tidak ada koneksi ke server. Coba lagi."
        case .notFound: return "Pembayaran tidak ditemukan."
        case .alreadyFinal: return "Pembayaran ini sudah selesai diproses."
        case .gateway(let message): return message
        case .sessionExpired: return "Sesi kamu berakhir. Silakan masuk lagi."
        }
    }
}
