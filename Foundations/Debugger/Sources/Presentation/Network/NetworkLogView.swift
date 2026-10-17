//
//  NetworkLogView.swift
//  Debugger · Presentation
//
import SwiftUI
import NetworkManager
import TTUI

struct NetworkLogView: View {
    @ObservedObject var store: NetworkLogStore
    let onClose: () -> Void

    private var state: NetworkLogState { store.state }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filter", selection: store.binding(\.filter, send: { .filterChanged($0) })) {
                        ForEach(NetworkFilter.allCases) { filter in
                            Text(label(for: filter)).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if state.visibleEntries.isEmpty {
                    emptyState
                } else {
                    Section {
                        ForEach(state.visibleEntries) { entry in
                            NavigationLink(value: entry.id) {
                                NetworkRow(entry: entry)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.send(.deleteTapped(entry.id))
                                } label: {
                                    Label("Hapus", systemImage: "trash")
                                }
                            }
                        }
                    } footer: {
                        Text("Menyimpan \(state.entries.count) request terakhir di memori. Geser baris untuk menghapus satu, atau ikon 🗑 untuk semua.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("API")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: store.binding(\.searchText, send: { .searchChanged($0) }),
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Cari path, method, status")
            .toolbar {
                DebugToolbar(onClose: onClose)
                // Di atas (bukan .bottomBar) karena bottom bar tertutup tab bar Debugger.
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        store.send(.clearTapped)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                    .disabled(state.entries.isEmpty)
                    .accessibilityLabel("Bersihkan log API")
                }
            }
            .navigationDestination(for: String.self) { id in
                NetworkDetailView(store: store.makeDetailStore(for: id))
            }
        }
    }

    private func label(for filter: NetworkFilter) -> String {
        switch filter {
        case .all: return "Semua (\(state.entries.count))"
        case .failed: return "Gagal (\(state.failedCount))"
        case .pending: return filter.rawValue
        }
    }

    private var emptyState: some View {
        Section {
            VStack(spacing: Spacing.s) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(state.entries.isEmpty ? "Belum ada API yang di-hit" : "Tidak ada yang cocok")
                    .font(.headline)
                Text(state.entries.isEmpty
                     ? "Buka screen yang memanggil backend, lalu shake lagi."
                     : "Ubah kata kunci atau filter.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
        }
    }
}

struct NetworkRow: View {
    let entry: NetworkEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.s) {
                MethodBadge(method: entry.method)
                StatusBadge(entry: entry)
                Spacer()
                Text(entry.startedAt, format: .dateTime.hour().minute().second())
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(entry.path + (entry.query.map { "?\($0)" } ?? ""))
                .font(.system(.subheadline, design: .monospaced).weight(.medium))
                .lineLimit(2)
            HStack(spacing: Spacing.m) {
                Text(entry.host)
                if let duration = entry.durationMs {
                    Label("\(duration) ms", systemImage: "timer")
                }
                if let size = entry.responseSize {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

struct MethodBadge: View {
    let method: String

    var body: some View {
        Text(method)
            .font(.caption2.weight(.heavy).monospaced())
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
    }

    private var color: Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PATCH", "PUT": return .orange
        case "DELETE": return .red
        default: return .gray
        }
    }
}

struct StatusBadge: View {
    let entry: NetworkEntry

    var body: some View {
        switch entry.phase {
        case .pending:
            HStack(spacing: 4) {
                ProgressView().controlSize(.mini)
                Text("…")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
        case .success, .failure:
            Text(entry.statusCode.map { String($0) } ?? "ERR")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(entry.phase == .success ? Color.green : Color.red)
        }
    }
}
