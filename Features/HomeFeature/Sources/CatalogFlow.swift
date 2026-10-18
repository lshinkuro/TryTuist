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
    private weak var paymentController: UIViewController?
    /// Untuk menyegarkan kartu "Menunggu pembayaran" setelah Keranjang ditutup.
    private weak var homeStore: HomeStore?

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
                              dismissPromoPopup: container.dismissPromoPopup,
                              changeOutlet: container.changeOutlet,
                              getPendingPayment: container.getPendingPayment,
                              location: HomeLocationUseCases(resolveDelivery: container.resolveDelivery,
                                                             useCurrentLocation: container.useCurrentLocation,
                                                             changeDelivery: container.changeDeliveryLocation,
                                                             offerPermission: container.offerLocationPermission))
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
            case .manageAddresses:
                self?.onExternalRoute(.manageAddresses)
            case .openSettings:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            case .resumePayment(let session):
                self?.showPayment(session) { outcome in store?.send(.paymentFinished(outcome)) }
            case .promoProduct(let product):
                // Detail dibuka setelah popup hilang; harga di detail sudah harga promo.
                self?.hidePromoPopup {
                    self?.showProductDetail(product) { store?.send(.toastRequested($0)) }
                }
            }
        }
        homeStore = store
        return HomeView(store: store)
    }

    func makeMenu(isRootScreen: Bool, categoryID: String? = nil) -> some View {
        let store = MenuStore(getMenu: container.getMenu,
                              addToCart: container.addToCart,
                              cart: container.cartRepository,
                              outlets: container.outletSelection,
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

    func reorder(_ items: [CatalogReorderItem]) {
        let reorder = container.reorder
        Task { [weak self] in
            do {
                let result = try await reorder.execute(items)
                if !result.skipped.isEmpty {
                    self?.homeStore?.send(.toastRequested(.error("Sedang tidak tersedia: \(result.skipped.joined(separator: ", "))")))
                }
                if result.added > 0 { self?.showCart() }
            } catch {
                self?.homeStore?.send(.toastRequested(.error("Gagal memuat menu. Coba lagi.")))
            }
        }
    }

    private func showCart() {
        let store = CartStore(cart: container.cartRepository, options: container.checkoutOptionsRepository,
                              outlets: container.outletSelection, delivery: container.deliveryLocation)
        store.onRoute = { [weak self, weak store] route in
            switch route {
            case .close:
                self?.router?.dismiss()
                self?.homeStore?.send(.refreshPendingPayment)
            case .payment(let session):
                self?.showPayment(session) { outcome in store?.send(.paymentFinished(outcome)) }
            case .manageAddresses:
                self?.leaveCart(to: .manageAddresses)
            case .managePaymentMethods:
                self?.leaveCart(to: .managePaymentMethods)
            }
        }
        router?.present(CartView(store: store), title: "Keranjang")
    }

    // MARK: - Pembayaran online (§5.27)

    /// Layar Pembayaran layar penuh di atas screen paling atas (Keranjang atau Beranda).
    private func showPayment(_ session: PaymentSession, onFinish: @escaping (PaymentOutcome) -> Void) {
        guard paymentController == nil, let navigationController = router?.navigationController else { return }
        let store = PaymentStore(session: session,
                                 checkPayment: container.checkPayment,
                                 cancelPayment: container.cancelPayment,
                                 finishPayment: container.finishPayment)
        let controller = UIHostingController(rootView: PaymentView(store: store))
        controller.modalPresentationStyle = .fullScreen
        store.onRoute = { [weak controller] route in
            switch route {
            case .finished(let outcome):
                controller?.dismiss(animated: true) { onFinish(outcome) }
            }
        }
        paymentController = controller
        var top: UIViewController = navigationController
        while let presented = top.presentedViewController { top = presented }
        top.present(controller, animated: true)
    }

    /// Tutup keranjang dulu (isinya tetap tersimpan), lalu pindah ke tab Profil.
    private func leaveCart(to route: CatalogExternalRoute) {
        let onExternalRoute = self.onExternalRoute
        router?.navigationController.dismiss(animated: true) {
            onExternalRoute(route)
        }
    }

}
