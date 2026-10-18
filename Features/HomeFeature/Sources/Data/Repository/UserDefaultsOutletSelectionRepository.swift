//
//  UserDefaultsOutletSelectionRepository.swift
//  HomeFeature · Data
//
//  Yang disimpan hanya id outlet; detail (jam buka, jarak) selalu diambil ulang dari server.
//
import Combine
import Foundation

@MainActor
final class UserDefaultsOutletSelectionRepository: OutletSelectionRepository {
    private static let key = "home.selectedOutletID"
    private let defaults: UserDefaults
    private let subject = CurrentValueSubject<Outlet?, Never>(nil)

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selected: Outlet? { subject.value }

    var savedOutletID: String? { subject.value?.id ?? defaults.string(forKey: Self.key) }

    var selectedPublisher: AnyPublisher<Outlet?, Never> { subject.eraseToAnyPublisher() }

    func select(_ outlet: Outlet) {
        defaults.set(outlet.id, forKey: Self.key)
        if subject.value != outlet { subject.send(outlet) }
    }
}
