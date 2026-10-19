//
//  ReceiptView.swift
//  FocuseFeature · Presentation
//
//  Struk digital: tampil di sheet & dibagikan sebagai PDF (reimburse, bukti komplain).
//  Selalu hitam di atas putih supaya PDF sama di light/dark mode.
//
import SwiftUI
import TTUI

struct ReceiptSheet: View {
    let detail: OrderDetail
    let onClose: () -> Void
    @State private var pdfURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                ReceiptView(detail: detail)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                    .padding(Spacing.xl)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(String(localized: "Struk"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Tutup"), action: onClose)
                }
                ToolbarItem(placement: .primaryAction) {
                    if let pdfURL {
                        ShareLink(item: pdfURL) { Label(String(localized: "Bagikan"), systemImage: "square.and.arrow.up") }
                    } else {
                        ProgressView()
                    }
                }
            }
        }
        .task { @MainActor in pdfURL = ReceiptPDF.make(detail) }
    }
}

struct ReceiptView: View {
    let detail: OrderDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 4) {
                Text("TryTuist").font(.title2.bold())
                Text(detail.storeName).font(.subheadline.weight(.semibold))
                if let address = detail.storeAddress {
                    Text(address).font(.caption).multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)

            dashed

            VStack(spacing: 4) {
                line(String(localized: "No. pesanan"), detail.orderNumber)
                line(String(localized: "Tanggal"), detail.createdAt.formatted(date: .abbreviated, time: .shortened))
                line(String(localized: "Status"), OrderStatusText.title(for: detail.rawStatus))
                line(String(localized: "Pembayaran"), PaymentLabel.title(for: detail))
            }

            dashed

            ForEach(Array(detail.items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.subheadline)
                    ForEach(item.bundle, id: \.self) { part in
                        Text("  - \(part)").font(.caption2)
                    }
                    HStack {
                        Text([item.optionName, "\(item.quantity)×"].compactMap { $0 }.joined(separator: " · "))
                            .font(.caption)
                        Spacer()
                        Text(item.subtotal.rupiahFormatted).font(.subheadline)
                    }
                }
            }

            dashed

            VStack(spacing: 4) {
                line(String(localized: "Subtotal"), detail.subtotal.rupiahFormatted)
                if detail.freeDeliveryCoupon {
                    line(String(localized: "Ongkir"), detail.deliveryFeeWaived.rupiahFormatted)
                    line(String(localized: "Kupon gratis ongkir"), "−\(detail.deliveryFeeWaived.rupiahFormatted)")
                } else {
                    line(String(localized: "Ongkir"), detail.deliveryFee.rupiahFormatted)
                }
                if detail.discount > 0 {
                    line(detail.voucherCode.map { String(localized: "Diskon (\($0))") } ?? String(localized: "Diskon"),
                         "−\(detail.discount.rupiahFormatted)")
                }
            }
            HStack {
                Text("TOTAL").font(.headline)
                Spacer()
                Text(detail.total.rupiahFormatted).font(.headline)
            }
            if case .completed(let amount) = detail.refund {
                line(String(localized: "Dikembalikan"), "−\(amount.rupiahFormatted)")
            } else if case .partial(let amount) = detail.refund {
                line(String(localized: "Dikembalikan"), "−\(amount.rupiahFormatted)")
            }

            dashed

            Text("Terima kasih sudah memesan di TryTuist!")
                .font(.caption)
                .frame(maxWidth: .infinity)
        }
        .monospacedDigit()
        .foregroundStyle(.black)
        .padding(24)
        .frame(width: 340)
        .background(.white)
        .environment(\.colorScheme, .light)
    }

    private var dashed: some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(.black.opacity(0.35))
            .frame(height: 1)
    }

    private func line(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).font(.caption)
            Spacer()
            Text(value).font(.caption).multilineTextAlignment(.trailing)
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { $0.move(to: .zero); $0.addLine(to: CGPoint(x: rect.width, y: 0)) }
        }
    }
}

/// Render `ReceiptView` ke file PDF sementara untuk ShareLink.
@MainActor
enum ReceiptPDF {
    static func make(_ detail: OrderDetail) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Struk-\(detail.orderNumber).pdf")
        let renderer = ImageRenderer(content: ReceiptView(detail: detail))
        var written = false
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
            written = true
        }
        return written ? url : nil
    }
}
