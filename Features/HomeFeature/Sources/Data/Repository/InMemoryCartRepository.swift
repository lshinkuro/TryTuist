//
//  InMemoryCartRepository.swift
//  HomeFeature · Data
//
//  Keranjang di memori (hilang saat app ditutup). Ganti dengan implementasi
//  API/CoreData nanti tanpa mengubah Store karena Store hanya kenal `CartRepository`.
//
import Combine
import Foundation

@MainActor
final class InMemoryCartRepository: CartRepository {
    private let items = CurrentValueSubject<[CartItem], Never>([])

    var itemsPublisher: AnyPublisher<[CartItem], Never> {
        items.eraseToAnyPublisher()
    }

    var summaryPublisher: AnyPublisher<CartSummary, Never> {
        items
            .map { items in
                CartSummary(itemCount: items.reduce(0) { $0 + $1.quantity },
                            total: items.reduce(0) { $0 + $1.subtotal })
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func add(_ item: CartItem) async throws {
        var current = items.value
        if let index = current.firstIndex(where: { $0.id == item.id }) {
            current[index].quantity = min(current[index].quantity + item.quantity, AddToCartUseCase.quantityRange.upperBound)
        } else {
            current.append(item)
        }
        items.send(current)
    }

    func updateQuantity(itemID: String, quantity: Int) async {
        var current = items.value
        guard let index = current.firstIndex(where: { $0.id == itemID }) else { return }
        if quantity <= 0 {
            current.remove(at: index)
        } else {
            current[index].quantity = min(quantity, AddToCartUseCase.quantityRange.upperBound)
        }
        items.send(current)
    }

    func remove(itemID: String) async {
        items.send(items.value.filter { $0.id != itemID })
    }

    /// Mock checkout: jeda sebentar lalu kosongkan keranjang.
    func checkout() async throws -> PlacedOrder {
        let current = items.value
        guard !current.isEmpty else { throw CartError.emptyCart }
        try await Task.sleep(for: .seconds(1))
        let total = current.reduce(Decimal(0)) { $0 + $1.subtotal }
        items.send([])
        return PlacedOrder(orderNumber: "ORD-\(Int.random(in: 10000...99999))", total: total)
    }
}
