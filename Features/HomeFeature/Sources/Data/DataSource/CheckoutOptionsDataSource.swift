//
//  CheckoutOptionsDataSource.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

protocol CheckoutOptionsRemoteDataSource {
    func fetchAddresses() async throws -> CheckoutAddressListResponseDTO
    func fetchPaymentMethods() async throws -> CheckoutPaymentOverviewResponseDTO
}

/// Backend asli: endpoint yang sama dengan tab Profil.
struct CheckoutOptionsAPIDataSource: CheckoutOptionsRemoteDataSource {
    var api: APIManager = .shared

    func fetchAddresses() async throws -> CheckoutAddressListResponseDTO {
        try await api.send(.addresses)
    }

    func fetchPaymentMethods() async throws -> CheckoutPaymentOverviewResponseDTO {
        try await api.send(.paymentMethods)
    }
}

/// Mock: satu alamat + Bayar Online/COD (tanpa network).
struct CheckoutOptionsMockDataSource: CheckoutOptionsRemoteDataSource {
    var latency: Duration = .milliseconds(300)

    func fetchAddresses() async throws -> CheckoutAddressListResponseDTO {
        try await Task.sleep(for: latency)
        return try decode("""
        { "code": 200, "message": "success", "data": [
          { "id": "addr-1", "label": "Rumah", "recipient": "Kholis", "phone": "081234567890",
            "address": "Jl. Kebayoran Lama No. 12, Jakarta Selatan", "is_default": true,
            "lat": -6.2389, "lng": 106.7826 }
        ] }
        """)
    }

    func fetchPaymentMethods() async throws -> CheckoutPaymentOverviewResponseDTO {
        try await Task.sleep(for: latency)
        return try decode("""
        { "code": 200, "message": "success", "data": { "default_id": "ONLINE", "methods": [
          { "id": "ONLINE", "type": "ONLINE", "name": "Bayar Online", "description": "GoPay, QRIS, ShopeePay, transfer bank (VA), kartu",
            "icon": "creditcard.fill", "is_enabled": true, "is_default": true },
          { "id": "COD", "type": "COD", "name": "Bayar di Tempat", "description": "Bayar tunai ke kurir saat pesanan tiba",
            "icon": "banknote", "is_enabled": true, "is_default": false }
        ] } }
        """)
    }

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}
