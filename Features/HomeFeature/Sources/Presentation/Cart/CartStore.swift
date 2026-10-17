//
//  CartStore.swift
//  HomeFeature · Presentation
//
//  Keranjang + pilihan "Antar ke" & "Pembayaran". Defaultnya alamat & metode utama user
//  (dari tab Profil); pilihan di sini hanya berlaku untuk pesanan ini.
//
import Foundation
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

    static let standardDeliveryFee: Decimal = 10000

    var subtotal: Decimal { items.reduce(0) { $0 + $1.subtotal } }
    var deliveryFee: Decimal { items.isEmpty ? 0 : Self.standardDeliveryFee }
    var total: Decimal { subtotal + deliveryFee }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    var addresses: [CheckoutAddress] { options.value?.addresses ?? [] }
    var paymentMethods: [CheckoutPaymentMethod] { options.value?.paymentMethods ?? [] }
    var selectedAddress: CheckoutAddress? { addresses.first { $0.id == selectedAddressID } }
    var selectedPayment: CheckoutPaymentMethod? { paymentMethods.first { $0.id == selectedPaymentID } }

    /// Pilihan sudah termuat tapi user belum punya alamat → wajib tambah dulu.
    var needsAddress: Bool { options.value != nil && addresses.isEmpty }

    /// Bila pilihan gagal dimuat, checkout tetap boleh: server memakai default user.
    var canCheckout: Bool {
        !items.isEmpty && !isCheckingOut && !options.isLoading && !needsAddress
    }

    var checkoutHint: String? {
        if needsAddress { return "Tambahkan alamat pengiriman dulu ya." }
        return nil
    }

    var selection: CheckoutSelection {
        CheckoutSelection(addressID: selectedAddressID, paymentMethodID: selectedPaymentID)
    }
}

enum CartAction {
    case onAppear
    case retryOptionsTapped
    case optionsResponse(Result<CheckoutOptions, CartError>)
    case itemsChanged([CartItem])
    case incrementTapped(CartItem)
    case decrementTapped(CartItem)
    case removeTapped(CartItem)
    case sheetChanged(CartSheet?)
    case addressSelected(String)
    case paymentSelected(String)
    case manageAddressesTapped
    case managePaymentMethodsTapped
    case checkoutTapped
    case checkoutResponse(Result<PlacedOrder, CartError>)
    case closeTapped
}

enum CartRoute {
    case close
    /// Ke tab Profil (keranjang ditutup, isinya tetap tersimpan).
    case manageAddresses
    case managePaymentMethods
}

final class CartStore: Store<CartState, CartAction> {
    private let cart: CartRepository
    private let options: CheckoutOptionsRepository
    var onRoute: ((CartRoute) -> Void)?

    init(cart: CartRepository, options: CheckoutOptionsRepository) {
        self.cart = cart
        self.options = options
        super.init(initialState: CartState())
        // Daftar item selalu sinkron dengan repository (sumber kebenaran keranjang).
        bind(cart.itemsPublisher) { .itemsChanged($0) }
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
                state.selectedAddressID = options.defaultAddress?.id
            }
            if !options.paymentMethods.contains(where: { $0.id == state.selectedPaymentID && $0.isEnabled }) {
                state.selectedPaymentID = options.defaultPaymentMethod?.id
            }
            return nil

        case .optionsResponse(.failure(let error)):
            // Pilihan yang sudah tampil tidak dihapus bila refresh gagal.
            if state.options.value == nil { state.options = .failed(error.errorDescription ?? "") }
            return nil

        case .itemsChanged(let items):
            state.items = items
            return nil

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
            state.selectedAddressID = id
            state.activeSheet = nil
            state.errorMessage = nil
            return nil

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

        case .checkoutResponse(.success(let order)):
            state.isCheckingOut = false
            state.placedOrder = order
            return nil

        case .checkoutResponse(.failure(let error)):
            state.isCheckingOut = false
            state.errorMessage = error.errorDescription
            // Alamat/metode yang dipilih sudah tidak ada → muat ulang pilihan.
            return error == .selectionNotFound ? fetchOptions() : nil

        case .closeTapped:
            return .run { [weak self] in self?.onRoute?(.close) }
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
