//
//  ScreensView.swift
//  Debugger · Presentation
//
//  Tab "Layar": screen yang sedang tampil, hierarki navigasi, riwayat, dan info app.
//  State-nya ada di DebuggerStore.
//
import SwiftUI
import Navigation
import TTUI

struct ScreensView: View {
    @ObservedObject var store: DebuggerStore
    let onClose: () -> Void

    private var state: DebuggerState { store.state }

    var body: some View {
        NavigationStack {
            List {
                currentSection
                hierarchySection
                historySection
                infoSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Layar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { DebugToolbar(onClose: onClose) }
        }
    }

    private var currentSection: some View {
        Section {
            HStack(spacing: Spacing.m) {
                IconBadge(systemImage: "iphone", size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sedang dibuka")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(state.currentScreen)
                        .font(.system(.headline, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var hierarchySection: some View {
        Section {
            if state.hierarchy.isEmpty {
                Text("Hierarki tidak terbaca").foregroundStyle(.secondary)
            }
            ForEach(state.hierarchy) { node in
                HStack(spacing: Spacing.s) {
                    Image(systemName: icon(for: node.kind))
                        .foregroundStyle(node.isVisible ? Color.brand : .secondary)
                        .frame(width: 20)
                    Text(node.name)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(node.isVisible ? .bold : .regular)
                    Spacer()
                    if node.isVisible {
                        Text("TAMPIL")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(Color.brand)
                    }
                }
                .padding(.leading, indent(for: node.kind))
            }
        } header: {
            Text("Hierarki navigasi")
        } footer: {
            Text("Dibaca dari window saat device di-shake: tab aktif → stack → modal.")
        }
    }

    private var historySection: some View {
        Section {
            if state.history.isEmpty {
                Text("Belum ada riwayat").foregroundStyle(.secondary)
            }
            ForEach(state.history.prefix(20)) { visit in
                HStack {
                    Text(visit.name)
                        .font(.system(.subheadline, design: .monospaced))
                    Spacer()
                    Text(visit.date, format: .dateTime.hour().minute().second())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if !state.history.isEmpty {
                Button("Hapus riwayat", role: .destructive) { store.send(.clearHistoryTapped) }
            }
        } header: {
            Text("Riwayat layar")
        }
    }

    private var infoSection: some View {
        Section {
            ForEach(state.info) { row in
                Button {
                    store.send(.copyTapped(row))
                } label: {
                    LabeledContent(row.title) {
                        Text(row.value)
                            .font(.system(.footnote, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                    }
                }
                .tint(.primary)
            }
        } header: {
            Text("Info app")
        } footer: {
            Text("Ketuk baris untuk menyalin nilainya.")
        }
    }

    private func icon(for kind: ScreenNode.Kind) -> String {
        switch kind {
        case .window: return "macwindow"
        case .tab: return "square.grid.2x2"
        case .stack(let depth): return depth == 0 ? "rectangle.portrait" : "arrow.turn.down.right"
        case .modal: return "rectangle.bottomhalf.inset.filled"
        }
    }

    private func indent(for kind: ScreenNode.Kind) -> CGFloat {
        switch kind {
        case .window, .tab, .modal: return 0
        case .stack(let depth): return CGFloat(min(depth, 4)) * 12
        }
    }
}
