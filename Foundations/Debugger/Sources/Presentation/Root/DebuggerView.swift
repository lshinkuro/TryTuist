//
//  DebuggerView.swift
//  Debugger · Presentation
//
import SwiftUI
import TTUI
import Utility

struct DebuggerView: View {
    @StateObject private var store: DebuggerStore

    init(store: DebuggerStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        TabView(selection: store.binding(\.selectedTab, send: { .tabSelected($0) })) {
            NetworkLogView(store: store.network, onClose: close)
                .tabItem { Label(DebuggerTab.network.title, systemImage: DebuggerTab.network.systemImage) }
                .tag(DebuggerTab.network)

            ScreensView(store: store, onClose: close)
                .tabItem { Label(DebuggerTab.screens.title, systemImage: DebuggerTab.screens.systemImage) }
                .tag(DebuggerTab.screens)

            ShortcutsView(store: store, onClose: close)
                .tabItem { Label(DebuggerTab.navigation.title, systemImage: DebuggerTab.navigation.systemImage) }
                .tag(DebuggerTab.navigation)

            ServerView(store: store.server, onClose: close)
                .tabItem { Label(DebuggerTab.server.title, systemImage: DebuggerTab.server.systemImage) }
                .tag(DebuggerTab.server)
        }
        .tint(.brand)
        .toast(store.state.toast)
    }

    private func close() {
        store.send(.closeTapped)
    }
}

// MARK: - Komponen bersama

/// Toolbar standar tiap tab: badge environment + tombol tutup.
struct DebugToolbar: ToolbarContent {
    let onClose: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            EnvironmentBadge()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("Tutup", action: onClose)
                .fontWeight(.semibold)
        }
    }
}

struct EnvironmentBadge: View {
    var body: some View {
        let env = AppEnvironment.current
        HStack(spacing: 4) {
            Image(systemName: AppEnvironment.isOverridden ? "arrow.triangle.swap" : "hammer.fill")
            Text(env.displayName)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color(for: env), in: Capsule())
        .accessibilityLabel("Environment \(env.displayName)")
    }

    private func color(for env: AppEnvironment) -> Color {
        switch env {
        case .dev: return .green
        case .staging: return .orange
        case .prod: return .red
        }
    }
}

/// Teks monospace yang bisa diseleksi, untuk JSON / header / cURL.
struct CodeBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
            .background(Color.fieldBackground, in: RoundedRectangle(cornerRadius: 10))
    }
}
