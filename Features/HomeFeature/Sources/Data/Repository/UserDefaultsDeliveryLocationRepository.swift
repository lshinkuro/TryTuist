//
//  UserDefaultsDeliveryLocationRepository.swift
//  HomeFeature · Data
//
//  Disimpan hanya sumbernya ("address:<id>" / "current"); detail selalu dimuat ulang.
//
import Combine
import Foundation

@MainActor
final class UserDefaultsDeliveryLocationRepository: DeliveryLocationRepository {
    private static let sourceKey = "home.deliverySource"
    private static let offeredKey = "home.didOfferLocationPermission"
    private let defaults: UserDefaults
    private let subject = CurrentValueSubject<DeliveryLocation?, Never>(nil)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selected: DeliveryLocation? { subject.value }
    var selectedPublisher: AnyPublisher<DeliveryLocation?, Never> { subject.eraseToAnyPublisher() }

    var savedSource: DeliveryLocation.Source? {
        if let selected = subject.value { return selected.source }
        guard let raw = defaults.string(forKey: Self.sourceKey) else { return nil }
        if raw == "current" { return .currentLocation }
        if raw.hasPrefix("address:") { return .savedAddress(id: String(raw.dropFirst("address:".count))) }
        return nil
    }

    var didOfferLocationPermission: Bool {
        get { defaults.bool(forKey: Self.offeredKey) }
        set { defaults.set(newValue, forKey: Self.offeredKey) }
    }

    func select(_ location: DeliveryLocation) {
        switch location.source {
        case .savedAddress(let id): defaults.set("address:\(id)", forKey: Self.sourceKey)
        case .currentLocation: defaults.set("current", forKey: Self.sourceKey)
        }
        if subject.value != location { subject.send(location) }
    }
}
