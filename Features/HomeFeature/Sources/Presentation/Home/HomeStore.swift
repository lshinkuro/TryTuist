//
//  HomeStore.swift
//  HomeFeature · Presentation
//
import Foundation
import TTUI
import Utility

struct HomeState: Equatable {
    var userName = "Ishinkuro"
    var deliveryAddress = "Jl. Sudirman No. 21, Jakarta"
    var content: Loadable<HomeContent> = .idle
    var bannerPage = 0
    var cart: CartSummary = .empty
    var toast: ToastMessage?
    /// Popup promo yang sedang tampil.
    var promoPopup: PromoPopup?
    /// Popup hanya dicek sekali per sesi Beranda (bukan setiap retry / kembali ke tab).
    var didCheckPromoPopup = false

    var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 4..<11: return "Selamat pagi ☀️"
        case 11..<15: return "Selamat siang 🌤️"
        case 15..<18: return "Selamat sore 🌇"
        default: return "Selamat malam 🌙"
        }
    }
}

enum HomeAction {
    case onAppear
    case retryTapped
    case contentResponse(Result<HomeContent, CatalogError>)
    case bannerPageChanged(Int)
    case productTapped(Product)
    case quickAddTapped(Product)
    case quickAddResponse(Result<Product, CartError>)
    case categoryTapped(MenuCategory)
    case seeAllTapped
    case cartTapped
    case cartChanged(CartSummary)
    case toastRequested(ToastMessage)
    case toastDismissed(UUID)
    case promoPopupResponse(PromoPopup?)
    case promoPopupClosed
    case promoPopupTapped
}

enum HomeRoute {
    case productDetail(Product)
    case category(MenuCategory)
    case allMenu
    case cart
    case showPromoPopup(PromoPopup)
    /// Popup ditutup (tombol X / tap di luar kartu).
    case hidePromoPopup
    /// Popup di-tap → tutup popup lalu buka detail produk promo.
    case promoProduct(Product)
}

final class HomeStore: Store<HomeState, HomeAction> {
    private let getHomeContent: GetHomeContentUseCase
    private let addToCart: AddToCartUseCase
    private let getPromoPopup: GetPromoPopupUseCase
    private let dismissPromoPopup: DismissPromoPopupUseCase
    var onRoute: ((HomeRoute) -> Void)?

    init(getHomeContent: GetHomeContentUseCase, addToCart: AddToCartUseCase, cart: CartRepository,
         getPromoPopup: GetPromoPopupUseCase, dismissPromoPopup: DismissPromoPopupUseCase) {
        self.getHomeContent = getHomeContent
        self.addToCart = addToCart
        self.getPromoPopup = getPromoPopup
        self.dismissPromoPopup = dismissPromoPopup
        super.init(initialState: HomeState())
        bind(cart.summaryPublisher) { .cartChanged($0) }
    }

    override func reduce(state: inout HomeState, action: HomeAction) -> Effect<HomeAction>? {
        switch action {
        case .onAppear:
            guard state.content.isIdle else { return nil }
            return load(&state)

        case .retryTapped:
            return load(&state)

        case .contentResponse(.success(let content)):
            state.content = .loaded(content)
            // Popup muncul setelah Beranda tampil, supaya tidak menutupi skeleton/error.
            guard !state.didCheckPromoPopup else { return nil }
            state.didCheckPromoPopup = true
            let getPromoPopup = self.getPromoPopup
            return .task { .promoPopupResponse(await getPromoPopup.execute()) }

        case .contentResponse(.failure(let error)):
            state.content = .failed(error.errorDescription ?? "")
            return nil

        case .bannerPageChanged(let page):
            state.bannerPage = page
            return nil

        case .productTapped(let product):
            return route(.productDetail(product))

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

        case .categoryTapped(let category):
            return route(.category(category))

        case .seeAllTapped:
            return route(.allMenu)

        case .cartTapped:
            return route(.cart)

        case .cartChanged(let summary):
            state.cart = summary
            return nil

        case .toastRequested(let toast):
            return showToast(&state, toast)

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil

        case .promoPopupResponse(let popup):
            guard let popup, state.promoPopup == nil else { return nil }
            state.promoPopup = popup
            return route(.showPromoPopup(popup))

        case .promoPopupClosed:
            guard let popup = state.promoPopup else { return nil }
            state.promoPopup = nil
            dismissPromoPopup.execute(popup)
            return route(.hidePromoPopup)

        case .promoPopupTapped:
            guard let popup = state.promoPopup else { return nil }
            state.promoPopup = nil
            dismissPromoPopup.execute(popup)
            return route(.promoProduct(popup.product))
        }
    }

    // MARK: - Helpers

    private func load(_ state: inout HomeState) -> Effect<HomeAction> {
        state.content = .loading
        let getHomeContent = self.getHomeContent
        return .task {
            do {
                return .contentResponse(.success(try await getHomeContent.execute()))
            } catch {
                return .contentResponse(.failure(error as? CatalogError ?? .unknown))
            }
        }
    }

    private func showToast(_ state: inout HomeState, _ toast: ToastMessage) -> Effect<HomeAction> {
        state.toast = toast
        return dismissToastEffect(id: toast.id) { .toastDismissed($0) }
    }

    private func route(_ route: HomeRoute) -> Effect<HomeAction> {
        .run { [weak self] in self?.onRoute?(route) }
    }
}
