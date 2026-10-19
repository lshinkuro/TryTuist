//
//  CartStore.swift
//  HomeFeature · Presentation
//
//  Keranjang + pilihan "Antar ke" & "Pembayaran". Defaultnya alamat & metode utama user
//  (dari tab Profil); pilihan di sini hanya berlaku untuk pesanan ini.
//  Ongkir & total dihitung server (`POST /v1/orders/quote`) setiap isi atau pilihan berubah.
//
import Foundation
import TTUI
import Utility

/// Sheet pilihan di Keranjang.
enum CartSheet: String, Identifiable {
    case address
    case payment

    var id: String { rawValue }
}

struct CartState: Equatable {
    var items: [CartItem] = []
    var isCheckingOut = false
    var errorMessage: String?
    var placedOrder: PlacedOrder?

    var options: Loadable<CheckoutOptions> = .idle
    var selectedAddressID: String?
    var selectedPaymentID: String?
    var activeSheet: CartSheet?
    /// Outlet asal pesanan (dipilih di Beranda).
    var outlet: Outlet?

    /// Harga resmi dari server untuk isi & pilihan saat ini; `nil` = belum / gagal dihitung.
    var quote: CartQuote?
    var isQuoting = false
    var quoteError: String?
    /// Naik setiap isi / pilihan berubah; hasil quote yang lebih lama diabaikan.
    var quoteVersion = 0
    /// Kupon gratis ongkir diaktifkan user untuk pesanan ini.
    var useFreeDelivery = false
    /// Pesan saat kupon otomatis dimatikan (habis / fitur dinonaktifkan).
    var freeDeliveryNote: String?

    var subtotal: Decimal { items.reduce(0) { $0 + $1.subtotal } }
    /// Selama menghitung ulang, ongkir lama tetap ditampilkan supaya angka tidak berkedip.
    var total: Decimal {
        guard let quote else { return subtotal }
        return isQuoting ? subtotal + quote.deliveryFee - quote.discount : quote.total
    }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    var addresses: [CheckoutAddress] { options.value?.addresses ?? [] }
    var paymentMethods: [CheckoutPaymentMethod] { options.value?.paymentMethods ?? [] }
    var selectedAddress: CheckoutAddress? { addresses.first { $0.id == selectedAddressID } }
    var selectedPayment: CheckoutPaymentMethod? { paymentMethods.first { $0.id == selectedPaymentID } }

    /// Pilihan sudah termuat tapi user belum punya alamat → wajib tambah dulu.
    var needsAddress: Bool { options.value != nil && addresses.isEmpty }

    /// Bila pilihan gagal dimuat, checkout tetap boleh: server memakai default user.
    /// Harga harus sudah dihitung server, supaya total di tombol = yang ditagih.
    var canCheckout: Bool {
        !items.isEmpty && !isCheckingOut && !options.isLoading && !needsAddress && quote != nil && !isQuoting
    }

    var checkoutHint: String? {
        if needsAddress { return String(localized: "Tambahkan alamat pengiriman dulu ya.") }
        if selectedPayment?.isOnline == true { return String(localized: "Pesanan dibuat setelah pembayaran berhasil.") }
        return nil
    }

    /// Bayar Online → "Bayar"; COD → "Pesan Sekarang".
    var checkoutTitle: String {
        "\(selectedPayment?.isOnline == true ? "Bayar" : "Pesan Sekarang") · \(total.rupiahFormatted)"
    }

    var selection: CheckoutSelection {
        CheckoutSelection(addressID: selectedAddressID, paymentMethodID: selectedPaymentID, storeID: outlet?.id,
                          useFreeDelivery: useFreeDelivery)
    }
}

enum CartAction {
    case onAppear
    case retryOptionsTapped
    case optionsResponse(Result<CheckoutOptions, CartError>)
    case quoteResponse(version: Int, Result<CartQuote, CartError>)
    case retryQuoteTapped
    case freeDeliveryToggled(Bool)
    case itemsChanged([CartItem])
    case outletChanged(Outlet?)
    case incrementTapped(CartItem)
    case decrementTapped(CartItem)
    case removeTapped(CartItem)
    case sheetChanged(CartSheet?)
    case addressSelected(String)
    case paymentSelected(String)
    case manageAddressesTapped
    case managePaymentMethodsTapped
    case checkoutTapped
    case checkoutResponse(Result<CheckoutOutcome, CartError>)
    /// Layar Pembayaran ditutup.
    case paymentFinished(PaymentOutcome)
    case closeTapped
}

