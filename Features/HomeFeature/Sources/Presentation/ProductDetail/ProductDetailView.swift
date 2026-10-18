//
//  ProductDetailView.swift
//  HomeFeature · Presentation
//
//  Tidak ada @State logika di sini; semua lewat ProductDetailStore.
//
import SwiftUI
import TTUI

struct ProductDetailView: View {
    @StateObject private var store: ProductDetailStore

    init(store: ProductDetailStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: ProductDetailState { store.state }
    private var product: Product { state.product }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Color.clear
                    .frame(height: 300)
                    .overlay { RemoteImage(url: product.imageURL) }
                    .clipped()

                VStack(alignment: .leading, spacing: Spacing.xl) {
                    info
                    if !product.options.isEmpty { options }
                    quantity
                    note
                    if let error = state.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, 100)
        }
        .ignoresSafeArea(edges: .top)
        .task { @MainActor in store.send(.onAppear) }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.send(.favoriteToggled) } label: {
                    Image(systemName: state.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(state.isFavorite ? Color.red : Color.primary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(state.isFavorite ? String(localized: "Hapus dari favorit") : String(localized: "Tambah ke favorit"))
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(state.addButtonTitle, isLoading: state.isAdding, isEnabled: state.canAddToCart) {
                store.send(.addToCartTapped)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.m)
            .background(.bar)
        }
    }

    // MARK: - Sections

    private var info: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(product.name)
                    .font(.title.bold())
                Spacer(minLength: Spacing.s)
                if product.isOnDeal {
                    DiscountBadge(percent: product.discountPercent)
                } else if product.isBestSeller {
                    BestSellerBadge()
                }
            }
            RatingLabel(rating: product.rating, soldCount: product.soldCount)
            Text(product.description)
                .font(.body)
                .foregroundStyle(.secondary)
            PriceLabel(price: state.unitPrice, originalPrice: state.originalUnitPrice, font: .title2.bold())
                .contentTransition(.numericText())
                .animation(.snappy, value: state.unitPrice)
            if state.totalSavings > 0 {
                Label("Kamu hemat \(state.totalSavings.rupiahFormatted)", systemImage: "tag.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1), in: Capsule())
                    .contentTransition(.numericText())
                    .animation(.snappy, value: state.totalSavings)
            }
        }
    }

    private var options: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text("Pilih varian").font(.headline)
            VStack(spacing: 0) {
                ForEach(product.options) { option in
                    let isSelected = option.id == state.selectedOptionID
                    Button { store.send(.optionSelected(option.id)) } label: {
                        HStack {
                            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(isSelected ? Color.brand : Color.secondary)
                            Text(option.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(option.extraPrice == 0 ? String(localized: "Gratis") : "+\(option.extraPrice.rupiahFormatted)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, Spacing.l)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])

                    if option.id != product.options.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .formCard(cornerRadius: Radius.control)
        }
    }

    private var quantity: some View {
        HStack {
            Text("Jumlah").font(.headline)
            Spacer()
            HStack(spacing: Spacing.l) {
                stepperButton("minus", enabled: state.canDecrease) { store.send(.decrementTapped) }
                    .accessibilityLabel("Kurangi")
                Text("\(state.quantity)")
                    .font(.title3.bold())
                    .frame(minWidth: 28)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: state.quantity)
                stepperButton("plus", enabled: state.canIncrease) { store.send(.incrementTapped) }
                    .accessibilityLabel("Tambah")
            }
        }
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Catatan").font(.headline)
                Text("(opsional)").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("\(state.note.count)/\(ProductDetailState.noteLimit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextField("Contoh: less sugar, tanpa bawang",
                      text: store.binding(\.note, send: { .noteChanged($0) }),
                      axis: .vertical)
                .lineLimit(2...4)
                .padding(Spacing.m)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
    }

    private func stepperButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(enabled ? Color.brand : Color.secondary)
                .frame(width: 36, height: 36)
                .background((enabled ? Color.brand : Color.secondary).opacity(0.12), in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
    }
}
