//
//  AddressListView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct AddressListView: View {
    @StateObject private var store: AddressListStore

    init(store: AddressListStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: AddressListState { store.state }

    var body: some View {
        LoadableView(state: state.addresses, retry: { store.send(.retryTapped) }) { addresses in
            if addresses.isEmpty {
                ContentUnavailableView {
                    Label("Belum ada alamat", systemImage: "location.slash")
                } description: {
                    Text("Tambahkan alamat supaya pesanan bisa diantar.")
                } actions: {
                    Button("Tambah Alamat") { store.send(.addTapped) }
                        .buttonStyle(CapsuleButtonStyle(.filled))
                }
            } else {
                list(addresses)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.send(.addTapped) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Tambah alamat")
            }
        }
        .onAppear { store.send(.onAppear) }
        .toast(state.toast)
        .confirmationDialog("Hapus alamat \(state.pendingDeletion?.label ?? "")?",
                            isPresented: store.binding(\.isConfirmingDeletion, send: { .deleteDialogChanged($0) }),
                            titleVisibility: .visible) {
            Button("Hapus", role: .destructive) { store.send(.deleteConfirmed) }
            Button("Batal", role: .cancel) {}
        }
    }

    private func list(_ addresses: [Address]) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.m) {
                ForEach(addresses) { address in
                    AddressCard(address: address,
                                isBusy: state.busyID == address.id,
                                onEdit: { store.send(.editTapped(address)) },
                                onSetDefault: { store.send(.setDefaultTapped(address)) },
                                onDelete: { store.send(.deleteTapped(address)) })
                }
            }
            .padding(Spacing.xl)
        }
        .refreshable { store.send(.retryTapped) }
    }
}

private struct AddressCard: View {
    let address: Address
    let isBusy: Bool
    let onEdit: () -> Void
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Image(systemName: icon)
                    .foregroundStyle(Color.brand)
                Text(address.label)
                    .font(.headline)
                if address.isDefault {
                    Text("Utama")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.brandSoft, in: Capsule())
                }
                Spacer()
                if isBusy {
                    ProgressView()
                } else {
                    Menu {
                        Button { onEdit() } label: { Label("Ubah", systemImage: "pencil") }
                        if !address.isDefault {
                            Button { onSetDefault() } label: { Label("Jadikan utama", systemImage: "star") }
                        }
                        Button(role: .destructive) { onDelete() } label: { Label("Hapus", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Opsi alamat \(address.label)")
                }
            }

            Text("\(address.recipient) · \(address.phone)")
                .font(.subheadline.weight(.medium))
            Text(address.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let notes = address.notes {
                Label(notes, systemImage: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .stroke(address.isDefault ? Color.brand.opacity(0.5) : .clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }

    private var icon: String {
        switch address.label.lowercased() {
        // Label tersimpan bisa bahasa Indonesia atau Inggris (saran label ikut bahasa app).
        case "rumah", "home": return "house.fill"
        case "kantor", "office": return "building.2.fill"
        case "kos", "apartemen", String(localized: "boarding house"), "apartment": return "building.fill"
        default: return "mappin.circle.fill"
        }
    }
}
