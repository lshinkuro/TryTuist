//
//  DebugShortcut.swift
//  Debugger
//
//  Shortcut navigasi yang disediakan app (AppRouter) untuk tab "Navigasi".
//  `action` dijalankan SETELAH Debugger tertutup.
//
import Foundation

public struct DebugShortcut: Identifiable {
    public enum Role {
        case normal
        case destructive
    }

    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let systemImage: String
    public let role: Role
    public let action: @MainActor () -> Void

    public init(_ title: String,
                subtitle: String? = nil,
                systemImage: String,
                role: Role = .normal,
                action: @escaping @MainActor () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }
}

public struct DebugShortcutSection: Identifiable {
    public let id = UUID()
    public let title: String
    public let footer: String?
    public let items: [DebugShortcut]

    public init(_ title: String, footer: String? = nil, items: [DebugShortcut]) {
        self.title = title
        self.footer = footer
        self.items = items
    }
}
