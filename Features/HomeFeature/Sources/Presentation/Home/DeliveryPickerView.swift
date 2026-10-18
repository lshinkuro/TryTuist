//
//  DeliveryPickerView.swift
//  HomeFeature · Presentation
//
//  Sheet "Antar ke": lokasi saat ini, alamat tersimpan (dari Profil), kelola alamat.
//  Pilihan menentukan outlet terdekat; alamat tersimpan juga jadi default di Keranjang.
//
import SwiftUI
import TTUI

struct DeliveryPickerView: View {
    let choice: DeliveryChoice
    let permission: LocationPermission?
    let isUpdating: Bool
    let onUseCurrentLocation: () -> Void
    let onSelectAddress: (CheckoutAddress) -> Void
    let onManageAddresses: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: onUseCurrentLocation) {
                        row(systemImage: "location.fill",
                            title: "Gunakan lokasi saat ini",
                            subtitle: currentLocationSubtitle,
                            isSelected: choice.selected?.source == .currentLocation,
                            showsProgress: isUpdating)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUpdating)

                    if permission == .denied {
                        Button("Buka Pengaturan untuk izinkan lokasi", action: onOpenSettings)
                            .font(.subheadline.weight(.semibold))
                    }
                } footer: {
                    Text("Lokasi dipakai untuk mencari outlet terdekat. Untuk checkout tetap pilih alamat lengkap.")
                }

                Section("Alamat tersimpan") {
                    if choice.addresses.isEmpty {
                        Text("Belum ada alamat. Tambahkan supaya kurir tahu persis tujuanmu.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(choice.addresses) { address in
                        Button { onSelectAddress(address) } label: {
                            row(systemImage: "mappin.circle.fill",
                                title: address.label + (address.isDefault ? " · Utama" : ""),
                                subtitle: address.address,
                                isSelected: address.id == choice.selected?.savedAddressID,
                                showsProgress: false)
                        }
                        .buttonStyle(.plain)
                        .disabled(isUpdating)
                    }
                    Button(action: onManageAddresses) {
                        Label("Tambah / kelola alamat", systemImage: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .navigationTitle("Antar ke")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var currentLocationSubtitle: String {
        if choice.selected?.source == .currentLocation, let subtitle = choice.selected?.subtitle {
            return subtitle
        }
        switch permission {
        case .denied?: return "Izin lokasi dimatikan"
        default: return "Cari outlet terdekat dari posisimu"
        }
    }

    private func row(systemImage: String, title: String, subtitle: String, isSelected: Bool, showsProgress: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if showsProgress {
                ProgressView()
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.brand)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
