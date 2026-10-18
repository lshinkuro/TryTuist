//
//  CoreLocationService.swift
//  HomeFeature · Data
//
//  CLLocationManager (izin When In Use + satu kali ambil lokasi) dan CLGeocoder (nama jalan).
//  Info.plist wajib punya NSLocationWhenInUseUsageDescription.
//
import CoreLocation
import Foundation

@MainActor
final class CoreLocationService: NSObject, LocationService, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var permissionContinuations: [CheckedContinuation<LocationPermission, Never>] = []
    private var locationContinuations: [CheckedContinuation<GeoPoint, Error>] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var permission: LocationPermission { Self.map(manager.authorizationStatus) }

    nonisolated private static func map(_ status: CLAuthorizationStatus) -> LocationPermission {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        default: return .denied
        }
    }

    func requestPermission() async -> LocationPermission {
        guard permission == .notDetermined else { return permission }
        return await withCheckedContinuation { continuation in
            permissionContinuations.append(continuation)
            manager.requestWhenInUseAuthorization()
        }
    }

    func currentLocation() async throws -> GeoPoint {
        switch await requestPermission() {
        case .authorized: break
        case .denied, .notDetermined: throw LocationError.denied
        }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuations.append(continuation)
            if locationContinuations.count == 1 { manager.requestLocation() }
        }
    }

    func describe(_ point: GeoPoint) async -> String? {
        let location = CLLocation(latitude: point.lat, longitude: point.lng)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "id_ID")).first
        else { return nil }
        let parts = [placemark.thoroughfare ?? placemark.name, placemark.subLocality ?? placemark.locality]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = Self.map(manager.authorizationStatus)
        Task { @MainActor in
            guard status != .notDetermined else { return }
            let waiting = self.permissionContinuations
            self.permissionContinuations.removeAll()
            waiting.forEach { $0.resume(returning: status) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let point = GeoPoint(lat: last.coordinate.latitude, lng: last.coordinate.longitude)
        Task { @MainActor in
            let waiting = self.locationContinuations
            self.locationContinuations.removeAll()
            waiting.forEach { $0.resume(returning: point) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        Task { @MainActor in
            let waiting = self.locationContinuations
            self.locationContinuations.removeAll()
            waiting.forEach { $0.resume(throwing: denied ? LocationError.denied : LocationError.unavailable) }
        }
    }
}
