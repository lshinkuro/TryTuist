//
//  HomeStore.swift
//  HomeFeature · Presentation
//
import Foundation
import TTUI
import Utility

struct HomeState: Equatable {
    var userName = "Ishinkuro"
    var content: Loadable<HomeContent> = .idle
    var bannerPage = 0
    var cart: CartSummary = .empty
    var toast: ToastMessage?
    /// Popup promo yang sedang tampil.
    var promoPopup: PromoPopup?
    /// Popup hanya dicek sekali per sesi Beranda (bukan setiap retry / kembali ke tab).
    var didCheckPromoPopup = false
    /// Sheet "Pilih outlet".
    var isOutletPickerPresented = false
    /// Outlet yang sedang diganti (spinner di baris itu).
    var switchingOutletID: String?
    /// Disimpan terpisah dari `content` supaya header outlet tetap tampil saat Beranda dimuat ulang.
    var outletChoice: OutletChoice = .empty
    /// Toast ganti outlet yang ditutup setelah Beranda selesai dimuat ulang.
    var toastAwaitingReload: UUID?

    var outlet: Outlet? { outletChoice.selected }
    /// Pembayaran online yang belum diselesaikan (kartu "Menunggu pembayaran").
    var pendingPayment: PaymentSession?
    /// "Antar ke" (disimpan terpisah dari `content`, sama seperti outlet).
    var deliveryChoice: DeliveryChoice = .empty
    var isDeliverySheetPresented = false
    /// Sedang mengambil lokasi perangkat / mengganti alamat (spinner di sheet).
    var isUpdatingDelivery = false
    var locationPermission: LocationPermission?

    var delivery: DeliveryLocation? { deliveryChoice.selected }

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
    case outletPickerTapped
    case outletPickerDismissed
    case outletSelected(Outlet)
    case outletChangeResponse(Result<[String], CatalogError>)
    case refreshPendingPayment
    case pendingPaymentResponse(PaymentSession?)
    case pendingPaymentTapped
    case paymentFinished(PaymentOutcome)
    // Antar ke / lokasi
    case offerLocationPermission
    case locationPermissionResponse(LocationPermission?)
    case deliveryTapped
    case deliverySheetDismissed
    case deliveryAddressSelected(CheckoutAddress)
    case useCurrentLocationTapped
    case currentLocationResponse(Result<DeliveryLocation, LocationError>)
    case deliveryChangeResponse(Result<[String], CatalogError>)
    case manageAddressesTapped
    case openSettingsTapped
    /// Kembali ke Beranda (mis. setelah menambah alamat di Profil): segarkan daftar alamat.
    case refreshDeliveryChoice
    case deliveryChoiceResponse(DeliveryChoice)
}

/// Use case lokasi Beranda (digabung supaya init HomeStore tidak terlalu panjang).
struct HomeLocationUseCases {
    let resolveDelivery: ResolveDeliveryLocationUseCase
    let useCurrentLocation: UseCurrentLocationUseCase
    let changeDelivery: ChangeDeliveryLocationUseCase
    let offerPermission: OfferLocationPermissionUseCase
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
    /// Lanjutkan pembayaran online yang tertunda.
    case resumePayment(PaymentSession)
    /// Tab Profil → Alamat Pengiriman.
    case manageAddresses
    /// Pengaturan iOS (izin lokasi ditolak).
    case openSettings
}

final class HomeStore: Store<HomeState, HomeAction> {
    private let getHomeContent: GetHomeContentUseCase
    private let addToCart: AddToCartUseCase
    private let getPromoPopup: GetPromoPopupUseCase
    private let dismissPromoPopup: DismissPromoPopupUseCase
    private let changeOutlet: ChangeOutletUseCase
    private let getPendingPayment: GetPendingPaymentUseCase
    private let location: HomeLocationUseCases
    var onRoute: ((HomeRoute) -> Void)?

