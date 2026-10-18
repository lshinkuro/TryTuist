//
//  DeliveryLocationUseCases.swift
//  HomeFeature · Domain
//
//  "Antar ke" di Beranda. Urutan pilihan saat Beranda dimuat:
//  1. pilihan terakhir user (alamat tersimpan yang masih ada / lokasi saat ini),
//  2. alamat utama,
//  3. lokasi perangkat (bila izin sudah diberikan — tidak memunculkan dialog).
//
import Foundation

@MainActor
struct ResolveDeliveryLocationUseCase {
    let checkoutOptions: CheckoutOptionsRepository
    let delivery: DeliveryLocationRepository
    let location: LocationService

    func execute() async -> DeliveryChoice {
        // Alamat butuh login; gagal = lanjut tanpa alamat tersimpan.
        let addresses = (try? await checkoutOptions.options())?.addresses ?? []
        var chosen: DeliveryLocation?
        switch delivery.savedSource {
        case .savedAddress(let id)?:
            chosen = addresses.first { $0.id == id }.map(DeliveryLocation.saved)
        case .currentLocation?:
            chosen = await CurrentDeliveryLocation.fetch(location, prompt: false)
        case nil:
            break
        }
        if chosen == nil, let address = addresses.first(where: \.isDefault) ?? addresses.first {
            chosen = .saved(address)
        }
        if chosen == nil {
            chosen = await CurrentDeliveryLocation.fetch(location, prompt: false)
        }
        if let chosen { delivery.select(chosen) }
        return DeliveryChoice(selected: chosen, addresses: addresses)
    }
}

/// Lokasi perangkat → `DeliveryLocation` ("Lokasi saat ini · Jl. …").
enum CurrentDeliveryLocation {
    @MainActor
    static func fetch(_ location: LocationService, prompt: Bool) async -> DeliveryLocation? {
        try? await fetchOrThrow(location, prompt: prompt)
    }

    @MainActor
    static func fetchOrThrow(_ location: LocationService, prompt: Bool) async throws -> DeliveryLocation {
        if !prompt, location.permission != .authorized { throw LocationError.denied }
        let point = try await location.currentLocation()
        let name = await location.describe(point)
        return DeliveryLocation(source: .currentLocation, title: "Lokasi saat ini",
                                subtitle: name ?? "Sekitar lokasimu", point: point)
    }
}

/// Tombol "Gunakan lokasi saat ini": minta izin bila perlu, lalu ambil lokasi.
@MainActor
struct UseCurrentLocationUseCase {
    let location: LocationService

    func execute() async throws -> DeliveryLocation {
        do {
            return try await CurrentDeliveryLocation.fetchOrThrow(location, prompt: true)
        } catch let error as LocationError {
            throw error
        } catch {
            throw LocationError.unavailable
        }
    }
}

/// Ganti "Antar ke" → outlet terbaik untuk titik baru (buka → menjangkau → terdekat).
/// Bila outletnya berubah, menu yang habis di outlet baru dikeluarkan dari keranjang (nama dikembalikan).
@MainActor
struct ChangeDeliveryLocationUseCase {
    let repository: CatalogRepository
    let delivery: DeliveryLocationRepository
    let outlets: OutletSelectionRepository
    let changeOutlet: ChangeOutletUseCase

    func execute(_ location: DeliveryLocation) async throws -> [String] {
        delivery.select(location)
        guard let best = try? await repository.fetchOutlets(near: location.point).first,
              best.id != outlets.selected?.id else { return [] }
        return try await changeOutlet.execute(best)
    }
}

/// Dialog izin lokasi ditawarkan sekali, saat Beranda pertama kali tampil setelah login.
@MainActor
struct OfferLocationPermissionUseCase {
    let location: LocationService
    let delivery: DeliveryLocationRepository

    /// `nil` = tidak ditawarkan (sudah pernah / izin sudah diputuskan).
    func execute() async -> LocationPermission? {
        guard !delivery.didOfferLocationPermission, location.permission == .notDetermined else { return nil }
        delivery.didOfferLocationPermission = true
        return await location.requestPermission()
    }
}
