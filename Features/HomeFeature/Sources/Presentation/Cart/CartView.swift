//
//  CartView.swift
//  HomeFeature · Presentation
//
import SwiftUI
import TTUI

struct CartView: View {
    @StateObject private var store: CartStore

    init(store: CartStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: CartState { store.state }

    var body: some View {
        Group {
            if let order = state.placedOrder {
                OrderPlacedView(order: order) { store.send(.closeTapped) }
            } else if state.items.isEmpty {
                ContentUnavailableView {
                    Label("Keranjang kosong", systemImage: "bag")
                } description: {
                    Text("Yuk pilih makanan & minuman favoritmu dulu.")
                } actions: {
                    Button("Lihat Menu") { store.send(.closeTapped) }
                        .buttonStyle(CapsuleButtonStyle(.filled))
                }
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Tutup") { store.send(.closeTapped) }
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: 0) {
                    ForEach(state.items) { item in
                        CartItemRow(
                            item: item,
                            onIncrement: { store.send(.incrementTapped(item)) },
                            onDecrement: { store.send(.decrementTapped(item)) }
                        )
                        if item.id != state.items.last?.id {
                            Divider().padding(.leading, 88)
                        }
                    }
                }
                .formCard()

                VStack(spacing: Spacing.m) {
                    summaryRow("Subtotal (\(state.itemCount) item)", state.subtotal.rupiahFormatted)
                    summaryRow("Ongkos kirim", state.deliveryFee.rupiahFormatted)
                    Divider()
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(state.total.rupiahFormatted)
                            .font(.title3.bold())
                            .foregroundStyle(Color.brand)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: state.total)
                    }
                }
                .padding(Spacing.l)
                .formCard()

                if let error = state.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton("Pesan Sekarang · \(state.total.rupiahFormatted)",
                          isLoading: state.isCheckingOut,
                          isEnabled: state.canCheckout) {
                store.send(.checkoutTapped)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(.bar)
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

private struct CartItemRow: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Color.clear
                .frame(width: 64, height: 64)
                .overlay { RemoteImage(url: item.product.imageURL) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.subheadline.weight(.semibold))
                if let option = item.option {
                    Text(option.name).font(.caption).foregroundStyle(.secondary)
                }
                if !item.note.isEmpty {
                    Label(item.note, systemImage: "note.text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(item.subtotal.rupiahFormatted)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.brand)
            }

            Spacer(minLength: Spacing.s)

            HStack(spacing: Spacing.m) {
                Button(action: onDecrement) {
                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                        .frame(width: 30, height: 30)
                        .background(Color.brandSoft, in: Circle())
                }
                .accessibilityLabel(item.quantity == 1 ? "Hapus" : "Kurangi")
                Text("\(item.quantity)")
                    .font(.subheadline.bold())
                    .frame(minWidth: 18)
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .frame(width: 30, height: 30)
                        .background(Color.brandSoft, in: Circle())
                }
                .accessibilityLabel("Tambah")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.brand)
            .buttonStyle(.plain)
        }
        .padding(Spacing.m)
    }
}

private struct OrderPlacedView: View {
    let order: PlacedOrder
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: order.orderNumber)
            VStack(spacing: Spacing.s) {
                Text("Pesanan diterima! 🎉")
                    .font(.title2.bold())
                Text("No. pesanan \(order.orderNumber)\nTotal \(order.total.rupiahFormatted)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PrimaryButton("Selesai", action: onDone)
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
        }
    }
}
