//
//  MenuStore.swift
//  HomeFeature · Presentation
//
//  Dipakai di dua tempat: root tab "Menu" dan screen kategori yang di-push dari Beranda.
//
import Combine
import Foundation
import TTUI
import Utility

struct MenuSection: Identifiable, Equatable {
    let category: MenuCategory
    let products: [Product]
    var id: String { category.id }
}

struct MenuState: Equatable {
    /// `true` = root tab (pakai header besar); `false` = di-push (pakai navigation bar).
    let isRootScreen: Bool
    var query = ""
    /// nil = semua kategori
    var selectedCategoryID: String?
    var content: Loadable<MenuContent> = .idle
    /// Pull-to-refresh berjalan: daftar lama tetap tampil.
    var isRefreshing = false
    var cart: CartSummary = .empty
    var toast: ToastMessage?
    /// Outlet yang stoknya sedang ditampilkan (nil = stok pusat).
    var outletID: String?
    /// Apple Intelligence tersedia di perangkat ini → Enter di kolom cari memakai pencarian AI.
    var isSmartSearchAvailable = false
    var isSmartSearching = false
    /// Hasil pencarian AI untuk `query` sekarang; `nil` = pakai pencarian kata kunci.
    var smartResultIDs: [String]?
    /// Mic aktif (pencarian suara).
    var isListening = false

    /// Hasil filter kategori + pencarian, dikelompokkan per kategori. Dihitung dari state, tidak disimpan.
    var sections: [MenuSection] {
        guard let content = content.value else { return [] }
        let keyword = query.trimmingCharacters(in: .whitespaces).lowercased()
        let smartIDs = smartResultIDs.map(Set.init)
        return content.categories
            .filter { selectedCategoryID == nil || $0.id == selectedCategoryID }
            .compactMap { (category) -> MenuSection? in
                let products = content.products.filter { product in
                    product.categoryID == category.id
                        && (smartIDs.map { $0.contains(product.id) } ?? (keyword.isEmpty
                            || product.name.lowercased().contains(keyword)
                            || product.description.lowercased().contains(keyword)))
                }
                return products.isEmpty ? nil : MenuSection(category: category, products: products)
            }
    }
}

enum MenuAction {
    case onAppear
    case retryTapped
    case refreshPulled
    case contentResponse(Result<MenuContent, CatalogError>)
    case queryChanged(String)
    case querySubmitted
    case smartSearchResponse(query: String, productIDs: [String]?)
    case shoppingListTapped
    case micTapped
    case voiceEvent(VoiceSearchEvent)
    case categorySelected(String?)
    case productTapped(Product)
    case quickAddTapped(Product)
    case quickAddResponse(Result<Product, CartError>)
    case cartTapped
    case cartChanged(CartSummary)
    case outletChanged(String?)
    case toastRequested(ToastMessage)
    case toastDismissed(UUID)
}

enum MenuRoute {
    case productDetail(Product)
    case cart
    case shoppingList
}

final class MenuStore: Store<MenuState, MenuAction> {
    private let getMenu: GetMenuUseCase
    private let addToCart: AddToCartUseCase
    private let smartSearch: SmartProductSearch
    private let voiceSearch: VoiceSearch
    var onRoute: ((MenuRoute) -> Void)?

    init(getMenu: GetMenuUseCase,
         addToCart: AddToCartUseCase,
         smartSearch: SmartProductSearch,
         voiceSearch: VoiceSearch,
         cart: CartRepository,
         outlets: OutletSelectionRepository,
         isRootScreen: Bool,
         initialCategoryID: String? = nil) {
        self.getMenu = getMenu
        self.addToCart = addToCart
        self.smartSearch = smartSearch
        self.voiceSearch = voiceSearch
        var initial = MenuState(isRootScreen: isRootScreen, selectedCategoryID: initialCategoryID)
        initial.isSmartSearchAvailable = smartSearch.isAvailable
        initial.outletID = outlets.savedOutletID
        super.init(initialState: initial)
        bind(cart.summaryPublisher) { .cartChanged($0) }
        bind(voiceSearch.events) { .voiceEvent($0) }
        // Ganti outlet di Beranda → stok di Menu ikut berubah.
        bind(outlets.selectedPublisher.compactMap { $0?.id }.removeDuplicates()) { .outletChanged($0) }
    }

