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
    let paymentRepository: PaymentRepository
    let promoPopupDismissals: PromoPopupDismissalStore = UserDefaultsPromoPopupDismissalStore()
    /// Outlet asal pesanan, bersama untuk Beranda, Menu & Keranjang.
    let outletSelection: OutletSelectionRepository = UserDefaultsOutletSelectionRepository()
    /// "Antar ke" di Beranda (alamat tersimpan / lokasi saat ini), juga default alamat Keranjang.
    let deliveryLocation: DeliveryLocationRepository = UserDefaultsDeliveryLocationRepository()
    let locationService: LocationService = CoreLocationService()

    private init() {
        catalogRepository = DefaultCatalogRepository(remote: Self.makeRemoteDataSource())
        cartRepository = InMemoryCartRepository(checkoutSource: Self.makeCheckoutDataSource())
        checkoutOptionsRepository = DefaultCheckoutOptionsRepository(remote: Self.makeCheckoutOptionsDataSource())
        paymentRepository = DefaultPaymentRepository(remote: AppConfig.useMockData
                                                     ? PaymentMockDataSource() as PaymentRemoteDataSource
                                                     : PaymentAPIDataSource())
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

    var getHomeContent: GetHomeContentUseCase {
        GetHomeContentUseCase(repository: catalogRepository, resolveDelivery: resolveDelivery, resolveOutlet: resolveOutlet)
    }
    var resolveDelivery: ResolveDeliveryLocationUseCase {
        ResolveDeliveryLocationUseCase(checkoutOptions: checkoutOptionsRepository, delivery: deliveryLocation,
                                       location: locationService)
    }
    var useCurrentLocation: UseCurrentLocationUseCase { UseCurrentLocationUseCase(location: locationService) }
    var changeDeliveryLocation: ChangeDeliveryLocationUseCase {
        ChangeDeliveryLocationUseCase(repository: catalogRepository, delivery: deliveryLocation,
                                      outlets: outletSelection, changeOutlet: changeOutlet)
    }
    var offerLocationPermission: OfferLocationPermissionUseCase {
        OfferLocationPermissionUseCase(location: locationService, delivery: deliveryLocation)
    }
    var resolveOutlet: ResolveOutletUseCase {
        ResolveOutletUseCase(repository: catalogRepository, selection: outletSelection)
    }
    var changeOutlet: ChangeOutletUseCase {
        ChangeOutletUseCase(repository: catalogRepository, cart: cartRepository, selection: outletSelection)
    }
    var getMenu: GetMenuUseCase { GetMenuUseCase(repository: catalogRepository) }
    var addToCart: AddToCartUseCase { AddToCartUseCase(cart: cartRepository) }
    var getFavorites: GetFavoritesUseCase { GetFavoritesUseCase(repository: catalogRepository, outlets: outletSelection) }
    var setFavorite: SetFavoriteUseCase { SetFavoriteUseCase(repository: catalogRepository) }
    var reorder: ReorderUseCase {
        ReorderUseCase(repository: catalogRepository, selection: outletSelection, addToCart: addToCart)
    }
    var getProduct: GetProductUseCase { GetProductUseCase(repository: catalogRepository, outlets: outletSelection) }
    var getPromoPopup: GetPromoPopupUseCase {
        GetPromoPopupUseCase(repository: catalogRepository, dismissals: promoPopupDismissals, outlets: outletSelection)
    }
    var checkPayment: CheckPaymentUseCase { CheckPaymentUseCase(repository: paymentRepository) }
    var cancelPayment: CancelPaymentUseCase { CancelPaymentUseCase(repository: paymentRepository) }
    var simulatePayment: SimulatePaymentUseCase { SimulatePaymentUseCase(repository: paymentRepository) }
    var getPendingPayment: GetPendingPaymentUseCase { GetPendingPaymentUseCase(repository: paymentRepository) }
    var finishPayment: FinishPaymentUseCase { FinishPaymentUseCase(cart: cartRepository) }
    var dismissPromoPopup: DismissPromoPopupUseCase { DismissPromoPopupUseCase(dismissals: promoPopupDismissals) }
}
