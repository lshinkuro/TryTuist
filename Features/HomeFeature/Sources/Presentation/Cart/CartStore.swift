//
//  CartStore.swift
//  HomeFeature · Presentation
//
import Foundation
import Utility

struct CartState: Equatable {
    var items: [CartItem] = []
    var isCheckingOut = false
    var errorMessage: String?
    var placedOrder: PlacedOrder?

    static let standardDeliveryFee: Decimal = 10000

    var subtotal: Decimal { items.reduce(0) { $0 + $1.subtotal } }
    var deliveryFee: Decimal { items.isEmpty ? 0 : Self.standardDeliveryFee }
    var total: Decimal { subtotal + deliveryFee }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
    var canCheckout: Bool { !items.isEmpty && !isCheckingOut }
}

enum CartAction {
    case itemsChanged([CartItem])
    case incrementTapped(CartItem)
    case decrementTapped(CartItem)
    case removeTapped(CartItem)
    case checkoutTapped
    case checkoutResponse(Result<PlacedOrder, CartError>)
    case closeTapped
}

enum CartRoute {
    case close
}

final class CartStore: Store<CartState, CartAction> {
    private let cart: CartRepository
    var onRoute: ((CartRoute) -> Void)?

    init(cart: CartRepository) {
        self.cart = cart
        super.init(initialState: CartState())
        // Daftar item selalu sinkron dengan repository (sumber kebenaran keranjang).
        bind(cart.itemsPublisher) { .itemsChanged($0) }
    }

    override func reduce(state: inout CartState, action: CartAction) -> Effect<CartAction>? {
        switch action {
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

        case .checkoutTapped:
            guard state.canCheckout else { return nil }
            state.isCheckingOut = true
            state.errorMessage = nil
            let cart = self.cart
            return .task {
                do {
                    return .checkoutResponse(.success(try await cart.checkout()))
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
            return nil

        case .closeTapped:
            return .run { [weak self] in self?.onRoute?(.close) }
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