    init(getHomeContent: GetHomeContentUseCase, addToCart: AddToCartUseCase, cart: CartRepository,
         getPromoPopup: GetPromoPopupUseCase, dismissPromoPopup: DismissPromoPopupUseCase,
         changeOutlet: ChangeOutletUseCase, getPendingPayment: GetPendingPaymentUseCase,
         location: HomeLocationUseCases) {
        self.getHomeContent = getHomeContent
        self.addToCart = addToCart
        self.getPromoPopup = getPromoPopup
        self.dismissPromoPopup = dismissPromoPopup
        self.changeOutlet = changeOutlet
        self.getPendingPayment = getPendingPayment
        self.location = location
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
            if !content.outlet.outlets.isEmpty || state.outletChoice.selected == nil {
                state.outletChoice = content.outlet
            }
            state.deliveryChoice = content.delivery
            if let toastID = state.toastAwaitingReload {
                state.toastAwaitingReload = nil
                return dismissToastEffect(id: toastID) { .toastDismissed($0) }
            }
            // Popup muncul setelah Beranda tampil, supaya tidak menutupi skeleton/error.
            guard !state.didCheckPromoPopup else { return nil }
            state.didCheckPromoPopup = true
            let getPromoPopup = self.getPromoPopup
            return .task { .promoPopupResponse(await getPromoPopup.execute()) }

        case .contentResponse(.failure(let error)):
            state.content = .failed(error.errorDescription ?? "")
            if let toastID = state.toastAwaitingReload {
                state.toastAwaitingReload = nil
                return dismissToastEffect(id: toastID) { .toastDismissed($0) }
            }
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

        case .outletPickerTapped:
            guard !state.outletChoice.outlets.isEmpty else { return nil }
            state.isOutletPickerPresented = true
            return nil

        case .outletPickerDismissed:
            state.isOutletPickerPresented = false
            return nil

        case .outletSelected(let outlet):
            guard state.switchingOutletID == nil else { return nil }
            guard outlet.id != state.outlet?.id else {
                state.isOutletPickerPresented = false
                return nil
            }
            state.switchingOutletID = outlet.id
            let changeOutlet = self.changeOutlet
            return .task {
                do {
                    return .outletChangeResponse(.success(try await changeOutlet.execute(outlet)))
                } catch {
                    return .outletChangeResponse(.failure(error as? CatalogError ?? .unknown))
                }
            }

        case .outletChangeResponse(.success(let removedNames)):
            let outlet = state.outletChoice.outlets.first { $0.id == state.switchingOutletID }
            state.switchingOutletID = nil
            state.isOutletPickerPresented = false
            if let outlet {
                state.outletChoice = OutletChoice(outlets: state.outletChoice.outlets, selected: outlet)
            }
            let name = outlet?.name ?? "outlet baru"
            let toast: ToastMessage = removedNames.isEmpty
                ? ToastMessage("Sekarang pesan dari \(name)")
                : .error("\(removedNames.joined(separator: ", ")) habis di \(name), dikeluarkan dari keranjang")
            state.toast = toast
            state.toastAwaitingReload = toast.id
            // Stok berbeda per outlet → muat ulang Beranda; toast ditutup setelah selesai.
            return load(&state)

        case .refreshPendingPayment:
            let getPendingPayment = self.getPendingPayment
            return .task { .pendingPaymentResponse(await getPendingPayment.execute()) }

        case .pendingPaymentResponse(let session):
            state.pendingPayment = session
            return nil

        case .pendingPaymentTapped:
            guard let session = state.pendingPayment else { return nil }
            return route(.resumePayment(session))

        case .paymentFinished(.paid(let order)):
            state.pendingPayment = nil
            return showToast(&state, ToastMessage("Pembayaran berhasil · pesanan \(order.orderNumber)"))

        case .paymentFinished(.notPaid(let message)):
            state.pendingPayment = nil
            return showToast(&state, .error(message))

        case .paymentFinished(.later):
            let getPendingPayment = self.getPendingPayment
            return .task { .pendingPaymentResponse(await getPendingPayment.execute()) }

        // MARK: Antar ke / lokasi

        case .offerLocationPermission:
            let offer = location.offerPermission
            return .task { .locationPermissionResponse(await offer.execute()) }

        case .locationPermissionResponse(let permission):
            guard let permission else { return nil }
            state.locationPermission = permission
            // Baru diizinkan & belum ada alamat tersimpan → pakai lokasi perangkat untuk outlet terdekat.
            if permission == .authorized, state.deliveryChoice.addresses.isEmpty, state.delivery == nil {
                return load(&state)
            }
            return nil

        case .deliveryTapped:
            state.isDeliverySheetPresented = true
            return nil

        case .deliverySheetDismissed:
            state.isDeliverySheetPresented = false
            return nil

        case .deliveryAddressSelected(let address):
            guard !state.isUpdatingDelivery else { return nil }
            guard address.id != state.delivery?.savedAddressID else {
                state.isDeliverySheetPresented = false
                return nil
            }
            return changeDelivery(&state, .saved(address))

        case .useCurrentLocationTapped:
            guard !state.isUpdatingDelivery else { return nil }
            state.isUpdatingDelivery = true
            let useCurrentLocation = location.useCurrentLocation
            return .task {
                do {
                    return .currentLocationResponse(.success(try await useCurrentLocation.execute()))
                } catch {
                    return .currentLocationResponse(.failure(error as? LocationError ?? .unavailable))
                }
            }

        case .currentLocationResponse(.success(let current)):
            state.isUpdatingDelivery = false
            state.locationPermission = .authorized
            return changeDelivery(&state, current)

        case .currentLocationResponse(.failure(let error)):
            state.isUpdatingDelivery = false
            if error == .denied { state.locationPermission = .denied }
            return showToast(&state, .error(error.errorDescription ?? ""))

        case .deliveryChangeResponse(.success(let removedNames)):
            state.isUpdatingDelivery = false
            state.isDeliverySheetPresented = false
            let title = state.delivery?.title ?? "alamat baru"
            let toast: ToastMessage = removedNames.isEmpty
                ? ToastMessage("Antar ke \(title)")
                : .error("\(removedNames.joined(separator: ", ")) habis di outlet terdekat, dikeluarkan dari keranjang")
            state.toast = toast
            state.toastAwaitingReload = toast.id
            // Outlet terdekat & stok bisa berubah → muat ulang Beranda.
            return load(&state)

        case .deliveryChangeResponse(.failure(let error)):
            state.isUpdatingDelivery = false
            return showToast(&state, .error(error.errorDescription ?? "Gagal mengganti alamat."))

        case .manageAddressesTapped:
            state.isDeliverySheetPresented = false
            return route(.manageAddresses)

        case .openSettingsTapped:
            return route(.openSettings)

        case .refreshDeliveryChoice:
            // Pemuatan pertama sudah mengisi pilihan; ini hanya untuk kunjungan berikutnya.
            guard state.content.value != nil, !state.isUpdatingDelivery else { return nil }
            let resolveDelivery = location.resolveDelivery
            return .task { .deliveryChoiceResponse(await resolveDelivery.execute()) }

        case .deliveryChoiceResponse(let choice):
            let previous = state.delivery
            state.deliveryChoice = choice
            // Alamat yang dipakai dihapus / alamat pertama baru ditambah → outlet terdekat dihitung ulang.
            // Lokasi saat ini yang bergeser sedikit tidak dihitung sebagai perubahan.
            guard let selected = choice.selected else { return nil }
            let changed = selected.source != previous?.source
                || (selected.savedAddressID != nil && (selected.point != previous?.point || selected.subtitle != previous?.subtitle))
            if changed {
                return changeDelivery(&state, selected)
            }
            return nil

        case .outletChangeResponse(.failure(let error)):
            state.switchingOutletID = nil
            return showToast(&state, .error(error.errorDescription ?? "Gagal mengganti outlet."))
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

    /// Pilih "Antar ke" → outlet terbaik untuk titik itu (header langsung berubah, Beranda dimuat ulang).
    private func changeDelivery(_ state: inout HomeState, _ location: DeliveryLocation) -> Effect<HomeAction> {
        state.isUpdatingDelivery = true
        state.deliveryChoice = DeliveryChoice(selected: location, addresses: state.deliveryChoice.addresses)
        let changeDelivery = self.location.changeDelivery
        return .task {
            do {
                return .deliveryChangeResponse(.success(try await changeDelivery.execute(location)))
            } catch {
                return .deliveryChangeResponse(.failure(error as? CatalogError ?? .unknown))
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
