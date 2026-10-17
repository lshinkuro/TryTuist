//
//  CheckoutOptionsRepository.swift
//  HomeFeature · Domain
//
import Foundation

protocol CheckoutOptionsRepository {
    /// Alamat + metode pembayaran user (diambil bersamaan).
    func options() async throws -> CheckoutOptions
}
