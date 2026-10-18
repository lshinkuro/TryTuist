//
//  OrderDetailView.swift
//  FocuseFeature · Presentation
//
import SwiftUI
import TTUI

struct OrderDetailView: View {
    @StateObject private var store: OrderDetailStore

    init(store: OrderDetailStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ScrollView {
            content.padding(Spacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task { @MainActor in store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.detail {
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

        case .loaded(let detail):
            VStack(alignment: .leading, spacing: Spacing.l) {
                header(detail)
                itemsCard(detail)
                summaryCard(detail)
                infoCard(detail)
                if detail.canRate || detail.rating != nil { ratingCard(detail) }
                if !detail.history.isEmpty { historyCard(detail) }
            }
        }
    }

    private func header(_ detail: OrderDetail) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(detail.orderNumber).font(.headline)
                Label(detail.createdAt.shortDateTimeFormatted, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(OrderStatusText.title(for: detail.rawStatus))
                .font(.caption.weight(.semibold))
                .foregroundStyle(detail.status.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, Spacing.xs)
                .background(detail.status.tint.opacity(0.12), in: Capsule())
        }
        .padding(Spacing.l)
        .formCard()
    }

    private func itemsCard(_ detail: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Pesananmu").font(.headline)
            ForEach(Array(detail.items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top) {
                    Text("\(item.quantity)×").font(.subheadline.weight(.semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.subheadline)
                        if let option = item.optionName {
                            Text(option).font(.caption).foregroundStyle(.secondary)
                        }
                        if let note = item.note {
                            Text("Catatan: \(note)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(item.subtotal.rupiahFormatted).font(.subheadline)
                }
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
    }

    private func summaryCard(_ detail: OrderDetail) -> some View {
        VStack(spacing: Spacing.s) {
            row(String(localized: "Subtotal"), detail.subtotal.rupiahFormatted)
            row(String(localized: "Ongkir"), detail.deliveryFee.rupiahFormatted)
            if detail.discount > 0 {
                row(detail.voucherCode.map { String(localized: "Diskon (\($0))") } ?? String(localized: "Diskon"), "-\(detail.discount.rupiahFormatted)")
            }
            Divider()
            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text(detail.total.rupiahFormatted).font(.headline)
            }
        }
        .padding(Spacing.l)
        .formCard()
    }

    private func infoCard(_ detail: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Label(detail.storeName, systemImage: "storefront")
            if let address = detail.deliveryAddress {
                Label(address, systemImage: "mappin.and.ellipse")
            }
            Label(detail.paymentMethod, systemImage: "creditcard")
        }
        .font(.subheadline)
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
    }

    private func ratingCard(_ detail: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Penilaianmu").font(.headline)
            if let rating = detail.rating {
                RatingStars(rating: rating)
                if let comment = detail.ratingComment {
                    Text(comment).font(.subheadline).foregroundStyle(.secondary)
                }
            } else {
                Text("Bagaimana pesananmu? Nilaimu membantu outlet jadi lebih baik.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Beri Nilai") { store.send(.rateTapped) }
                    .buttonStyle(CapsuleButtonStyle(.filled))
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
    }

    private func historyCard(_ detail: OrderDetail) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Riwayat status").font(.headline)
            ForEach(Array(detail.history.enumerated()), id: \.offset) { _, event in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(OrderStatusText.title(for: event.rawStatus)).font(.subheadline)
                        if let note = event.note {
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(event.at.shortDateTimeFormatted).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

/// Bintang 1–5 yang sudah diberikan (hanya tampil).
struct RatingStars: View {
    let rating: Int
    var size: Font = .title3

    var body: some View {
        HStack(spacing: 2) {
            ForEach(RateOrderUseCase.ratingRange, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? Color.orange : Color.secondary)
            }
        }
        .font(size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dinilai \(rating) dari 5 bintang")
    }
}

/// Status mentah backend → teks. Daftar resmi: API_PLAN.md §5.12.
enum OrderStatusText {
    static func title(for raw: String) -> String {
        switch raw {
        case "PENDING": return String(localized: "Menunggu")
        case "PAID": return String(localized: "Dibayar")
        case "PROCESSING": return String(localized: "Diproses")
        case "DELIVERING": return String(localized: "Diantar")
        case "COMPLETED": return String(localized: "Selesai")
        case "CANCELLED": return String(localized: "Dibatalkan")
        case "FAILED": return String(localized: "Gagal")
        default: return raw.capitalized
        }
    }
}
