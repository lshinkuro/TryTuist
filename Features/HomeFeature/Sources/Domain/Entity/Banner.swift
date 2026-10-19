//
//  Banner.swift
//  HomeFeature · Domain
//
import Foundation

struct Banner: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    var action: BannerAction = .none
}

/// Yang terjadi saat banner di-tap (diatur admin di web admin → Banner).
enum BannerAction: Equatable {
    case none
    case product(id: String)
    case category(id: String)
    /// Info kupon gratis ongkir mingguan.
    case freeDelivery
}
