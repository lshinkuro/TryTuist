//
//  CheckoutOptions.swift
//  HomeFeature · Domain
//
//  Pilihan alamat & metode bayar di Keranjang. Datanya milik user (dikelola di tab Profil),
//  HomeFeature hanya membaca versi ringkasnya — tidak bergantung ke ProfileFeature.
//
import Foundation

struct CheckoutAddress: Identifiable, Equatable {
    let id: String
    let label: String
    let recipient: String
    let phone: String
    let address: String
    let isDefault: Bool
}

struct CheckoutPaymentMethod: Identifiable, Equatable {
    /// "COD" | "QRIS" | uuid e-wallet — dikirim sebagai `payment_method_id`.
    let id: String
    let name: String
    let detail: String?
    let systemImage: String
    let isEnabled: Bool
    let isDefault: Bool
}

struct CheckoutOptions: Equatable {
    let addresses: [CheckoutAddress]
    let paymentMethods: [CheckoutPaymentMethod]

    var defaultAddress: CheckoutAddress? {
        addresses.first(where: \.isDefault) ?? addresses.first
    }

    var defaultPaymentMethod: CheckoutPaymentMethod? {
        paymentMethods.first { $0.isDefault && $0.isEnabled } ?? paymentMethods.first(where: \.isEnabled)
    }
}

/// Pilihan user untuk satu checkout. `nil` = biarkan server memakai default user.
struct CheckoutSelection: Equatable {
    var addressID: String?
    var paymentMethodID: String?

    static let serverDefault = CheckoutSelection()
}
