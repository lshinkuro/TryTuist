//
//  UserDefaultsShoppingPreferencesRepository.swift
//  HomeFeature · Data
//
import Foundation

struct UserDefaultsShoppingPreferencesRepository: ShoppingPreferencesRepository {
    private static let likesKey = "home.preferences.likes"
    private static let needsKey = "home.preferences.needs"

    var defaults: UserDefaults = .standard

    func load() -> ShoppingPreferences {
        ShoppingPreferences(likes: defaults.string(forKey: Self.likesKey) ?? "",
                            needs: defaults.string(forKey: Self.needsKey) ?? "")
    }

    func save(_ preferences: ShoppingPreferences) {
        defaults.set(preferences.likes, forKey: Self.likesKey)
        defaults.set(preferences.needs, forKey: Self.needsKey)
    }
}
