//
//  ProfileModule.swift
//  ProfileFeature
//
//  Composition root + routing tab Profil.
//
import SwiftUI
import Navigation

@MainActor
public final class ProfileModule: TabFeature {
    public let tabItem = TabItem(title: "Profil", systemImage: "person", selectedSystemImage: "person.fill")
    private let onLogout: () -> Void

    public init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
    }

    public func start(router: Router) {
        let store = ProfileStore()
        store.onRoute = { [weak self, weak router] route in
            switch route {
            case .setting(let item):
                router?.push(SettingDetailView(item: item), title: item.title)
            case .loggedOut:
                self?.onLogout()
            }
        }
        router.setRoot(ProfileView(store: store), hidesNavigationBar: true)
    }
}
