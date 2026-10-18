//
//  DeliveryLocation.swift
//  HomeFeature · Domain
//
//  "Antar ke" di Beranda: alamat tersimpan user (dari Profil) atau lokasi perangkat saat ini.
//  Titiknya dipakai mencari outlet terdekat; alamat tersimpan juga jadi default di Keranjang.
//
import Foundation

struct DeliveryLocation: Equatable {
    enum Source: Equatable {
        /// `id` alamat di `/v1/me/addresses`.
        case savedAddress(id: String)
        case currentLocation
    }

    let source: Source
    /// Mis. "Rumah" / "Lokasi saat ini".
    let title: String
    /// Alamat lengkap / hasil reverse geocode.
    let subtitle: String
    /// `nil` = alamat belum dipin (outlet dipilih tanpa jarak).
    let point: GeoPoint?

    var savedAddressID: String? {
        if case .savedAddress(let id) = source { return id }
        return nil
    }

    static func saved(_ address: CheckoutAddress) -> DeliveryLocation {
        DeliveryLocation(source: .savedAddress(id: address.id), title: address.label,
                         subtitle: address.address, point: address.location)
    }
}

/// Isi sheet "Antar ke": pilihan saat ini + alamat tersimpan.
struct DeliveryChoice: Equatable {
    let selected: DeliveryLocation?
    let addresses: [CheckoutAddress]

    static let empty = DeliveryChoice(selected: nil, addresses: [])
}

/// Izin lokasi (When In Use).
enum LocationPermission: Equatable {
    case notDetermined
    case denied
    case authorized
}

enum LocationError: LocalizedError, Equatable {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied: return "Izin lokasi belum diberikan. Aktifkan di Pengaturan → TryTuist → Lokasi."
        case .unavailable: return "Lokasi tidak bisa didapat. Coba lagi di tempat terbuka."
        }
    }
}
