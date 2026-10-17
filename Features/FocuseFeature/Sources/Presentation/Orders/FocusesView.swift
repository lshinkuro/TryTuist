//
//  FocusesView.swift
//  FocuseFeature · Presentation
//
import SwiftUI
import TTUI

struct FocusesView: View {
    @StateObject private var store: OrdersStore

    init(store: OrdersStore) {
        _store = StateObject(wrappedValue: store)
    }

    /// Tab: "Semua" + semua status.
    private let filters: [OrderStatus?] = [nil] + OrderStatus.allCases.map { Optional($0) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                ScreenHeader(title: "Pesanan", subtitle: "Riwayat pesananmu")

                SegmentedTabBar(titles: filters.map { $0?.title ?? "Semua" }, selectedIndex: selectedIndex)

                content
            }
            .padding(Spacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { @MainActor in store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.orders {
        case .idle, .loading:
            ProgressView("Memuat…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)

        case .failed(let message):
            ContentUnavailableView {
                Label("Gagal memuat", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Coba Lagi") { store.send(.retryTapped) }
                    .buttonStyle(CapsuleButtonStyle(.filled))
            }

        case .loaded:
            if store.state.displayedOrders.isEmpty {
                ContentUnavailableView("Belum ada pesanan",
                                       systemImage: "bag",
                                       description: Text("Pesanan dengan status ini akan muncul di sini."))
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: Spacing.m) {
                    ForEach(store.state.displayedOrders) { order in
                        OrderRowView(order: order)
                    }
                }
            }
        }
    }

    private var selectedIndex: Binding<Int> {
        Binding(
            get: { MainActor.assumeIsolated { filters.firstIndex(of: store.state.filter) ?? 0 } },
            set: { index in MainActor.assumeIsolated { store.send(.filterChanged(filters[index])) } }
        )
    }
}

struct OrderRowView: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: Spacing.m) {
                IconBadge(systemImage: "cup.and.saucer.fill", size: 48)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(order.productName)
                        .font(.headline)
                    Label(order.storeName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(order.createdAt.shortDateTimeFormatted, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Spacing.s)

                Text(order.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(order.status.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, Spacing.xs)
                    .background(order.status.tint.opacity(0.12), in: Capsule())
            }

            Divider()

            HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(order.quantity) item")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(order.totalPrice.rupiahFormatted)
                        .font(.headline)
                }
                Spacer()
                Button("Beri Nilai") {}
                    .buttonStyle(CapsuleButtonStyle(.outlined))
                Button("Pesan Lagi") {}
                    .buttonStyle(CapsuleButtonStyle(.filled))
            }
        }
        .padding(Spacing.l)
        .formCard()
    }
}

/// Tampilan status hanya diketahui Presentation; Domain cukup tahu enum-nya.
extension OrderStatus {
    var title: String {
        switch self {
        case .pending: return "Diproses"
        case .completed: return "Selesai"
        case .failed: return "Gagal"
        }
    }

    var tint: Color {
        switch self {
        case .pending: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
}
