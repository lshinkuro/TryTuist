//
//  DebuggerStore.swift
//  Debugger · Presentation
//
//  Store root Debugger: tab aktif, info layar (Layar), shortcut (Navigasi).
//  Tab API & Server punya Store sendiri yang dirakit di sini.
//
import SwiftUI
import UIKit
import Navigation
import NetworkManager
import TTUI
import Utility

enum DebuggerTab: String, CaseIterable, Identifiable {
    case network
    case screens
    case navigation
    case server

    var id: String { rawValue }

    var title: String {
        switch self {
        case .network: return "API"
        case .screens: return "Layar"
        case .navigation: return "Navigasi"
        case .server: return "Server"
        }
    }

    var systemImage: String {
        switch self {
        case .network: return "network"
        case .screens: return "rectangle.stack"
        case .navigation: return "arrow.triangle.turn.up.right.diamond"
        case .server: return "server.rack"
        }
    }
}

struct InfoRow: Identifiable, Equatable {
    var id: String { title }
    let title: String
    let value: String
    /// Nilai yang disalin saat baris ditekan (bisa beda dari yang ditampilkan, mis. token asli).
    var copyValue: String?
}

struct DebuggerState: Equatable {
    var selectedTab: DebuggerTab = .network
    let hierarchy: [ScreenNode]
    var history: [ScreenVisit] = []
    let info: [InfoRow]
    var toast: ToastMessage?

    var currentScreen: String {
        hierarchy.last(where: \.isVisible)?.name ?? "-"
    }

    var environmentBadge: String {
        let active = AppEnvironment.current.displayName
        return AppEnvironment.isOverridden ? "\(active) · override" : active
    }
}

enum DebuggerAction {
    case tabSelected(DebuggerTab)
    case historyUpdated([ScreenVisit])
    case clearHistoryTapped
    case copyTapped(InfoRow)
    case shortcutTapped(DebugShortcut)
    case closeTapped
    case toastDismissed(UUID)
}

enum DebuggerRoute {
    case close
    case run(DebugShortcut)
    case serverChanged
}

final class DebuggerStore: Store<DebuggerState, DebuggerAction> {
    let network: NetworkLogStore
    let server: ServerStore
    /// Bukan bagian State karena berisi closure; daftarnya tetap selama Debugger terbuka.
    let shortcuts: [DebugShortcutSection]
    var onRoute: ((DebuggerRoute) -> Void)?

    private let clearHistory: @MainActor () -> Void

    init(hierarchy: [ScreenNode],
         shortcuts: [DebugShortcutSection],
         tracker: ScreenTracker = .shared,
         inspector: NetworkInspector = .shared) {
        self.network = NetworkLogStore(inspector: inspector)
        self.server = ServerStore()
        self.shortcuts = shortcuts
        self.clearHistory = { tracker.clear() }
        super.init(initialState: DebuggerState(hierarchy: hierarchy, info: Self.makeInfo()))

        server.onRoute = { [weak self] route in
            switch route {
            case .applied: self?.onRoute?(.serverChanged)
            }
        }
        bind(tracker.$history) { .historyUpdated($0) }
    }

    override func reduce(state: inout DebuggerState, action: DebuggerAction) -> Effect<DebuggerAction>? {
        switch action {
        case .tabSelected(let tab):
            state.selectedTab = tab
            return nil

        case .historyUpdated(let history):
            state.history = history
            return nil

        case .clearHistoryTapped:
            let clearHistory = self.clearHistory
            return .run { clearHistory() }

        case .copyTapped(let row):
            let toast = ToastMessage("\(row.title) disalin", systemImage: "doc.on.doc.fill")
            state.toast = toast
            return copyEffect(row.copyValue ?? row.value, toastID: toast.id) { .toastDismissed($0) }

        case .shortcutTapped(let shortcut):
            return .run { [weak self] in self?.onRoute?(.run(shortcut)) }

        case .closeTapped:
            return .run { [weak self] in self?.onRoute?(.close) }

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    // MARK: - Info app

    private static func makeInfo() -> [InfoRow] {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        let device = UIDevice.current
        let token = TokenStorage.token

        return [
            InfoRow(title: "Build scheme", value: AppEnvironment.build.displayName),
            InfoRow(title: "API aktif", value: AppEnvironment.current.displayName
                    + (AppEnvironment.isOverridden ? " (override)" : "")),
            InfoRow(title: "Base URL", value: AppEnvironment.apiBaseURL),
            InfoRow(title: "API key", value: mask(AppEnvironment.apiKey), copyValue: AppEnvironment.apiKey),
            InfoRow(title: "Data", value: AppEnvironment.useMockData ? "Mock" : "API"),
            InfoRow(title: "Token login", value: token.map { mask($0) } ?? "Tidak ada", copyValue: token ?? ""),
            InfoRow(title: "Versi", value: "\(version) (\(build))"),
            InfoRow(title: "Bundle ID", value: bundle.bundleIdentifier ?? "-"),
            InfoRow(title: "Device", value: "\(device.model) · \(device.systemName) \(device.systemVersion)")
        ]
    }

    private static func mask(_ value: String) -> String {
        guard !value.isEmpty else { return "-" }
        return value.count > 10 ? String(value.prefix(10)) + "…" : "••••"
    }
}
