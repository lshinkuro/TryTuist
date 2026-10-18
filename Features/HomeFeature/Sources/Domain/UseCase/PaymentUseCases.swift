//
//  PaymentUseCases.swift
//  HomeFeature · Domain
//
import Foundation

/// Cek status pembayaran (polling layar Pembayaran).
struct CheckPaymentUseCase {
    let repository: PaymentRepository

    func execute(id: String) async throws -> PaymentSession {
        try await repository.status(id: id)
    }
}

/// Batalkan sesi yang masih menunggu. Bila ternyata sudah lunas, status lunas yang dikembalikan.
struct CancelPaymentUseCase {
    let repository: PaymentRepository

    func execute(id: String) async throws -> PaymentSession {
        do {
            return try await repository.cancel(id: id)
        } catch PaymentError.alreadyFinal {
            return try await repository.status(id: id)
        }
    }
}

/// Kartu "Menunggu pembayaran" di Beranda. Gagal memuat = tidak ada kartu.
struct GetPendingPaymentUseCase {
    let repository: PaymentRepository
    var now: () -> Date = Date.init

    func execute() async -> PaymentSession? {
        guard let list = try? await repository.pending() else { return nil }
        return list.first { $0.status == .pending && $0.remaining(at: now()) > 0 && $0.redirectURL != nil }
    }
}

/// Pembayaran selesai: lunas → keranjang dikosongkan; selain itu keranjang tetap,
/// dan checkout berikutnya memakai Idempotency-Key baru.
struct FinishPaymentUseCase {
    let cart: CartRepository

    func execute(_ outcome: PaymentOutcome) async {
        switch outcome {
        case .paid: await cart.finishPayment(paid: true)
        case .notPaid: await cart.finishPayment(paid: false)
        case .later: break
        }
    }
}
