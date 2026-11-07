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
                ScreenHeader(title: String(localized: "Pesanan"), subtitle: String(localized: "Riwayat pesananmu")) {
                    if store.state.isAssistantAvailable {
                        Button { store.send(.assistantTapped) } label: {
                            Label("Asisten", systemImage: "sparkles")
                        }
                        .buttonStyle(CapsuleButtonStyle(.outlined))
                        .accessibilityHint("Chat dengan asisten AI soal pesanan, kupon, dan pembayaran")
                    }
                }

                if let spending = store.state.spending.value {
                    MonthlySpendingCard(spending: spending, note: store.state.spendingNote)
                }

                SegmentedTabBar(titles: filters.map { $0?.title ?? String(localized: "Semua") }, selectedIndex: selectedIndex)

                HStack {
                    Menu {
                        Picker("Tanggal", selection: store.binding(\.dateRange, send: OrdersAction.dateRangeChanged)) {
                            ForEach(OrderDateRange.allCases, id: \.self) { Text($0.title).tag($0) }
                        }
                    } label: {
                        Label(store.state.dateRange.title, systemImage: "calendar")
                    }
                    Spacer()
                    Button { store.send(.sortToggled) } label: {
                        Label(store.state.newestFirst ? String(localized: "Terbaru") : String(localized: "Terlama"),
                              systemImage: store.state.newestFirst ? "arrow.down" : "arrow.up")
                    }
                    .accessibilityHint("Ubah urutan berdasarkan jam & tanggal pesanan")
                }
                .font(.appSubheadStrong)

                content
            }
            .padding(Spacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toast(store.state.toast)
        .refreshable { @MainActor in
            store.send(.onAppear)
            store.send(.spendingRequested)
        }
        .task { @MainActor in
            store.send(.onAppear)
            store.send(.spendingRequested)
        }
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
                        OrderRowView(order: order,
                                     isReordering: store.state.reorderingID == order.id,
                                     onTap: { store.send(.orderTapped(order)) },
                                     onRate: { store.send(.rateTapped(order)) },
                                     onReorder: { store.send(.reorderTapped(order)) })
                            .onAppear {
                                if order.id == store.state.displayedOrders.last?.id { store.send(.lastRowAppeared) }
                            }
                    }
                    if store.state.isLoadingMore {
                        ProgressView().padding(.vertical, Spacing.m)
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
    let isReordering: Bool
    let onTap: () -> Void
    let onRate: () -> Void
    let onReorder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onTap) { summary }
                .buttonStyle(.plain)
                .accessibilityHint("Buka detail pesanan")

            Divider()

            HStack(spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(order.quantity) item")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                    Text(order.totalPrice.rupiahFormatted)
                        .font(.appHeadline)
                }
                Spacer()
                if let rating = order.rating {
                    RatingStars(rating: rating, size: .caption)
                }
                if order.canRate {
                    Button("Beri Nilai", action: onRate)
                        .buttonStyle(CapsuleButtonStyle(.outlined))
                }
                Button(action: onReorder) {
                    if isReordering { ProgressView() } else { Text("Pesan Lagi") }
                }
                .buttonStyle(CapsuleButtonStyle(.filled))
                .disabled(isReordering)
            }
        }
        .padding(Spacing.l)
        .formCard()
    }

    private var summary: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            IconBadge(systemImage: "basket.fill", size: 48)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(order.productName)
                    .font(.appHeadline)
                Label(order.storeName, systemImage: "mappin.and.ellipse")
                    .font(.appSubhead)
                    .foregroundStyle(.secondary)
                Label(order.createdAt.shortDateTimeFormatted, systemImage: "clock")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.s)

            Text(order.status.title)
                .font(.appCaptionStrong)
                .foregroundStyle(order.status.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, Spacing.xs)
                .background(order.status.tint.opacity(0.12), in: Capsule())
        }
        .contentShape(Rectangle())
    }
}

/// Tampilan status hanya diketahui Presentation; Domain cukup tahu enum-nya.
extension OrderStatus {
    var title: String {
        switch self {
        case .pending: return String(localized: "Diproses")
        case .completed: return String(localized: "Selesai")
        case .failed: return String(localized: "Gagal")
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

/// "Belanja bulan ini": angka dihitung aplikasi, kalimat (opsional) dari Apple Intelligence.
private struct MonthlySpendingCard: View {
    let spending: MonthlySpending
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Belanja \(spending.month.formatted(.dateTime.month(.wide)))")
                .font(.appSubhead)
                .foregroundStyle(.secondary)
            if spending.orderCount == 0 {
                Text("Belum ada belanja bulan ini.").font(.appHeadline)
            } else {
                Text(spending.total.rupiahFormatted).font(.appTitle)
                Text("\(spending.orderCount) pesanan · paling sering: \(spending.topProducts.joined(separator: ", "))")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            if let note {
                Label(note, systemImage: "sparkles")
                    .font(.appSubhead)
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(Color.brand.opacity(0.08), in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}
