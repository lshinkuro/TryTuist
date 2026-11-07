//
//  BestSellerWidget.swift
//  TryTuistWidget
//
//  Widget "Kopdes · Terlaris": produk terlaris dari GET /v1/products?best_seller=true.
//  Endpoint publik (cukup X-API-Key), jadi widget tidak butuh sesi login / App Group.
//  Tap widget = buka app.
//
import UIKit
import WidgetKit
import SwiftUI

// MARK: - Model

struct WidgetProduct: Identifiable {
    let id: String
    let name: String
    let price: Int64
    let originalPrice: Int64?
    var image: UIImage?
}

struct BestSellerEntry: TimelineEntry {
    let date: Date
    let products: [WidgetProduct]
    let failed: Bool

    static let sample = BestSellerEntry(date: .now, products: [
        WidgetProduct(id: "P01", name: "Minyak Goreng 1 L", price: 22000, originalPrice: nil),
        WidgetProduct(id: "P05", name: "Susu UHT Full Cream 1 L", price: 17900, originalPrice: 27000),
        WidgetProduct(id: "P07", name: "Paket Sayur Segar", price: 19900, originalPrice: 32000)
    ], failed: false)
}

// MARK: - API

private enum BestSellerAPI {
    private struct Envelope: Decodable { let data: [ProductDTO] }
    private struct ProductDTO: Decodable {
        let product_id: String
        let product_name: String
        let price: Int64
        let original_price: Int64?
        let image_url: String
    }

    // shortcut: selalu server build (xcconfig), override server dari Debugger tidak ikut; pakai App Group bila perlu.
    private static func info(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "").trimmingCharacters(in: .whitespaces)
    }

    static func fetch(limit: Int) async throws -> [WidgetProduct] {
        guard var components = URLComponents(string: info("API_BASE_URL") + "/v1/products") else { throw URLError(.badURL) }
        components.queryItems = [URLQueryItem(name: "best_seller", value: "true"), URLQueryItem(name: "limit", value: "\(limit)")]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(info("API_KEY"), forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let dtos = try JSONDecoder().decode(Envelope.self, from: data).data.prefix(limit)

        // Widget tidak bisa AsyncImage: foto diunduh di sini lalu diperkecil (batas memori widget ±30 MB).
        return await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, dto) in dtos.enumerated() {
                group.addTask { (index, await thumbnail(dto.image_url)) }
            }
            var products = dtos.map {
                WidgetProduct(id: $0.product_id, name: $0.product_name, price: $0.price, originalPrice: $0.original_price)
            }
            for await (index, image) in group { products[index].image = image }
            return products
        }
    }

    private static func thumbnail(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 160, height: 160))
    }
}

// MARK: - Timeline

struct BestSellerProvider: TimelineProvider {
    func placeholder(in context: Context) -> BestSellerEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (BestSellerEntry) -> Void) {
        guard !context.isPreview else { return completion(.sample) }
        Task { completion(await load(for: context.family)) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BestSellerEntry>) -> Void) {
        Task {
            let entry = await load(for: context.family)
            // Gagal → coba lagi lebih cepat.
            let next = Date.now.addingTimeInterval(entry.failed ? 15 * 60 : 60 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func load(for family: WidgetFamily) async -> BestSellerEntry {
        do {
            let products = try await BestSellerAPI.fetch(limit: family == .systemSmall ? 1 : 3)
            return BestSellerEntry(date: .now, products: products, failed: false)
        } catch {
            return BestSellerEntry(date: .now, products: [], failed: true)
        }
    }
}

// MARK: - View

extension Color {
    /// Sama dengan `UIColor.brand` di TTUI (widget tidak menautkan framework app).
    static let brand = Color(red: 0.851, green: 0.282, blue: 0.059)
}

private func rupiah(_ value: Int64) -> String {
    value.formatted(.currency(code: "IDR").locale(Locale(identifier: "id_ID")).precision(.fractionLength(0)))
}

struct BestSellerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BestSellerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Kopdes · Terlaris", systemImage: "basket.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brand)
                .lineLimit(1)

            if entry.products.isEmpty {
                Spacer(minLength: 0)
                Text(entry.failed ? "Produk belum bisa dimuat. Buka aplikasi untuk belanja." : "Belum ada produk terlaris.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else if family == .systemSmall, let product = entry.products.first {
                ProductCell(product: product, imageSize: 56)
            } else {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(entry.products) { ProductCell(product: $0, imageSize: 52) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
    }
}

private struct ProductCell: View {
    let product: WidgetProduct
    let imageSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if let image = product.image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Color.brand.opacity(0.12).overlay(Image(systemName: "basket").foregroundStyle(Color.brand))
                }
            }
            .frame(width: imageSize, height: imageSize)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(product.name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
            Text(rupiah(product.price))
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.brand)
            if let original = product.originalPrice {
                Text(rupiah(original))
                    .font(.caption2)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct BestSellerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BestSellerWidget", provider: BestSellerProvider()) { entry in
            BestSellerWidgetView(entry: entry)
        }
        .configurationDisplayName("Kopdes Terlaris")
        .description("Produk terlaris dan promo Kopdes hari ini.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    BestSellerWidget()
} timeline: {
    BestSellerEntry.sample
}
