//
//  ServerView.swift
//  Debugger · Presentation
//
import SwiftUI
import TTUI
import Utility

struct ServerView: View {
    @ObservedObject var store: ServerStore
    let onClose: () -> Void

    private var state: ServerState { store.state }

    var body: some View {
        NavigationStack {
            Form {
                activeSection
                selectionSection
                detailSection
                applySection
            }
            .navigationTitle("Server API")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { DebugToolbar(onClose: onClose) }
            .confirmationDialog("Terapkan server baru?",
                                isPresented: store.binding(\.isConfirmingApply, send: { .applyDialogChanged($0) }),
                                titleVisibility: .visible) {
                Button("Terapkan & restart") { store.send(.applyConfirmed) }
                Button("Batal", role: .cancel) {}
            } message: {
                Text("Sesi login & keranjang dihapus, lalu app kembali ke Splash memakai server baru.")
            }
        }
    }

    // MARK: - Sections

    private var activeSection: some View {
        Section {
            LabeledContent("Scheme build", value: AppEnvironment.build.displayName)
            LabeledContent("Aktif") {
                HStack(spacing: 6) {
                    EnvironmentBadge()
                    if AppEnvironment.isOverridden {
                        Text("override").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            LabeledContent("Base URL") {
                Text(AppEnvironment.useMockData ? "Mock (tanpa network)" : AppEnvironment.apiBaseURL)
                    .font(.system(.footnote, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Sedang dipakai")
        }
    }

    private var selectionSection: some View {
        Section {
            Picker("Server", selection: store.binding(\.selection, send: { .selectionChanged($0) })) {
                Text("Bawaan build (\(AppEnvironment.build.displayName))").tag(ServerSelection.build)
                ForEach(state.presets) { preset in
                    Text(preset.title).tag(ServerSelection.preset(preset.id))
                }
                Text("Custom URL").tag(ServerSelection.custom)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Pilih server")
        } footer: {
            Text("Untuk device fisik, pilih Custom lalu isi IP Mac di jaringan yang sama, mis. http://192.168.1.10:8080.")
        }
    }

    private var detailSection: some View {
        Section {
            Picker("Environment", selection: store.binding(\.environment, send: { .environmentChanged($0) })) {
                ForEach(AppEnvironment.allCases, id: \.self) { env in
                    Text(env.displayName).tag(env)
                }
            }
            .disabled(!state.isEditable)

            VStack(alignment: .leading, spacing: 4) {
                Text("Base URL").font(.caption).foregroundStyle(.secondary)
                TextField("http://localhost:8080",
                          text: store.binding(\.baseURL, send: { .baseURLChanged($0) }))
                    .font(.system(.body, design: .monospaced))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!state.isEditable)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API key (X-API-Key)").font(.caption).foregroundStyle(.secondary)
                TextField("api-key",
                          text: store.binding(\.apiKey, send: { .apiKeyChanged($0) }))
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(!state.isEditable)
            }

            Toggle("Pakai mock data", isOn: store.binding(\.useMockData, send: { .mockToggled($0) }))

            if let message = state.validationMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                store.send(.pingTapped)
            } label: {
                HStack {
                    Label("Cek koneksi (/healthz)", systemImage: "bolt.horizontal.circle")
                    Spacer()
                    if state.isPinging { ProgressView() }
                }
            }
            .disabled(state.isPinging || state.useMockData)

            if let result = state.pingResult {
                Label(result.message, systemImage: result.isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(result.isSuccess ? Color.green : Color.red)
            }
        } header: {
            Text("Detail")
        } footer: {
            if !state.isEditable {
                Text("Pilih Custom URL untuk mengubah environment, URL, atau API key.")
            }
        }
    }

    private var applySection: some View {
        Section {
            Button {
                store.send(.applyTapped)
            } label: {
                Text("Terapkan")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .disabled(!state.hasChanges)
        } footer: {
            Text(state.hasChanges
                 ? "Perubahan disimpan di device ini & tetap dipakai sampai diganti. Diabaikan di build Prod."
                 : "Belum ada perubahan.")
        }
    }
}
