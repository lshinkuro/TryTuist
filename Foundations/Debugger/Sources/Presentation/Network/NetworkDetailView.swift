//
//  NetworkDetailView.swift
//  Debugger · Presentation
//
import SwiftUI
import NetworkManager
import TTUI

struct NetworkDetailView: View {
    @StateObject private var store: NetworkDetailStore

    init(store: NetworkDetailStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        Group {
            if let entry = store.state.entry {
                content(entry)
            } else {
                ContentUnavailableView("Log tidak ditemukan", systemImage: "questionmark.folder")
            }
        }
        .navigationTitle(store.state.entry?.path ?? "Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toast(store.state.toast)
    }

    private func content(_ entry: NetworkEntry) -> some View {
        List {
            summarySection(entry)

            Section {
                Picker("Bagian", selection: store.binding(\.section, send: { .sectionChanged($0) })) {
                    ForEach(NetworkDetailSection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            switch store.state.section {
            case .request: requestSections(entry)
            case .response: responseSections(entry)
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { copy("cURL", entry.curl) } label: { Label("Salin cURL", systemImage: "terminal") }
                    Button { copy("URL", entry.url) } label: { Label("Salin URL", systemImage: "link") }
                    if let body = entry.responseBody {
                        Button { copy("Response", body) } label: { Label("Salin response", systemImage: "doc.plaintext") }
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Salin")
            }
        }
    }

    // MARK: - Sections

    private func summarySection(_ entry: NetworkEntry) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.s) {
                    MethodBadge(method: entry.method)
                    StatusBadge(entry: entry)
                    Spacer()
                }
                Text(entry.url)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)

            LabeledContent("Waktu", value: entry.startedAt.formatted(date: .omitted, time: .standard))
            LabeledContent("Durasi", value: entry.durationMs.map { "\($0) ms" } ?? "menunggu…")
            if let size = entry.responseSize {
                LabeledContent("Ukuran", value: ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary))
            }
            LabeledContent("ID", value: entry.id)
        }
    }

    @ViewBuilder
    private func requestSections(_ entry: NetworkEntry) -> some View {
        if let query = entry.query {
            Section("Query") { CodeBlock(text: query.replacingOccurrences(of: "&", with: "\n")) }
        }
        headersSection(entry.requestHeaders, footer: "Authorization, X-API-Key & password di-mask. cURL berisi nilai asli.")
        Section("Body") {
            if let body = entry.requestBody {
                CodeBlock(text: body)
            } else {
                Text("Tanpa body").foregroundStyle(.secondary)
            }
        }
        Section("cURL") {
            CodeBlock(text: entry.curl)
            Button { copy("cURL", entry.curl) } label: { Label("Salin cURL", systemImage: "terminal") }
        }
    }

    @ViewBuilder
    private func responseSections(_ entry: NetworkEntry) -> some View {
        if let error = entry.errorMessage {
            Section("Error") {
                Text(error)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
        if entry.phase == .pending {
            Section {
                HStack {
                    ProgressView()
                    Text("Menunggu response…").foregroundStyle(.secondary)
                }
            }
        } else {
            headersSection(entry.responseHeaders, footer: nil)
            Section("Body") {
                if let body = entry.responseBody {
                    CodeBlock(text: body)
                } else {
                    Text("Response kosong").foregroundStyle(.secondary)
                }
            }
        }
    }

    private func headersSection(_ headers: [NetworkEntry.Header], footer: String?) -> some View {
        Section {
            if headers.isEmpty {
                Text("Tanpa header").foregroundStyle(.secondary)
            }
            ForEach(headers, id: \.self) { header in
                VStack(alignment: .leading, spacing: 2) {
                    Text(header.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(header.value)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        } header: {
            Text("Headers")
        } footer: {
            if let footer { Text(footer) }
        }
    }

    private func copy(_ label: String, _ text: String) {
        store.send(.copyTapped(label: label, text: text))
    }
}
