//
//  CheckoutMapper.swift
//  HomeFeature · Data
//
//  Entity keranjang + pilihan user → body request, response DTO → `PlacedOrder`, error → `CartError`.
//
import Foundation
import NetworkManager

enum CheckoutMapper {
    /// Outlet, alamat & metode bayar: pilihan user, atau dipilih server bila `nil`
    /// (outlet buka terdekat yang menjangkau alamat).
    static func request(from items: [CartItem], selection: CheckoutSelection) -> CreateOrderParam {
        CreateOrderParam(
            storeID: selection.storeID,
            paymentMethodID: selection.paymentMethodID,
            addressID: selection.addressID,
            items: items.map {
                CreateOrderParam.Item(productID: $0.product.id,
                                      optionID: $0.option?.id,
                                      quantity: $0.quantity,
                                      note: $0.note)
            },
            useFreeDelivery: selection.useFreeDelivery
        )
    }

    /// Request quote = request checkout tanpa metode bayar (ongkir tidak bergantung metode bayar).
    static func quoteRequest(from items: [CartItem], selection: CheckoutSelection) -> CreateOrderParam {
        let full = request(from: items, selection: selection)
        return CreateOrderParam(storeID: full.storeID, addressID: full.addressID, items: full.items,
                                useFreeDelivery: full.useFreeDelivery)
    }

    static func quote(from dto: QuoteDTO) throws -> CartQuote {
        guard let subtotal = dto.subtotal, let fee = dto.deliveryFee, let total = dto.total else {
            throw CartError.checkoutFailed
        }
        var eta: ClosedRange<Int>?
        if let low = dto.etaMinMinutes, let high = dto.etaMaxMinutes, low <= high { eta = low...high }
        let coupon = dto.freeDelivery.map {
            FreeDeliveryCoupon(isEnabled: $0.enabled ?? false, weeklyQuota: $0.weeklyQuota ?? 0, remaining: $0.remaining ?? 0,
                               isApplied: $0.applied ?? false, feeWaived: Decimal($0.feeWaived ?? 0))
        }
        return CartQuote(subtotal: Decimal(subtotal), deliveryFee: Decimal(fee), discount: Decimal(dto.discount ?? 0),
                         total: Decimal(total), distanceKm: dto.distanceKm, eta: eta, freeDelivery: coupon)
    }

    /// `fallbackTotal` dipakai bila server (atau mock) tidak mengirim total.
    static func placedOrder(from dto: PlacedOrderDTO, fallbackTotal: Decimal = 0) throws -> PlacedOrder {
        guard let number = dto.orderNumber, !number.isEmpty else {
            throw CartError.checkoutFailed
        }
        let total = dto.total.map { Decimal($0) } ?? fallbackTotal
        return PlacedOrder(orderNumber: number, total: total == 0 ? fallbackTotal : total, orderID: dto.orderID)
    }

    static func toDomainError(_ error: Error) -> CartError {
        switch error {
        case let error as CartError:
            return error
        case let server as APIServerError:
            return domainError(from: server)
        case APIManager.APIError.invalidStatusCode(let status):
            return domainError(from: APIServerError(statusCode: status))
        case is URLError:
            return .network
        default:
            return .checkoutFailed
        }
    }

    private static func domainError(from server: APIServerError) -> CartError {
        switch (server.statusCode, server.type) {
        case (401, _): return .sessionExpired
        case (404, _): return .selectionNotFound
        case (_, "PRODUCT_UNAVAILABLE"?):
            // Server menyebut menu & outletnya ("X sedang habis di outlet Y.").
            if let message = server.message, !message.isEmpty { return .rejected(message) }
            return .productUnavailable
        case (_, "INVALID_QUANTITY"?): return .invalidQuantity
        case (_, "EMPTY_CART"?): return .emptyCart
        case (_, "FREE_DELIVERY_QUOTA_EXCEEDED"?), (_, "FREE_DELIVERY_UNAVAILABLE"?):
            return .freeDeliveryUnavailable(server.message ?? "Kupon gratis ongkir tidak bisa dipakai.")
        case (_, "PAYMENT_GATEWAY_ERROR"?), (502, _):
            return .rejected(server.message ?? "Pembayaran sedang gangguan. Coba lagi sebentar lagi.")
        case (422, _), (409, _):
            // Mis. PAYMENT_METHOD_UNAVAILABLE, STORE_CLOSED, OUT_OF_DELIVERY_AREA, INVALID_VOUCHER,
            // PRODUCT_UNAVAILABLE di outlet tertentu: pakai pesan server.
            if let message = server.message, !message.isEmpty { return .rejected(message) }
            return server.statusCode == 422 ? .productUnavailable : .checkoutFailed
        default:
            return .checkoutFailed
        }
    }
}
