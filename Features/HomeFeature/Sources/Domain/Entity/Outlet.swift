//
//  Outlet.swift
//  HomeFeature · Domain
//
//  Cabang tempat pesanan dibuat. Harga sama di semua outlet; yang berbeda per outlet
//  hanya stok (menu habis), jam buka, dan radius antar.
//
import Foundation

struct Outlet: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    /// "24 jam" / "10:00–22:00".
    let hoursLabel: String
    /// Buka sekarang (jam operasional & tidak sedang tutup sementara).
    let isOpenNow: Bool
    /// Alasan tutup dari server, mis. "Outlet Kelapa Gading buka 10:00–22:00.".
    let closedNote: String?
    let deliveryRadiusKM: Double
    /// Hanya ada bila daftar diambil dengan koordinat alamat.
    let distanceKM: Double?
    /// `nil` = tidak diketahui (tanpa koordinat alamat).
    let isDeliverable: Bool?

    /// Baris kecil di bawah nama outlet, mis. "1,2 km · 24 jam".
    var detailText: String {
        var parts: [String] = []
        if let distanceKM { parts.append(Self.formatKM(distanceKM)) }
        parts.append(isOpenNow ? hoursLabel : String(localized: "outlet.closed", defaultValue: "Tutup"))
        if isDeliverable == false { parts.append(String(localized: "di luar jangkauan antar")) }
        return parts.joined(separator: " · ")
    }

    /// Bisa dipakai untuk memesan ke alamat utama sekarang.
    var canOrder: Bool { isOpenNow && isDeliverable != false }

    static func formatKM(_ km: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = km < 10 ? 1 : 0
        return "\(formatter.string(from: NSNumber(value: km)) ?? "\(km)") km"
    }
}

/// Koordinat alamat antar.
struct GeoPoint: Equatable {
    let lat: Double
    let lng: Double
}

/// Daftar outlet + outlet yang sedang dipakai.
struct OutletChoice: Equatable {
    let outlets: [Outlet]
    let selected: Outlet?

    static let empty = OutletChoice(outlets: [], selected: nil)
}
