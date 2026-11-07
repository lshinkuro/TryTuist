//
//  ShoppingPreferencesView.swift
//  HomeFeature · Presentation
//
//  Sheet "Preferensi belanja" untuk saran AI di Beranda.
//
import SwiftUI
import TTUI

struct ShoppingPreferencesView: View {
    @State private var draft: ShoppingPreferences
    @Environment(\.dismiss) private var dismiss
    let onSave: (ShoppingPreferences) -> Void

    init(preferences: ShoppingPreferences, onSave: @escaping (ShoppingPreferences) -> Void) {
        _draft = State(initialValue: preferences)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kamu suka apa?") {
                    TextField("Contoh: pedas, kopi, camilan sehat", text: $draft.likes, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    TextField("Contoh: masak untuk 4 orang, belanja bulanan hemat", text: $draft.needs, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Lagi butuh apa?")
                } footer: {
                    Text("Disimpan di perangkat ini saja dan diproses Apple Intelligence di perangkatmu.")
                }
            }
            .navigationTitle("Preferensi Belanja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") { onSave(draft) }
                }
            }
        }
    }
}
