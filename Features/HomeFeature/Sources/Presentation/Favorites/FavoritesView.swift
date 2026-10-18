//
//  FavoritesView.swift
//  HomeFeature · Presentation
//
import SwiftUI
import TTUI

struct FavoritesView: View {
    @StateObject private var store: FavoritesStore

    init(store: FavoritesStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ScrollView {
            content.padding(Spacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toast(store.state.toast)
        .refreshable { @MainActor in store.send(.onAppear) }
        .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.favorites {
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

        case .loaded(let products) where products.isEmpty:
            ContentUnavailableView("Belum ada menu favorit",
                                   systemImage: "heart",
                                   description: Text("Ketuk ❤️ di detail menu untuk menyimpannya di sini."))
                .padding(.vertical, 40)

        case .loaded(let products):
            LazyVStack(spacing: Spacing.m) {
                ForEach(products) { product in
                    // "+" membuka Detail supaya varian & jumlah bisa dipilih.
                    ProductRowView(product: product) { store.send(.productTapped(product)) }
                        .onTapGesture { store.send(.productTapped(product)) }
                        .overlay(alignment: .topTrailing) {
                            Button { store.send(.removeTapped(product)) } label: {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                    .padding(Spacing.m)
                            }
                            .accessibilityLabel("Hapus \(product.name) dari favorit")
                        }
                }
            }
        }
    }
}
