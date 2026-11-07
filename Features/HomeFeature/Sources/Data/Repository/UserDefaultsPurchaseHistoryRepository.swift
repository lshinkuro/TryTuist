//
//  UserDefaultsPurchaseHistoryRepository.swift
//  HomeFeature · Data
//
import Foundation

struct UserDefaultsPurchaseHistoryRepository: PurchaseHistoryRepository {
    private static let key = "home.purchaseHistory"

    var defaults: UserDefaults = .standard

    func load() -> [PurchaseRecord] {
        defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([PurchaseRecord].self, from: $0) } ?? []
    }

    func save(_ records: [PurchaseRecord]) {
        defaults.set(try? JSONEncoder().encode(records), forKey: Self.key)
    }
}
