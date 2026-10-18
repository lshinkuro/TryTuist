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
        .onAppear { store.send(.onAppear) }
        .sheet(item: store.binding(\.activeSheet, send: { .sheetChanged($0) })) { sheet in
            switch sheet {
            case .address:
                CheckoutOptionSheet(title: "Antar ke",
                                    manageTitle: "Tambah / kelola alamat",
                                    onManage: { store.send(.manageAddressesTapped) }) {
                    ForEach(state.addresses) { address in
                        OptionRow(title: address.label,
                                  subtitle: "\(address.recipient) · \(address.phone)\n\(address.address)",
                                  systemImage: "mappin.circle.fill",
                                  badge: address.isDefault ? "Utama" : nil,
                                  isSelected: address.id == state.selectedAddressID,
                                  isEnabled: true) {
                            store.send(.addressSelected(address.id))
                        }
                    }
                }
            case .payment:
                CheckoutOptionSheet(title: "Metode pembayaran",
                                    manageTitle: "Kelola metode pembayaran",
                                    onManage: { store.send(.managePaymentMethodsTapped) }) {
                    ForEach(state.paymentMethods) { method in
                        OptionRow(title: method.name,
                                  subtitle: method.isEnabled ? method.detail : "Sedang tidak tersedia",
                                  systemImage: method.systemImage,
                                  badge: method.isDefault ? "Utama" : nil,
                                  isSelected: method.id == state.selectedPaymentID,
                                  isEnabled: method.isEnabled) {
                            store.send(.paymentSelected(method.id))
                        }
                    }
                }
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                deliverySection

                if let outlet = state.outlet {
                    SelectionCard(title: "Dikirim dari", value: outlet.name, detail: outlet.detailText,
                                  systemImage: outlet.canOrder ? "storefront.fill" : "exclamationmark.triangle.fill",
                                  actionTitle: nil) {}
                }

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

                paymentSection

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
            VStack(spacing: Spacing.s) {
                if let hint = state.checkoutHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                PrimaryButton(state.checkoutTitle,
                              isLoading: state.isCheckingOut,
                              isEnabled: state.canCheckout) {
                    store.send(.checkoutTapped)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(.bar)
        }
    }

    // MARK: - Antar ke & Pembayaran

    @ViewBuilder
    private var deliverySection: some View {
        switch state.options {
        case .idle, .loading:
            SelectionCard(title: "Antar ke", value: "Memuat alamat…", detail: nil,
                          systemImage: "mappin.circle.fill", actionTitle: nil, isLoading: true) {}
        case .failed:
            SelectionCard(title: "Antar ke", value: "Gagal memuat alamat",
                          detail: "Pesanan tetap memakai alamat utamamu.",
                          systemImage: "exclamationmark.triangle.fill", actionTitle: "Coba lagi") {
                store.send(.retryOptionsTapped)
            }
        case .loaded:
            if let address = state.selectedAddress {
                SelectionCard(title: "Antar ke", value: "\(address.label) · \(address.recipient)",
                              detail: address.address, systemImage: "mappin.circle.fill", actionTitle: "Ganti") {
                    store.send(.sheetChanged(.address))
                }
            } else {
                SelectionCard(title: "Antar ke", value: "Belum ada alamat",
                              detail: "Tambahkan alamat di Profil supaya pesanan bisa diantar.",
                              systemImage: "mappin.slash", actionTitle: "Tambah") {
                    store.send(.manageAddressesTapped)
                }
            }
        }
    }

    @ViewBuilder
    private var paymentSection: some View {
        switch state.options {
        case .idle, .loading:
            SelectionCard(title: "Pembayaran", value: "Memuat…", detail: nil,
                          systemImage: "creditcard.fill", actionTitle: nil, isLoading: true) {}
        case .failed:
            SelectionCard(title: "Pembayaran", value: "Metode utama", detail: "Dipilih otomatis oleh server.",
                          systemImage: "creditcard.fill", actionTitle: "Coba lagi") {
                store.send(.retryOptionsTapped)
            }
        case .loaded:
            let method = state.selectedPayment
            SelectionCard(title: "Pembayaran", value: method?.name ?? "Pilih metode", detail: method?.detail,
                          systemImage: method?.systemImage ?? "creditcard.fill", actionTitle: "Ganti") {
                store.send(.sheetChanged(.payment))
            }
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
                Text(order.paidVia == nil ? "Pesanan diterima! 🎉" : "Pembayaran berhasil! 🎉")
                    .font(.title2.bold())
                Text("No. pesanan \(order.orderNumber)\nTotal \(order.total.rupiahFormatted)" + (order.paidVia.map { "\n\($0)" } ?? ""))
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

/// Kartu "Antar ke" / "Pembayaran" di Keranjang.
private struct SelectionCard: View {
    let title: String
    let value: String
    let detail: String?
    let systemImage: String
    let actionTitle: String?
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.m) {
                IconBadge(systemImage: systemImage, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: Spacing.s)
                if isLoading {
                    ProgressView()
                } else if let actionTitle {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brand)
                }
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading || actionTitle == nil)
        .formCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint(actionTitle.map { "Ketuk untuk \($0.lowercased())" } ?? "")
    }
}

/// Sheet daftar pilihan (alamat / metode bayar) + tombol kelola di tab Profil.
private struct CheckoutOptionSheet<Rows: View>: View {
    let title: String
    let manageTitle: String
    let onManage: () -> Void
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    rows()
                    Button(action: onManage) {
                        Label(manageTitle, systemImage: "plus.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .foregroundStyle(Color.brand)
                }
                .padding(Spacing.xl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct OptionRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let badge: String?
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.m) {
                IconBadge(systemImage: systemImage, tint: isEnabled ? .brand : .secondary, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.s) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.brand)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandSoft, in: Capsule())
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: Spacing.s)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brand : Color.secondary.opacity(0.5))
            }
            .padding(Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(isSelected ? Color.brand : .clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
