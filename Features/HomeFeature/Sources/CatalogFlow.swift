//
//  CatalogFlow.swift
//  HomeFeature
//
//  Routing bersama Beranda & Menu: merakit Store tiap screen lalu menempelkannya ke Router.
//  Store hanya mengirim Route; keputusan push/present ada di sini.
//
import SwiftUI
import UIKit
import Navigation
import TTUI

@MainActor
final class CatalogFlow {
    private weak var router: Router?
    private let container: CatalogContainer
    /// Navigasi ke luar feature (tab Profil), diteruskan ke AppRouter.
    private let onExternalRoute: (CatalogExternalRoute) -> Void
    private weak var promoPopupController: UIViewController?

    init(router: Router, container: CatalogContainer? = nil,
         onExternalRoute: @escaping (CatalogExternalRoute) -> Void = { _ in }) {
        self.router = router
        self.container = container ?? .shared
        self.onExternalRoute = onExternalRoute
    }

    // MARK: - Root screens

    func makeHome() -> some View {
        let store = HomeStore(getHomeContent: container.getHomeContent,
                              addToCart: container.addToCart,
                              cart: container.cartRepository,
                              getPromoPopup: container.getPromoPopup,
                              dismissPromoPopup: container.dismissPromoPopup)
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
            case .showPromoPopup(let popup):
                self?.showPromoPopup(popup,
                                     onClose: { store?.send(.promoPopupClosed) },
                                     onOpen: { store?.send(.promoPopupTapped) })
            case .hidePromoPopup:
                self?.hidePromoPopup()
            case .promoProduct(let product):
                // Detail dibuka setelah popup hilang; harga di detail sudah harga promo.
                self?.hidePromoPopup {
                    self?.showProductDetail(product) { store?.send(.toastRequested($0)) }
                }
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

    // MARK: - Popup promo

    /// Di atas seluruh layar (termasuk tab bar), fade in/out.
    private func showPromoPopup(_ popup: PromoPopup, onClose: @escaping () -> Void, onOpen: @escaping () -> Void) {
        guard let navigationController = router?.navigationController,
              navigationController.presentedViewController == nil,
              promoPopupController == nil else {
            return   // Ada sheet lain (mis. sesi habis); popup dicoba lagi di pembukaan berikutnya.
        }
        let controller = UIHostingController(rootView: PromoPopupView(popup: popup, onClose: onClose, onOpen: onOpen))
        controller.view.backgroundColor = .clear
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        promoPopupController = controller
        navigationController.present(controller, animated: true)
    }

    private func hidePromoPopup(completion: (() -> Void)? = nil) {
        guard let controller = promoPopupController, controller.presentingViewController != nil else {
            completion?()
            return
        }
        controller.dismiss(animated: true, completion: completion)
    }

    /// Dipakai shortcut Debugger.
    func openCart() {
        showCart()
    }

    private func showCart() {
        let store = CartStore(cart: container.cartRepository, options: container.checkoutOptionsRepository)
        store.onRoute = { [weak self] route in
            switch route {
            case .close:
                self?.router?.dismiss()
            case .manageAddresses:
                self?.leaveCart(to: .manageAddresses)
            case .managePaymentMethods:
                self?.leaveCart(to: .managePaymentMethods)
            }
        }
        router?.present(CartView(store: store), title: "Keranjang")
    }

    /// Tutup keranjang dulu (isinya tetap tersimpan), lalu pindah ke tab Profil.
    private func leaveCart(to route: CatalogExternalRoute) {
        let onExternalRoute = self.onExternalRoute
        router?.navigationController.dismiss(animated: true) {
            onExternalRoute(route)
        }
    }

}
