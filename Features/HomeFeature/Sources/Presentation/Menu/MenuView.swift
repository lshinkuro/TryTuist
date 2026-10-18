//
//  MenuView.swift
//  HomeFeature · Presentation
//
import SwiftUI
import TTUI

struct MenuView: View {
    @StateObject private var store: MenuStore

    init(store: MenuStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: MenuState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            content
        }
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

    // MARK: - Header, pencarian, kategori

    private var topBar: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            if state.isRootScreen {
                ScreenHeader(title: String(localized: "Menu"), subtitle: String(localized: "Makanan & minuman"))
                    .padding(.horizontal, Spacing.xl)
            }

            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Cari menu…", text: store.binding(\.query, send: { .queryChanged($0) }))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                if !state.query.isEmpty {
                    Button { store.send(.queryChanged("")) } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Hapus pencarian")
                }
            }
            .padding(.horizontal, Spacing.l)
            .frame(height: 46)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .padding(.horizontal, Spacing.xl)

            if let categories = state.content.value?.categories {
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.s) {
                        CategoryChip(icon: "🍽️", title: String(localized: "Semua"), isSelected: state.selectedCategoryID == nil) {
                            store.send(.categorySelected(nil))
                        }
                        ForEach(categories) { category in
                            CategoryChip(icon: category.icon,
                                         title: category.name,
                                         isSelected: state.selectedCategoryID == category.id) {
                                store.send(.categorySelected(category.id))
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, Spacing.s)
        .padding(.bottom, Spacing.m)
    }

    // MARK: - Daftar

    @ViewBuilder
    private var content: some View {
        switch state.content {
        case .idle, .loading:
            ProgressView("Memuat menu…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            LoadFailedView(message: message) { store.send(.retryTapped) }
                .frame(maxHeight: .infinity)

        case .loaded:
            if state.sections.isEmpty {
                ContentUnavailableView.search(text: state.query)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.m, pinnedViews: .sectionHeaders) {
                        ForEach(state.sections) { section in
                            Section {
                                ForEach(section.products) { product in
                                    ProductRowView(product: product) { store.send(.quickAddTapped(product)) }
                                        .onTapGesture { store.send(.productTapped(product)) }
                                }
                            } header: {
                                Text("\(section.category.icon)  \(section.category.name)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, Spacing.s)
                                    .background(Color.appBackground)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, state.cart.isEmpty ? Spacing.xl : 96)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
}
