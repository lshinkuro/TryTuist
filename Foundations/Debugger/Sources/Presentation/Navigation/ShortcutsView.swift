//
//  ShortcutsView.swift
//  Debugger · Presentation
//
//  Tab "Navigasi": lompat langsung ke fitur. Daftarnya disediakan AppRouter
//  lewat `DebugMenu.shared.shortcutsProvider`. Action jalan setelah Debugger tertutup.
//
import SwiftUI
import TTUI

struct ShortcutsView: View {
    @ObservedObject var store: DebuggerStore
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if store.shortcuts.isEmpty {
                    Text("Belum ada shortcut. Isi `DebugMenu.shared.shortcutsProvider` di AppRouter.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.shortcuts) { section in
                    Section {
                        ForEach(section.items) { item in
                            Button {
                                store.send(.shortcutTapped(item))
                            } label: {
                                row(item)
                            }
                        }
                    } header: {
                        Text(section.title)
                    } footer: {
                        if let footer = section.footer { Text(footer) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Navigasi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { DebugToolbar(onClose: onClose) }
        }
    }

    private func row(_ item: DebugShortcut) -> some View {
        let tint: Color = item.role == .destructive ? .red : .brand
        return HStack(spacing: Spacing.m) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .foregroundStyle(item.role == .destructive ? Color.red : Color.primary)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}
