//
//  CatalogContainer.swift
//  HomeFeature
//
//  Dependency bersama untuk tab Beranda & Menu: satu repository katalog
//  dan SATU keranjang, supaya isi keranjang sama di semua screen.
//
import Foundation
import Utility

@MainActor
final class CatalogContainer {
    /// `var` supaya bisa di-reset (Debugger / ganti server) → keranjang & cache katalog kosong lagi.
    private(set) static var shared = CatalogContainer()

    static func reset() {
        shared = CatalogContainer()
    }

    let catalogRepository: CatalogRepository
    let cartRepository: CartRepository
    let checkoutOptionsRepository: CheckoutOptionsRepository
    let promoPopupDismissals: PromoPopupDismissalStore = UserDefaultsPromoPopupDismissalStore()

    private init() {
        catalogRepository = DefaultCatalogRepository(remote: Self.makeRemoteDataSource())
        cartRepository = InMemoryCartRepository(checkoutSource: Self.makeCheckoutDataSource())
        checkoutOptionsRepository = DefaultCheckoutOptionsRepository(remote: Self.makeCheckoutOptionsDataSource())
    }

    private static func makeCheckoutOptionsDataSource() -> CheckoutOptionsRemoteDataSource {
        if AppConfig.useMockData { return CheckoutOptionsMockDataSource() }
        return CheckoutOptionsAPIDataSource()
    }

    private static func makeRemoteDataSource() -> CatalogRemoteDataSource {
        if AppConfig.useMockData { return CatalogMockDataSource() }
        return CatalogAPIDataSource()
    }

    private static func makeCheckoutDataSource() -> CheckoutRemoteDataSource {
        if AppConfig.useMockData { return CheckoutMockDataSource() }
        return CheckoutAPIDataSource()
    }

    // MARK: Use cases

    var getHomeContent: GetHomeContentUseCase { GetHomeContentUseCase(repository: catalogRepository) }
    var getMenu: GetMenuUseCase { GetMenuUseCase(repository: catalogRepository) }
    var addToCart: AddToCartUseCase { AddToCartUseCase(cart: cartRepository) }
    var getPromoPopup: GetPromoPopupUseCase {
        GetPromoPopupUseCase(repository: catalogRepository, dismissals: promoPopupDismissals)
    }
    var dismissPromoPopup: DismissPromoPopupUseCase { DismissPromoPopupUseCase(dismissals: promoPopupDismissals) }
}
