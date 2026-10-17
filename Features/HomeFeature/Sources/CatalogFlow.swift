//
//  CatalogFlow.swift
//  HomeFeature
//
//  Routing bersama Beranda & Menu: merakit Store tiap screen lalu menempelkannya ke Router.
//  Store hanya mengirim Route; keputusan push/present ada di sini.
//
import SwiftUI
import Navigation
import TTUI

@MainActor
final class CatalogFlow {
    private weak var router: Router?
    private let container: CatalogContainer

    init(router: Router, container: CatalogContainer = .shared) {
        self.router = router
        self.container = container
    }

    // MARK: - Root screens

    func makeHome() -> some View {
        let store = HomeStore(getHomeContent: container.getHomeContent,
                              addToCart: container.addToCart,
                              cart: container.cartRepository)
        store.onRoute = { [weak self, weak store] route in
            switch route {
            case .productDetail(let product):
                self?.showProductDetail(product) { store?.send(.toastRequested($0)) }
            case .category(let category):
                self?.showMenu(categoryID: category.id, title: category.name)
            case .allMenu:
                self?.showMenu(categoryID: nil, title: "Semua Menu")
            case .cart:
                self?.showCart()
            }
        }
        return HomeView(store: store)
    }

    func makeMenu(isRootScreen: Bool, categoryID: String? = nil) -> some View {
        let store = MenuStore(getMenu: container.getMenu,
                              addToCart: container.addToCart,
                              cart: container.cartRepository,
                              isRootScreen: isRootScreen,
                              initialCategoryID: categoryID)
        store.onRoute = { [weak self, weak store] route in
            switch route {
            case .productDetail(let product):
                self?.showProductDetail(product) { store?.send(.toastRequested($0)) }
            case .cart:
                self?.showCart()
            }
        }
        return MenuView(store: store)
    }

    // MARK: - Pushed / presented screens

    private func showMenu(categoryID: String?, title: String) {
        router?.push(makeMenu(isRootScreen: false, categoryID: categoryID), title: title)
    }

    /// - Parameter onAdded: dipanggil setelah detail ditutup, untuk menampilkan toast di screen sebelumnya.
    private func showProductDetail(_ product: Product, onAdded: @escaping (ToastMessage) -> Void) {
        let store = ProductDetailStore(product: product, addToCart: container.addToCart)
        store.onRoute = { [weak self] route in
            switch route {
            case .addedToCart(let toast):
                self?.router?.pop()
                onAdded(toast)
            }
        }
        router?.push(ProductDetailView(store: store))
    }

    private func showCart() {
        let store = CartStore(cart: container.cartRepository)
        store.onRoute = { [weak self] route in
            switch route {
            case .close: self?.router?.dismiss()
            }
        }
        router?.present(CartView(store: store), title: "Keranjang")
    }
}
