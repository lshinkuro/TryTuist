//
//  CheckoutMapper.swift
//  HomeFeature · Data
//
//  Entity keranjang + pilihan user → body request, response DTO → `PlacedOrder`, error → `CartError`.
//
import Foundation
import NetworkManager

enum CheckoutMapper {
    /// Outlet dipilih server (outlet buka pertama). Alamat & metode bayar: pilihan user,
    /// atau default user di server bila `nil`.
    static func request(from items: [CartItem], selection: CheckoutSelection) -> CreateOrderParam {
        CreateOrderParam(
            paymentMethodID: selection.paymentMethodID,
            addressID: selection.addressID,
            items: items.map {
                CreateOrderParam.Item(productID: $0.product.id,
                                      optionID: $0.option?.id,
                                      quantity: $0.quantity,
                                      note: $0.note)
            }
        )
    }

    /// `fallbackTotal` dipakai bila server (atau mock) tidak mengirim total.
    static func placedOrder(from response: PlacedOrderResponseDTO, fallbackTotal: Decimal = 0) throws -> PlacedOrder {
        guard let dto = response.data, let number = dto.orderNumber, !number.isEmpty else {
            throw CartError.checkoutFailed
        }
        let total = dto.total.map { Decimal($0) } ?? fallbackTotal
        return PlacedOrder(orderNumber: number, total: total == 0 ? fallbackTotal : total)
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
        case (_, "PRODUCT_UNAVAILABLE"?): return .productUnavailable
        case (_, "INVALID_QUANTITY"?): return .invalidQuantity
        case (_, "EMPTY_CART"?): return .emptyCart
        case (422, _), (409, _):
            // Mis. PAYMENT_METHOD_UNAVAILABLE, STORE_CLOSED, INVALID_VOUCHER: pakai pesan server.
            if let message = server.message, !message.isEmpty { return .rejected(message) }
            return server.statusCode == 422 ? .productUnavailable : .checkoutFailed
        default:
            return .checkoutFailed
        }
    }
}
