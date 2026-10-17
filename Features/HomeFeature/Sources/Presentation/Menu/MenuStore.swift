//
//  MenuStore.swift
//  HomeFeature · Presentation
//
//  Dipakai di dua tempat: root tab "Menu" dan screen kategori yang di-push dari Beranda.
//
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
    var cart: CartSummary = .empty
    var toast: ToastMessage?

    /// Hasil filter kategori + pencarian, dikelompokkan per kategori. Dihitung dari state, tidak disimpan.
    var sections: [MenuSection] {
        guard let content = content.value else { return [] }
        let keyword = query.trimmingCharacters(in: .whitespaces).lowercased()
        return content.categories
            .filter { selectedCategoryID == nil || $0.id == selectedCategoryID }
            .compactMap { (category) -> MenuSection? in
                let products = content.products.filter { product in
                    product.categoryID == category.id
                        && (keyword.isEmpty
                            || product.name.lowercased().contains(keyword)
                            || product.description.lowercased().contains(keyword))
                }
                return products.isEmpty ? nil : MenuSection(category: category, products: products)
            }
    }
}

enum MenuAction {
    case onAppear
    case retryTapped
    case contentResponse(Result<MenuContent, CatalogError>)
    case queryChanged(String)
    case categorySelected(String?)
    case productTapped(Product)
    case quickAddTapped(Product)
    case quickAddResponse(Result<Product, CartError>)
    case cartTapped
    case cartChanged(CartSummary)
    case toastRequested(ToastMessage)
    case toastDismissed(UUID)
}

enum MenuRoute {
    case productDetail(Product)
    case cart
}

final class MenuStore: Store<MenuState, MenuAction> {
    private let getMenu: GetMenuUseCase
    private let addToCart: AddToCartUseCase
    var onRoute: ((MenuRoute) -> Void)?

    init(getMenu: GetMenuUseCase,
         addToCart: AddToCartUseCase,
         cart: CartRepository,
         isRootScreen: Bool,
         initialCategoryID: String? = nil) {
        self.getMenu = getMenu
        self.addToCart = addToCart
        super.init(initialState: MenuState(isRootScreen: isRootScreen, selectedCategoryID: initialCategoryID))
        bind(cart.summaryPublisher) { .cartChanged($0) }
    }

    override func reduce(state: inout MenuState, action: MenuAction) -> Effect<MenuAction>? {
        switch action {
        case .onAppear:
            guard state.content.isIdle else { return nil }
            return load(&state)

        case .retryTapped:
            return load(&state)

        case .contentResponse(.success(let content)):
            state.content = .loaded(content)
            return nil

        case .contentResponse(.failure(let error)):
            state.content = .failed(error.errorDescription ?? "")
            return nil

        case .queryChanged(let query):
            state.query = query
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
            return showToast(&state, ToastMessage("\(product.name) masuk keranjang"))

        case .quickAddResponse(.failure(let error)):
            return showToast(&state, .error(error.errorDescription ?? ""))

        case .cartTapped:
            return .run { [weak self] in self?.onRoute?(.cart) }

        case .cartChanged(let summary):
            state.cart = summary
            return nil

        case .toastRequested(let toast):
            return showToast(&state, toast)

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func load(_ state: inout MenuState) -> Effect<MenuAction> {
        state.content = .loading
        let getMenu = self.getMenu
        return .task {
            do {
                return .contentResponse(.success(try await getMenu.execute()))
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