    override func reduce(state: inout MenuState, action: MenuAction) -> Effect<MenuAction>? {
        switch action {
        case .onAppear:
            guard state.content.isIdle else { return nil }
            return load(&state)

        case .retryTapped:
            return load(&state)

        case .refreshPulled:
            guard !state.isRefreshing, !state.content.isLoading else { return nil }
            state.isRefreshing = true
            return load(&state, silently: true)

        case .contentResponse(.success(let content)):
            state.isRefreshing = false
            state.content = .loaded(content)
            return nil

        case .contentResponse(.failure(let error)) where state.isRefreshing && state.content.value != nil:
            state.isRefreshing = false
            return showToast(&state, .error(error.errorDescription ?? ""))

        case .contentResponse(.failure(let error)):
            state.isRefreshing = false
            state.content = .failed(error.errorDescription ?? "")
            return nil

        case .queryChanged(let query):
            state.query = query
            state.smartResultIDs = nil
            state.isSmartSearching = false
            return nil

        case .querySubmitted:
            let query = state.query.trimmingCharacters(in: .whitespaces)
            guard state.isSmartSearchAvailable, !query.isEmpty, let products = state.content.value?.products
            else { return nil }
            state.isSmartSearching = true
            let smartSearch = self.smartSearch
            let submitted = state.query
            return .task { .smartSearchResponse(query: submitted, productIDs: await smartSearch.search(query, in: products)) }

        case .smartSearchResponse(let query, let ids):
            // Query sudah diubah selama AI berpikir → hasil basi, abaikan.
            guard query == state.query else { return nil }
            state.isSmartSearching = false
            state.smartResultIDs = ids
            return nil

        case .categorySelected(let id):
            state.selectedCategoryID = id
            return nil

        case .productTapped(let product):
            return .run { [weak self] in self?.onRoute?(.productDetail(product)) }

        case .quickAddTapped(let product):
            let addToCart = self.addToCart
            return .task {
                do {
                    try await addToCart.execute(product: product, option: nil, quantity: 1)
                    return .quickAddResponse(.success(product))
                } catch {
                    return .quickAddResponse(.failure(error as? CartError ?? .productUnavailable))
                }
            }

        case .quickAddResponse(.success(let product)):
            return showToast(&state, ToastMessage(String(localized: "\(product.name) masuk keranjang")))

        case .quickAddResponse(.failure(let error)):
            return showToast(&state, .error(error.errorDescription ?? ""))

        case .cartTapped:
            return .run { [weak self] in self?.onRoute?(.cart) }

        case .shoppingListTapped:
            return .run { [weak self] in self?.onRoute?(.shoppingList) }

        case .micTapped:
            let voiceSearch = self.voiceSearch
            if state.isListening {
                return .run { voiceSearch.finish() }
            }
            state.isListening = true
            state.query = ""
            state.smartResultIDs = nil
            return .task {
                await voiceSearch.start()
                return nil
            }

        case .voiceEvent(.transcript(let text, let isFinal)):
            state.query = text
            state.smartResultIDs = nil
            guard isFinal else { return nil }
            state.isListening = false
            // Kalimat panjang ("yang manis buat sarapan") langsung dicari AI bila tersedia.
            return reduce(state: &state, action: .querySubmitted)

        case .voiceEvent(.failed(let message)):
            state.isListening = false
            return showToast(&state, .error(message))

        case .cartChanged(let summary):
            state.cart = summary
            return nil

        case .outletChanged(let id):
            guard id != state.outletID else { return nil }
            state.outletID = id
            // Belum pernah dimuat → biarkan onAppear yang memuat.
            return state.content.isIdle ? nil : load(&state)

        case .toastRequested(let toast):
            return showToast(&state, toast)

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func load(_ state: inout MenuState, silently: Bool = false) -> Effect<MenuAction> {
        if !silently || state.content.value == nil { state.content = .loading }
        let getMenu = self.getMenu
        let storeID = state.outletID
        return .task {
            do {
                return .contentResponse(.success(try await getMenu.execute(storeID: storeID)))
            } catch {
                return .contentResponse(.failure(error as? CatalogError ?? .unknown))
            }
        }
    }

    private func showToast(_ state: inout MenuState, _ toast: ToastMessage) -> Effect<MenuAction> {
        state.toast = toast
        return dismissToastEffect(id: toast.id) { .toastDismissed($0) }
    }
}
