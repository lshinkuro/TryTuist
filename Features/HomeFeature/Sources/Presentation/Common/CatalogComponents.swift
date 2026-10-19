//
//  CatalogComponents.swift
//  HomeFeature · Presentation
//
//  Komponen UI yang dipakai Beranda, Menu, dan Detail. Komponen tidak punya Store:
//  cukup menerima data + closure aksi dari screen-nya.
//
import SwiftUI
import TTUI

// MARK: - Kartu produk (carousel horizontal)

struct ProductCardView: View {
    let product: Product
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Color.clear
                .frame(height: 130)
                .overlay { RemoteImage(url: product.imageURL) }
                .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if product.isOnDeal {
                        DiscountBadge(percent: product.discountPercent).padding(Spacing.s)
                    } else if product.combo != nil {
                        ComboBadge().padding(Spacing.s)
                    } else if product.isBestSeller {
                        BestSellerBadge().padding(Spacing.s)
                    }
                }

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            RatingLabel(rating: product.rating, soldCount: product.soldCount)

            HStack(alignment: .bottom) {
                PriceLabel(price: product.price, originalPrice: product.originalPrice, axis: .vertical)
                Spacer(minLength: 0)
                AddButton(isEnabled: product.isAvailable, action: onAdd)
            }
        }
        .padding(Spacing.s)
        .frame(width: 168)
        .formCard()
        .contentShape(Rectangle())
    }
}

// MARK: - Baris produk (list vertikal)

struct ProductRowView: View {
    let product: Product
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Color.clear
                .frame(width: 92, height: 92)
                .overlay { RemoteImage(url: product.imageURL) }
                .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .overlay {
                    if !product.isAvailable {
                        RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                            .fill(.black.opacity(0.45))
                            .overlay { Text("Habis").font(.caption.bold()).foregroundStyle(.white) }
                    }
                }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Text(product.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if product.isOnDeal {
                        DiscountBadge(percent: product.discountPercent)
                    } else if product.combo != nil {
                        ComboBadge()
                    } else if product.isBestSeller {
                        BestSellerBadge()
                    }
                }
                // Combo: isi paket lebih berguna daripada deskripsi.
                Text(product.combo?.summary ?? product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                RatingLabel(rating: product.rating, soldCount: product.soldCount)
                HStack {
                    PriceLabel(price: product.price, originalPrice: product.originalPrice)
                    Spacer(minLength: 0)
                    AddButton(isEnabled: product.isAvailable, action: onAdd)
                }
            }
        }
        .padding(Spacing.m)
        .formCard()
        .opacity(product.isAvailable ? 1 : 0.7)
        .contentShape(Rectangle())
    }
}

// MARK: - Kecil-kecil

struct AddButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(isEnabled ? Color.brand : Color.secondary.opacity(0.4), in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel("Tambah ke keranjang")
    }
}

struct RatingLabel: View {
    let rating: Double
    let soldCount: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text(rating > 0 ? String(format: "%.1f", rating) : String(localized: "Baru"))
                .foregroundStyle(.primary)
            Text("· \(soldCount.compactFormatted) terjual")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }
}

struct BestSellerBadge: View {
    var body: some View {
        Text("🔥 Terlaris")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.brand, in: Capsule())
    }
}

/// Badge potongan harga, mis. "-37%".
/// Label paket combo.
struct ComboBadge: View {
    var body: some View {
        Text("PAKET")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.brand, in: Capsule())
            .accessibilityLabel(String(localized: "Paket combo"))
    }
}

struct DiscountBadge: View {
    let percent: Int

    var body: some View {
        Text(percent > 0 ? "-\(percent)%" : "PROMO")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red, in: Capsule())
            .accessibilityLabel(percent > 0 ? String(localized: "Diskon \(percent) persen") : String(localized: "Promo"))
    }
}

/// Harga berlaku + harga normal dicoret bila sedang promo.
struct PriceLabel: View {
    let price: Decimal
    var originalPrice: Decimal?
    var axis: Axis = .horizontal
    var font: Font = .subheadline.bold()

    private var showsOriginal: Bool { (originalPrice ?? 0) > price }

    var body: some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 6))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
        layout {
            if showsOriginal, let originalPrice {
                if axis == .vertical { original(originalPrice) }
                current
                if axis == .horizontal { original(originalPrice) }
            } else {
                current
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var current: some View {
        Text(price.rupiahFormatted)
            .font(font)
            .foregroundStyle(showsOriginal ? Color.red : Color.brand)
    }

    private func original(_ value: Decimal) -> some View {
        Text(value.rupiahFormatted)
            .font(.caption)
            .strikethrough()
            .foregroundStyle(.secondary)
    }

    private var accessibilityText: String {
        guard showsOriginal, let originalPrice else { return price.rupiahFormatted }
        return String(localized: "\(price.rupiahFormatted), dari \(originalPrice.rupiahFormatted)")
    }
}

struct CategoryChip: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(isSelected ? Color.brand : Color.cardBackground, in: Capsule())
            .overlay(Capsule().stroke(Color.primary.opacity(isSelected ? 0 : 0.08)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Bar keranjang mengambang di bawah layar.
struct CartBarView: View {
    let summary: CartSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bag.fill")
                        .font(.title3)
                    Text("\(summary.itemCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.brand)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Color.white, in: Circle())
                        .offset(x: 8, y: -6)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(summary.itemCount) item")
                        .font(.caption)
                        .opacity(0.85)
                    Text(summary.total.rupiahFormatted)
                        .font(.headline)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("Keranjang")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.l)
            .frame(height: 60)
            .background(Color.brand, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .shadow(color: Color.brand.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.s)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityLabel("Keranjang, \(summary.itemCount) item, total \(summary.total.rupiahFormatted)")
    }
}

/// Tampilan loading/error standar untuk data async.
struct LoadFailedView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Gagal memuat", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Coba Lagi", action: onRetry)
                .buttonStyle(CapsuleButtonStyle(.filled))
        }
    }
}

extension Int {
    /// 1520 → "1,5rb"
    var compactFormatted: String {
        self >= 1000 ? String(format: "%.1frb", Double(self) / 1000).replacingOccurrences(of: ".", with: ",") : "\(self)"
    }
}
