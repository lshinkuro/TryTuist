//
//  LocationRepositories.swift
//  HomeFeature · Domain
//
import Combine
import Foundation

/// Lokasi perangkat (CoreLocation di layer Data).
@MainActor
protocol LocationService: AnyObject {
    var permission: LocationPermission { get }
    /// Tampilkan dialog izin bila belum pernah ditanya. Mengembalikan status terbaru.
    func requestPermission() async -> LocationPermission
    func currentLocation() async throws -> GeoPoint
    /// Mis. "Jl. Sultan Iskandar Muda, Kebayoran Lama". `nil` bila gagal.
    func describe(_ point: GeoPoint) async -> String?
}

/// "Antar ke" yang dipilih di Beranda. Bersama untuk Beranda & Keranjang, diingat antar-launch.
@MainActor
protocol DeliveryLocationRepository: AnyObject {
    var selected: DeliveryLocation? { get }
    var selectedPublisher: AnyPublisher<DeliveryLocation?, Never> { get }
    /// Sumber yang terakhir dipilih (tetap ada walau detail alamat belum dimuat).
    var savedSource: DeliveryLocation.Source? { get }
    /// Dialog izin lokasi sudah pernah ditawarkan di Beranda.
    var didOfferLocationPermission: Bool { get set }

    func select(_ location: DeliveryLocation)
}
