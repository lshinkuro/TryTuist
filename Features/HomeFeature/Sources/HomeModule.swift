//
//  HomeModule.swift
//  HomeFeature
//
//  Feature katalog F&B punya dua pintu masuk (tab): Beranda & Menu.
//  Keduanya berbagi CatalogContainer (repository + keranjang) dan CatalogFlow (routing).
//
import SwiftUI
import Navigation

@MainActor
public final class HomeModule: TabFeature {
    public let tabItem = TabItem(title: "Beranda", systemImage: "house", selectedSystemImage: "house.fill")
    private var flow: CatalogFlow?

    public init() {}

    public func start(router: Router) {
        let flow = CatalogFlow(router: router)
        self.flow = flow
        router.setRoot(flow.makeHome(), hidesNavigationBar: true)
    }
}

@MainActor
public final class MenuModule: TabFeature {
    public let tabItem = TabItem(title: "Menu", systemImage: "menucard", selectedSystemImage: "menucard.fill")
    private var flow: CatalogFlow?

    public init() {}

    public func start(router: Router) {
        let flow = CatalogFlow(router: router)
        self.flow = flow
        router.setRoot(flow.makeMenu(isRootScreen: true), hidesNavigationBar: true)
    }
}