enum CartRoute {
    case close
    /// Bayar Online: buka layar Pembayaran (Snap).
    case payment(PaymentSession)
    /// Ke tab Profil (keranjang ditutup, isinya tetap tersimpan).
    case manageAddresses
    case managePaymentMethods
}

final class CartStore: Store<CartState, CartAction> {
    private let cart: CartRepository
    private let options: CheckoutOptionsRepository
    /// "Antar ke" di Beranda: alamat tersimpan yang dipilih jadi default di sini.
    private let delivery: DeliveryLocationRepository
    var onRoute: ((CartRoute) -> Void)?

    init(cart: CartRepository, options: CheckoutOptionsRepository, outlets: OutletSelectionRepository,
         delivery: DeliveryLocationRepository) {
        self.cart = cart
        self.options = options
        self.delivery = delivery
        super.init(initialState: CartState())
        // Daftar item selalu sinkron dengan repository (sumber kebenaran keranjang).
        bind(cart.itemsPublisher) { .itemsChanged($0) }
        bind(outlets.selectedPublisher) { .outletChanged($0) }
    }

    override func reduce(state: inout CartState, action: CartAction) -> Effect<CartAction>? {
        switch action {
        case .onAppear:
            // Dimuat ulang setiap keranjang dibuka: user mungkin baru menambah alamat di Profil.
            guard !state.options.isLoading else { return nil }
            if state.options.value == nil { state.options = .loading }
            return fetchOptions()

        case .retryOptionsTapped:
            state.options = .loading
            return fetchOptions()

        case .optionsResponse(.success(let options)):
            state.options = .loaded(options)
            // Pertahankan pilihan user bila masih ada; selain itu pakai default.
            if !options.addresses.contains(where: { $0.id == state.selectedAddressID }) {
                let fromHome = delivery.selected?.savedAddressID.flatMap { id in options.addresses.first { $0.id == id } }
                state.selectedAddressID = (fromHome ?? options.defaultAddress)?.id
            }
            if !options.paymentMethods.contains(where: { $0.id == state.selectedPaymentID && $0.isEnabled }) {
                state.selectedPaymentID = options.defaultPaymentMethod?.id
            }
            return requestQuote(&state)

        case .optionsResponse(.failure(let error)):
            // Pilihan yang sudah tampil tidak dihapus bila refresh gagal.
            if state.options.value == nil { state.options = .failed(error.errorDescription ?? "") }
            return requestQuote(&state)

        case .quoteResponse(let version, let result):
            guard version == state.quoteVersion else { return nil }
            state.isQuoting = false
            switch result {
            case .success(let quote):
                state.quote = quote
                state.quoteError = nil
            case .failure(.freeDeliveryUnavailable(let message)):
                // Kupon habis / dimatikan: matikan toggle & hitung ulang tanpa kupon.
                state.useFreeDelivery = false
                state.freeDeliveryNote = message
                return requestQuote(&state)
            case .failure(let error):
                // Mis. OUT_OF_DELIVERY_AREA / STORE_CLOSED: user perlu ganti alamat atau outlet.
                state.quote = nil
                state.quoteError = error.errorDescription
            }
            return nil

        case .freeDeliveryToggled(let isOn):
            guard isOn != state.useFreeDelivery else { return nil }
            state.useFreeDelivery = isOn
            state.freeDeliveryNote = nil
            state.errorMessage = nil
            return requestQuote(&state)

        case .retryQuoteTapped:
            return requestQuote(&state)

        case .itemsChanged(let items):
            state.items = items
            return requestQuote(&state)

        case .outletChanged(let outlet):
            let changed = outlet?.id != state.outlet?.id
            state.outlet = outlet
            return changed ? requestQuote(&state) : nil

        case .incrementTapped(let item):
            return updateQuantity(item, to: item.quantity + 1)

        case .decrementTapped(let item):
            return updateQuantity(item, to: item.quantity - 1)   // 0 = hapus

        case .removeTapped(let item):
            let cart = self.cart
            return .task {
                await cart.remove(itemID: item.id)
                return nil
            }

        case .sheetChanged(let sheet):
            state.activeSheet = sheet
            return nil

        case .addressSelected(let id):
            let changed = id != state.selectedAddressID
            state.selectedAddressID = id
            state.activeSheet = nil
            state.errorMessage = nil
            return changed ? requestQuote(&state) : nil

        case .paymentSelected(let id):
            guard state.paymentMethods.first(where: { $0.id == id })?.isEnabled == true else { return nil }
            state.selectedPaymentID = id
            state.activeSheet = nil
            state.errorMessage = nil
            return nil

        case .manageAddressesTapped:
            state.activeSheet = nil
            return .run { [weak self] in self?.onRoute?(.manageAddresses) }

        case .managePaymentMethodsTapped:
            state.activeSheet = nil
            return .run { [weak self] in self?.onRoute?(.managePaymentMethods) }

        case .checkoutTapped:
            guard state.canCheckout else { return nil }
            state.isCheckingOut = true
            state.errorMessage = nil
            let cart = self.cart
            let selection = state.selection
            return .task {
                do {
                    return .checkoutResponse(.success(try await cart.checkout(selection)))
                } catch {
                    return .checkoutResponse(.failure(error as? CartError ?? .checkoutFailed))
                }
            }

        case .checkoutResponse(.success(.placed(let order))):
            state.isCheckingOut = false
            state.placedOrder = order
            state.useFreeDelivery = false   // kupon dipilih ulang untuk pesanan berikutnya
            return nil

        case .checkoutResponse(.success(.payment(let session))):
            state.isCheckingOut = false
            return .run { [weak self] in self?.onRoute?(.payment(session)) }

        case .paymentFinished(.paid(let order)):
            state.placedOrder = order
            state.useFreeDelivery = false
            state.errorMessage = nil
            return nil

        case .paymentFinished(.notPaid(let message)):
            state.errorMessage = message
            return nil

        case .paymentFinished(.later):
            state.errorMessage = String(localized: "Pembayaran masih menunggu. Tekan Bayar lagi untuk melanjutkan.")
            return nil

        case .checkoutResponse(.failure(.freeDeliveryUnavailable(let message))):
            // Kupon terpakai di perangkat lain sejak harga dihitung: matikan, user cek total baru lalu bayar lagi.
            state.isCheckingOut = false
            state.useFreeDelivery = false
            state.freeDeliveryNote = message
            return requestQuote(&state)

        case .checkoutResponse(.failure(let error)):
            state.isCheckingOut = false
            state.errorMessage = error.errorDescription
            // Alamat/metode yang dipilih sudah tidak ada → muat ulang pilihan.
            return error == .selectionNotFound ? fetchOptions() : nil

        case .closeTapped:
            return .run { [weak self] in self?.onRoute?(.close) }
        }
    }

