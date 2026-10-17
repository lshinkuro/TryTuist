//
//  PaymentMethodsView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct PaymentMethodsView: View {
    @StateObject private var store: PaymentMethodsStore

    init(store: PaymentMethodsStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: PaymentMethodsState { store.state }

    var body: some View {
        LoadableView(state: state.overview, retry: { store.send(.retryTapped) }) { overview in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text("Metode utama dipakai otomatis saat checkout. Ketuk untuk memilih.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    section(title: "Metode Pembayaran", methods: overview.builtins)
                    eWalletSection(overview)

                    Label("TryTuist tidak pernah menyimpan nomor kartu kredit/debit kamu.", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.xl)
            }
            .refreshable { store.send(.retryTapped) }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { store.send(.onAppear) }
        .toast(state.toast)
        .confirmationDialog("Hapus \(state.pendingRemoval?.name ?? "e-wallet")?",
                            isPresented: store.binding(\.isConfirmingRemoval, send: { .removeDialogChanged($0) }),
                            titleVisibility: .visible) {
            Button("Hapus", role: .destructive) { store.send(.removeConfirmed) }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Akun \(state.pendingRemoval?.detail ?? "") tidak bisa dipakai lagi sampai ditautkan ulang.")
        }
    }

    private func section(title: String, methods: [PaymentMethod]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title).font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(methods.enumerated()), id: \.element.id) { index, method in
                    if index > 0 { Divider().padding(.leading, 64) }
                    PaymentMethodRow(method: method, isBusy: state.busyID == method.id) {
                        store.send(.methodTapped(method))
                    } onRemove: {
                        store.send(.removeTapped(method))
                    }
                }
            }
            .formCard()
        }
    }

    @ViewBuilder
    private func eWalletSection(_ overview: PaymentOverview) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("E-Wallet").font(.headline)
                Spacer()
                if overview.canAddEWallet {
                    Button { store.send(.addTapped) } label: { Label("Tambah", systemImage: "plus") }
                        .buttonStyle(CapsuleButtonStyle(.outlined))
                }
            }
            if overview.eWallets.isEmpty {
                HStack(spacing: Spacing.m) {
                    IconBadge(systemImage: "wallet.pass", tint: .secondary, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Belum ada e-wallet").font(.subheadline.weight(.semibold))
                        Text(overview.canAddEWallet
                             ? "Tautkan GoPay, OVO, DANA, atau ShopeePay untuk bayar lebih cepat."
                             : "E-wallet sedang tidak tersedia.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .formCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(overview.eWallets.enumerated()), id: \.element.id) { index, method in
                        if index > 0 { Divider().padding(.leading, 64) }
                        PaymentMethodRow(method: method,
                                         tint: tint(for: method, providers: overview.providers),
                                         isBusy: state.busyID == method.id) {
                            store.send(.methodTapped(method))
                        } onRemove: {
                            store.send(.removeTapped(method))
                        }
                    }
                }
                .formCard()
            }
        }
    }

    private func tint(for method: PaymentMethod, providers: [EWalletProvider]) -> Color {
        guard case .eWallet(let providerID) = method.kind,
              let provider = providers.first(where: { $0.id == providerID }) else { return .brand }
        return Color.named(provider.tint)
    }
}

private struct PaymentMethodRow: View {
    let method: PaymentMethod
    var tint: Color = .brand
    let isBusy: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    IconBadge(systemImage: method.systemImage, tint: method.isEnabled ? tint : .secondary, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(method.name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(method.isEnabled ? Color.primary : Color.secondary)
                        if let detail = method.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        if !method.isEnabled {
                            Text("Sedang tidak tersedia")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                    Spacer(minLength: Spacing.s)
                    if isBusy {
                        ProgressView()
                    } else {
                        Image(systemName: method.isDefault ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(method.isDefault ? Color.brand : Color.secondary.opacity(0.5))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(method.isDefault ? .isSelected : [])
            .accessibilityHint(method.isDefault ? "Metode utama" : "Ketuk untuk jadikan metode utama")

            if method.isRemovable {
                Menu {
                    Button(role: .destructive, action: onRemove) { Label("Hapus", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 28, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Opsi \(method.name)")
                .disabled(isBusy)
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}
