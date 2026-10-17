//
//  HomeView.swift
//  HomeFeature · Presentation
//
import SwiftUI
import TTUI

struct HomeView: View {
    @StateObject private var store: HomeStore

    init(store: HomeStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: HomeState { store.state }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                header
                    .padding(.horizontal, Spacing.xl)

                switch state.content {
                case .idle, .loading:
                    HomeSkeletonView()
                case .failed(let message):
                    LoadFailedView(message: message) { store.send(.retryTapped) }
                        .padding(.top, 40)
                case .loaded(let content):
                    loaded(content)
                }
            }
            .padding(.top, Spacing.s)
            .padding(.bottom, state.cart.isEmpty ? Spacing.xl : 96)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if !state.cart.isEmpty {
                CartBarView(summary: state.cart) { store.send(.cartTapped) }
            }
        }
        .animation(.snappy, value: state.cart)
        .toast(state.toast)
        .task { @MainActor in store.send(.onAppear) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            HStack(alignment: .center, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Antar ke")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Color.brand)
                        Text(state.deliveryAddress)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                CartIconButton(count: state.cart.itemCount) { store.send(.cartTapped) }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(state.greeting), \(state.userName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Mau makan apa hari ini?")
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
            }

            Button { store.send(.seeAllTapped) } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "magnifyingglass")
                    Text("Cari kopi, nasi goreng, burger…")
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.l)
                .frame(height: 48)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func loaded(_ content: HomeContent) -> some View {
        if !content.banners.isEmpty {
            PromoCarouselView(banners: content.banners,
                              currentPage: store.binding(\.bannerPage, send: { .bannerPageChanged($0) }))
        }

        if !content.categories.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader(title: "Kategori")
                    .padding(.horizontal, Spacing.xl)
                CategoryGridView(categories: content.categories) { store.send(.categoryTapped($0)) }
                    .padding(.horizontal, Spacing.xl)
            }
        }

        if !content.bestSellers.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader(title: "🔥 Paling Laris", actionTitle: "Lihat semua") { store.send(.seeAllTapped) }
                    .padding(.horizontal, Spacing.xl)
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.m) {
                        ForEach(content.bestSellers) { product in
                            ProductCardView(product: product) { store.send(.quickAddTapped(product)) }
                                .onTapGesture { store.send(.productTapped(product)) }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.xs)
                }
                .scrollIndicators(.hidden)
            }
        }

        if !content.recommended.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader(title: "Rekomendasi Buat Kamu")
                LazyVStack(spacing: Spacing.m) {
                    ForEach(content.recommended) { product in
                        ProductRowView(product: product) { store.send(.quickAddTapped(product)) }
                            .onTapGesture { store.send(.productTapped(product)) }
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - Komponen Beranda

private struct CartIconButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "bag")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Color.cardBackground, in: Circle())
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.brand, in: Circle())
                            .offset(x: 2, y: -2)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Keranjang, \(count) item")
    }
}

private struct PromoCarouselView: View {
    let banners: [Banner]
    @Binding var currentPage: Int

    var body: some View {
        VStack(spacing: Spacing.m) {
            TabView(selection: $currentPage) {
                ForEach(Array(banners.enumerated()), id: \.element.id) { index, banner in
                    Color.clear
                        .overlay { RemoteImage(url: banner.imageURL) }
                        .overlay {
                            LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
                        }
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PROMO")
                                    .font(.caption2.weight(.heavy))
                                    .tracking(1.5)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.brand, in: Capsule())
                                Text(banner.title)
                                    .font(.title3.bold())
                                Text(banner.subtitle)
                                    .font(.subheadline)
                                    .opacity(0.9)
                            }
                            .foregroundStyle(.white)
                            .padding(Spacing.l)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                        .padding(.horizontal, Spacing.xl)
                        .tag(index)
                        .accessibilityElement(children: .combine)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)

            PageIndicator(numberOfPages: banners.count, currentPage: currentPage)
        }
    }
}

private struct CategoryGridView: View {
    let categories: [MenuCategory]
    let onSelect: (MenuCategory) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.m), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.m) {
            ForEach(categories) { category in
                Button { onSelect(category) } label: {
                    VStack(spacing: Spacing.s) {
                        Text(category.icon)
                            .font(.system(size: 34))
                            .frame(width: 60, height: 60)
                            .background(Color.brandSoft, in: Circle())
                        Text(category.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .formCard(cornerRadius: Radius.control)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

private struct HomeSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            RoundedRectangle(cornerRadius: Radius.card).frame(height: 180)
            HStack(spacing: Spacing.m) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Radius.control).frame(height: 96)
                }
            }
            HStack(spacing: Spacing.m) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Radius.card).frame(height: 220)
                }
            }
        }
        .foregroundStyle(Color.secondary.opacity(0.12))
        .padding(.horizontal, Spacing.xl)
        .accessibilityLabel("Memuat")
    }
}
