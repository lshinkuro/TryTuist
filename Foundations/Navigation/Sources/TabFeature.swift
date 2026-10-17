//
//  TabFeature.swift
//  Navigation
//
//  Kontrak untuk feature yang tampil sebagai tab. Menggantikan
//  *Dependency + *Coordinatorable + MainTabBarType.
//
import UIKit

public struct TabItem {
    public let title: String
    public let systemImage: String
    public let selectedSystemImage: String

    public init(title: String, systemImage: String, selectedSystemImage: String) {
        self.title = title
        self.systemImage = systemImage
        self.selectedSystemImage = selectedSystemImage
    }
}

@MainActor
public protocol TabFeature: AnyObject {
    var tabItem: TabItem { get }
    /// Pasang root screen tab ini ke `router`. Navigasi lanjutan (push/present) juga lewat router ini.
    func start(router: Router)
}
