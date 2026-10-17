//
//  InMemoryCartRepository.swift
//  HomeFeature · Data
//
//  Isi keranjang disimpan di memori (hilang saat app ditutup).
//  Checkout dikirim lewat `CheckoutRemoteDataSource` → API (`POST /v1/orders`) atau Mock.
//
import Combine
import Foundation

@MainActor
final class InMemoryCartRepository: CartRepository {
    private let items = CurrentValueSubject<[CartItem], Never>([])
    private let checkoutSource: CheckoutRemoteDataSource
    /// Dipakai ulang bila checkout gagal lalu diulang, supaya server tidak membuat pesanan ganda.
    private var pendingIdempotencyKey: String?
    /// Pilihan alamat/metode bayar berubah → pesanan berbeda → key baru.
    private var pendingSelection: CheckoutSelection?

    init(checkoutSource: CheckoutRemoteDataSource) {
        self.checkoutSource = checkoutSource
    }

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
        pendingIdempotencyKey = nil   // isi keranjang berubah → pesanan baru
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
        pendingIdempotencyKey = nil   // isi keranjang berubah → pesanan baru
    }

    func remove(itemID: String) async {
        items.send(items.value.filter { $0.id != itemID })
        pendingIdempotencyKey = nil
    }

    func checkout(_ selection: CheckoutSelection) async throws -> PlacedOrder {
        let current = items.value
        guard !current.isEmpty else { throw CartError.emptyCart }

        if pendingSelection != selection { pendingIdempotencyKey = nil }
        let key = pendingIdempotencyKey ?? UUID().uuidString
        pendingIdempotencyKey = key
        pendingSelection = selection

        let request = CheckoutMapper.request(from: current, selection: selection)
        do {
            let response = try await checkoutSource.createOrder(request, idempotencyKey: key)
            // Total resmi dari server; fallback (subtotal + ongkir flat) hanya untuk mock.
            let fallbackTotal = current.reduce(Decimal(0)) { $0 + $1.subtotal } + 10000
            let order = try CheckoutMapper.placedOrder(from: response, fallbackTotal: fallbackTotal)
            pendingIdempotencyKey = nil
            items.send([])
            return order
        } catch {
            throw CheckoutMapper.toDomainError(error)
        }
    }
}
