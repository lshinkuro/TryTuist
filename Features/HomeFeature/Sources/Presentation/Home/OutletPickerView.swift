//
//  OutletPickerView.swift
//  HomeFeature · Presentation
//
//  Sheet "Pilih outlet". Harga sama di semua outlet; yang berbeda stok, jam buka & jangkauan antar.
//
import SwiftUI
import TTUI

struct OutletPickerView: View {
    let choice: OutletChoice
    let switchingOutletID: String?
    let onSelect: (Outlet) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(choice.outlets) { outlet in
                        Button { onSelect(outlet) } label: { row(outlet) }
                            .buttonStyle(.plain)
                            .disabled(switchingOutletID != nil)
                    }
                } footer: {
                    Text("Harga menu sama di semua outlet. Menu yang habis di outlet baru akan dikeluarkan dari keranjang.")
                }
            }
            .navigationTitle("Pilih Outlet")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func row(_ outlet: Outlet) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: "storefront.fill")
                .font(.title3)
                .foregroundStyle(outlet.canOrder ? Color.brand : Color.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(outlet.name)
                    .font(.subheadline.weight(.semibold))
                if !outlet.address.isEmpty {
                    Text(outlet.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text(outlet.detailText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(outlet.canOrder ? Color.green : Color.orange)
                if !outlet.isOpenNow, let note = outlet.closedNote {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if switchingOutletID == outlet.id {
                ProgressView()
            } else if outlet.id == choice.selected?.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.brand)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .opacity(outlet.canOrder || outlet.id == choice.selected?.id ? 1 : 0.7)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(outlet.id == choice.selected?.id ? .isSelected : [])
    }
}