    /// Ongkir bergantung alamat, jadi quote baru dikirim setelah pilihan alamat diketahui.
    private func requestQuote(_ state: inout CartState) -> Effect<CartAction>? {
        state.quoteVersion += 1
        guard !state.items.isEmpty else {
            state.quote = nil
            state.isQuoting = false
            state.quoteError = nil
            return nil
        }
        guard !state.options.isIdle, !state.options.isLoading else { return nil }
        state.isQuoting = true
        state.quoteError = nil
        let version = state.quoteVersion
        let selection = state.selection
        let cart = self.cart
        return .task { [weak self] in
            // Tap +/− beruntun: tunggu sebentar, lalu hanya permintaan terakhir yang dikirim.
            try? await Task.sleep(for: .milliseconds(300))
            guard let self, await self.state.quoteVersion == version else { return nil }
            do {
                return .quoteResponse(version: version, .success(try await cart.quote(selection)))
            } catch {
                return .quoteResponse(version: version, .failure(error as? CartError ?? .network))
            }
        }
    }

    private func fetchOptions() -> Effect<CartAction> {
        let options = self.options
        return .task {
            do {
                return .optionsResponse(.success(try await options.options()))
            } catch {
                return .optionsResponse(.failure(error as? CartError ?? .network))
            }
        }
    }

    private func updateQuantity(_ item: CartItem, to quantity: Int) -> Effect<CartAction> {
        let cart = self.cart
        return .task {
            await cart.updateQuantity(itemID: item.id, quantity: quantity)
            return nil
        }
    }
}
