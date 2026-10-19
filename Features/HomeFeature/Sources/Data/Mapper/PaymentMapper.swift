//
//  PaymentMapper.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

enum PaymentMapper {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func outcome(from response: CheckoutResponseDTO, fallbackTotal: Decimal) throws -> CheckoutOutcome {
        guard let dto = response.data else { throw CartError.checkoutFailed }
        if dto.next == "PAYMENT" {
            guard let payment = dto.payment, let session = session(from: payment) else { throw CartError.checkoutFailed }
            return .payment(session)
        }
        guard let order = dto.order else { throw CartError.checkoutFailed }
        return .placed(try CheckoutMapper.placedOrder(from: order, fallbackTotal: fallbackTotal))
    }

    static func session(from dto: PaymentDTO) -> PaymentSession? {
        guard let id = dto.id, !id.isEmpty,
              let status = dto.status.flatMap(PaymentStatus.init(rawValue:)),
              let amount = dto.amount,
              let expiresAt = dto.expiresAt.flatMap(isoFormatter.date(from:)) else { return nil }
        let typeName = dto.paymentType.map(paymentTypeName)
        var order: PlacedOrder?
        if let ref = dto.order, let number = ref.orderNumber, !number.isEmpty {
            order = PlacedOrder(orderNumber: number, total: Decimal(amount), orderID: ref.id,
                                paidVia: typeName.map { "Dibayar via \($0)" })
        }
        return PaymentSession(id: id, status: status, amount: Decimal(amount), expiresAt: expiresAt,
                              redirectURL: dto.redirectURL.flatMap(URL.init(string:)),
                              finishURLPrefix: dto.finishURLPrefix,
                              storeName: dto.store?.name ?? "",
                              paymentTypeName: typeName,
                              statusMessage: dto.statusMessage,
                              order: order)
    }

    static func paymentTypeName(_ type: String) -> String {
        switch type {
        case "gopay": return "GoPay"
        case "shopeepay": return "ShopeePay"
        case "qris", "other_qris": return "QRIS"
        case "bank_transfer", "echannel", "permata": return "transfer bank"
        case "credit_card": return "kartu"
        case "cstore": return "minimarket"
        default: return type
        }
    }

    /// transaction_status Midtrans yang disimulasikan backend dev.
    static func midtransStatus(_ outcome: PaymentSimulation) -> String {
        switch outcome {
        case .paid: return "settlement"
        case .denied: return "deny"
        case .expired: return "expire"
        case .cancelled: return "cancel"
        }
    }

    static func toDomainError(_ error: Error) -> PaymentError {
        switch error {
        case let error as PaymentError:
            return error
        case let server as APIServerError:
            switch (server.statusCode, server.type) {
            case (401, _): return .sessionExpired
            case (404, _): return .notFound
            case (_, "PAYMENT_ALREADY_FINAL"?): return .alreadyFinal
            default: return .gateway(server.message ?? "Pembayaran sedang gangguan. Coba lagi.")
            }
        case APIManager.APIError.invalidStatusCode(let status):
            return status == 401 ? .sessionExpired : status == 404 ? .notFound : .network
        default:
            return .network
        }
    }
}
