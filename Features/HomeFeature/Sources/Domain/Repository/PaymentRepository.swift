//
//  PaymentRepository.swift
//  HomeFeature · Domain
//
import Foundation

protocol PaymentRepository {
    /// Status terbaru. Selama `PENDING`, server ikut mengecek ke Midtrans.
    func status(id: String) async throws -> PaymentSession
    func cancel(id: String) async throws -> PaymentSession
    /// Sesi yang masih menunggu dibayar (paling baru dulu).
    func pending() async throws -> [PaymentSession]
    /// Debugger (backend dev): hasil pembayaran tanpa simulator Midtrans.
    func simulate(id: String, outcome: PaymentSimulation) async throws -> PaymentSession
}
