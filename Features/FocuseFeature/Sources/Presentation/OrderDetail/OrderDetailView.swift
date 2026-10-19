//
//  OrderDetailView.swift
//  FocuseFeature · Presentation
//
//  Detail pesanan: status & progres di atas, lalu pengembalian dana (Bayar Online), rute antar,
//  rincian & pembayaran, penilaian, riwayat status. Aksi (batal / pesan lagi / struk) di bawah.
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
        .safeAreaInset(edge: .bottom) {
            if let detail = store.state.detail.value { actionBar(detail) }
        }
        .toast(store.state.toast)
        .task(id: store.state.toast?.id) { @MainActor in
            guard let id = store.state.toast?.id else { return }
            try? await Task.sleep(for: .seconds(2.5))
            store.send(.toastDismissed(id))
        }
        .confirmationDialog(String(localized: "Batalkan pesanan ini?"),
                            isPresented: store.binding(\.isConfirmingCancel, send: { .cancelConfirmChanged($0) }),
                            titleVisibility: .visible) {
            Button(String(localized: "Ya, batalkan"), role: .destructive) { store.send(.cancelConfirmed) }
            Button(String(localized: "Tidak jadi"), role: .cancel) {}
        } message: {
            Text("Outlet belum memproses pesananmu, jadi masih bisa dibatalkan. Voucher & kupon yang dipakai akan kembali.")
        }
        .sheet(isPresented: store.binding(\.isReceiptPresented, send: { .receiptChanged($0) })) {
            if let detail = store.state.detail.value {
                ReceiptSheet(detail: detail) { store.send(.receiptChanged(false)) }
            }
        }
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
                StatusHeroCard(detail: detail)
                if let refund = detail.refund { RefundCard(refund: refund, paidWith: PaymentLabel.title(for: detail)) }
                RouteCard(detail: detail)
                BillCard(detail: detail) { store.send(.receiptChanged(true)) }
                if detail.canRate || detail.rating != nil { ratingCard(detail) }
                if !detail.history.isEmpty { TimelineCard(detail: detail) }
            }
        }
    }

    /// Aksi utama di bawah: batal selama belum diproses; pesan lagi setelah pesanan berakhir.
    @ViewBuilder
    private func actionBar(_ detail: OrderDetail) -> some View {
        let isFinished = ["COMPLETED", "CANCELLED", "FAILED"].contains(detail.rawStatus)
        if detail.canCancel || isFinished {
            HStack(spacing: Spacing.m) {
                if detail.canCancel {
                    Button(role: .destructive) { store.send(.cancelTapped) } label: {
                        if store.state.isCancelling { ProgressView() } else { Text("Batalkan Pesanan") }
                    }
                    .buttonStyle(CapsuleButtonStyle(.outlined, tint: .red))
                    .disabled(store.state.isCancelling)
                }
                if isFinished {
                    PrimaryButton(String(localized: "Pesan Lagi")) { store.send(.reorderTapped) }
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(.bar)
        }
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
}

// MARK: - Status

/// Tampilan per status mentah backend (API_PLAN §5.12).
private struct StatusStyle {
    let icon: String
    let title: String
    let message: String
    let tint: Color

    static func of(_ detail: OrderDetail) -> StatusStyle {
        switch detail.rawStatus {
        case "PENDING":
            return .init(icon: "clock.fill", title: String(localized: "Menunggu outlet"),
                         message: String(localized: "Pesananmu sudah diterima dan segera diproses outlet."), tint: .orange)
        case "PAID":
            return .init(icon: "checkmark.seal.fill", title: String(localized: "Pembayaran diterima"),
                         message: String(localized: "Pesananmu diteruskan ke outlet."), tint: .orange)
        case "PROCESSING":
            return .init(icon: "frying.pan.fill", title: String(localized: "Sedang disiapkan"),
                         message: String(localized: "Outlet sedang menyiapkan pesananmu."), tint: .orange)
        case "DELIVERING":
            return .init(icon: "scooter", title: String(localized: "Sedang diantar"),
                         message: String(localized: "Kurir sedang menuju alamatmu."), tint: .blue)
        case "COMPLETED":
            return .init(icon: "checkmark.circle.fill", title: String(localized: "Pesanan selesai"),
                         message: String(localized: "Selamat menikmati!"), tint: .green)
        case "CANCELLED":
            return .init(icon: "xmark.circle.fill", title: String(localized: "Pesanan dibatalkan"),
                         message: detail.closingNote ?? String(localized: "Pesanan ini sudah dibatalkan."), tint: .secondary)
        case "FAILED":
            return .init(icon: "exclamationmark.triangle.fill", title: String(localized: "Pesanan gagal"),
                         message: detail.closingNote ?? String(localized: "Outlet tidak dapat menyelesaikan pesanan ini."), tint: .red)
        default:
            return .init(icon: "bag.fill", title: OrderStatusText.title(for: detail.rawStatus), message: "", tint: .secondary)
        }
    }
}

private struct StatusHeroCard: View {
    let detail: OrderDetail

    /// Diterima → Diproses → Diantar → Selesai.
    private static let steps = [String(localized: "Diterima"), String(localized: "Diproses"),
                                String(localized: "Diantar"), String(localized: "Selesai")]

    private var stepIndex: Int? {
        switch detail.rawStatus {
        case "PENDING", "PAID": return 0
        case "PROCESSING": return 1
        case "DELIVERING": return 2
        case "COMPLETED": return 3
        default: return nil   // batal / gagal: tanpa progres
        }
    }

    var body: some View {
        let style = StatusStyle.of(detail)
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .top, spacing: Spacing.m) {
                Image(systemName: style.icon)
                    .font(.title2)
                    .foregroundStyle(style.tint)
                    .frame(width: 48, height: 48)
                    .background(style.tint.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(style.title).font(.title3.bold())
                    if !style.message.isEmpty {
                        Text(style.message).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let arrival = detail.estimatedArrival {
                        Label(String(localized: "Perkiraan tiba \(arrival.lowerBound.formatted(date: .omitted, time: .shortened))–\(arrival.upperBound.formatted(date: .omitted, time: .shortened))"),
                              systemImage: "clock")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brand)
                            .padding(.top, 2)
                    }
                }
            }

            if let current = stepIndex {
                progress(current: current)
            }

            HStack {
                Text(detail.orderNumber).font(.caption.monospaced())
                Spacer()
                Text(detail.createdAt.shortDateTimeFormatted).font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
        .accessibilityElement(children: .combine)
    }

    private func progress(current: Int) -> some View {
        VStack(spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                ForEach(Self.steps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= current ? Color.brand : Color.secondary.opacity(0.2))
                        .frame(height: 6)
                }
            }
            HStack {
                ForEach(Self.steps.indices, id: \.self) { i in
                    Text(Self.steps[i])
                        .font(.caption2.weight(i == current ? .bold : .regular))
                        .foregroundStyle(i <= current ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Pengembalian dana

private struct RefundCard: View {
    let refund: OrderRefund
    let paidWith: String

    var body: some View {
        let (icon, title, message, tint): (String, String, String, Color) = {
            switch refund {
            case .pending:
                return ("arrow.uturn.backward.circle.fill", String(localized: "Pengembalian dana diproses"),
                        String(localized: "Toko akan mengembalikan pembayaranmu ke \(paidWith). Hubungi Pusat Bantuan bila ada pertanyaan."), .orange)
            case .partial(let amount):
                return ("arrow.uturn.backward.circle.fill", String(localized: "Sebagian dana dikembalikan"),
                        String(localized: "\(amount.rupiahFormatted) sudah dikembalikan ke \(paidWith)."), .blue)
            case .completed(let amount):
                return ("checkmark.circle.fill", String(localized: "Dana sudah dikembalikan"),
                        String(localized: "\(amount.rupiahFormatted) sudah dikembalikan ke \(paidWith)."), .green)
            }
        }()
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: icon).font(.title3).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.l)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }
}

// MARK: - Rute antar

private struct RouteCard: View {
    let detail: OrderDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stop(icon: "storefront.fill", tint: Color.brand, title: detail.storeName, subtitle: detail.storeAddress)
            HStack(spacing: Spacing.m) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2, height: 22)
                    .padding(.leading, 13)
                if let km = detail.distanceKm {
                    Text("\(km.formatted(.number.precision(.fractionLength(1)))) km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            stop(icon: "mappin.circle.fill", tint: .red,
                 title: detail.deliveryAddress ?? String(localized: "Alamat tidak tersedia"), subtitle: nil)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
    }

    private func stop(icon: String, tint: Color, title: String, subtitle: String?) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Image(systemName: icon).font(.title3).foregroundStyle(tint).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }
}

// MARK: - Rincian & pembayaran

/// "COD" / "ONLINE" + provider → label untuk pelanggan.
enum PaymentLabel {
    static func title(for detail: OrderDetail) -> String {
        if let provider = detail.paymentProvider {
            switch provider.uppercased() {
            case "GOPAY": return "GoPay"
            case "SHOPEEPAY": return "ShopeePay"
            case "QRIS": return "QRIS"
            case "BANK_TRANSFER", "ECHANNEL": return String(localized: "Transfer bank (VA)")
            case "CREDIT_CARD": return String(localized: "Kartu kredit/debit")
            case "CSTORE": return String(localized: "Gerai (Indomaret/Alfamart)")
            default: return provider.capitalized
            }
        }
        switch detail.paymentType {
        case "COD": return String(localized: "Bayar di tempat (COD)")
        case "QRIS": return "QRIS"
        default: return String(localized: "Bayar online")
        }
    }
}

private struct BillCard: View {
    let detail: OrderDetail
    let onReceipt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Rincian pesanan").font(.headline)
            ForEach(Array(detail.items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: Spacing.m) {
                    Text("\(item.quantity)×")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.brand)
                        .frame(minWidth: 28, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.subheadline.weight(.medium))
                        if let option = item.optionName {
                            Text(option).font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(item.bundle, id: \.self) { part in
                            Text("• \(part)").font(.caption).foregroundStyle(.secondary)
                        }
                        if let note = item.note {
                            Text("“\(note)”").font(.caption).italic().foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(item.subtotal.rupiahFormatted).font(.subheadline)
                }
            }

            Divider()

            VStack(spacing: Spacing.s) {
                row(String(localized: "Subtotal"), detail.subtotal.rupiahFormatted)
                if detail.freeDeliveryCoupon {
                    HStack {
                        Label(String(localized: "Ongkir (kupon)"), systemImage: "ticket.fill").foregroundStyle(.secondary)
                        Spacer()
                        Text(detail.deliveryFeeWaived.rupiahFormatted).strikethrough().foregroundStyle(.secondary)
                        Text("Gratis").bold().foregroundStyle(Color.brand)
                    }
                    .font(.subheadline)
                } else {
                    row(String(localized: "Ongkir"), detail.deliveryFee == 0 ? String(localized: "Gratis") : detail.deliveryFee.rupiahFormatted)
                }
                if detail.discount > 0 {
                    row(detail.voucherCode.map { String(localized: "Diskon (\($0))") } ?? String(localized: "Diskon"),
                        "−\(detail.discount.rupiahFormatted)")
                }
            }

            Divider()

            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text(detail.total.rupiahFormatted).font(.title3.bold())
            }
            HStack {
                Label(PaymentLabel.title(for: detail), systemImage: detail.isOnlinePayment ? "creditcard.fill" : "banknote.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onReceipt) {
                    Label(String(localized: "Lihat struk"), systemImage: "doc.text")
                        .font(.subheadline.weight(.semibold))
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

// MARK: - Riwayat

private struct TimelineCard: View {
    let detail: OrderDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Riwayat status").font(.headline)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(detail.history.reversed().enumerated()), id: \.offset) { index, event in
                    HStack(alignment: .top, spacing: Spacing.m) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(index == 0 ? Color.brand : Color.secondary.opacity(0.35))
                                .frame(width: 10, height: 10)
                                .padding(.top, 4)
                            if index < detail.history.count - 1 {
                                Rectangle().fill(Color.secondary.opacity(0.25)).frame(width: 2).frame(maxHeight: .infinity)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(OrderStatusText.title(for: event.rawStatus))
                                .font(.subheadline.weight(index == 0 ? .semibold : .regular))
                            if let note = event.note {
                                Text(note).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(event.at.shortDateTimeFormatted).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.bottom, Spacing.m)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .formCard()
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
