//
//  DefaultCheckoutOptionsRepository.swift
//  HomeFeature · Data
//
import Foundation
import NetworkManager

struct DefaultCheckoutOptionsRepository: CheckoutOptionsRepository {
    let remote: CheckoutOptionsRemoteDataSource

    func options() async throws -> CheckoutOptions {
        do {
            // Dua request jalan bersamaan.
            async let addresses = remote.fetchAddresses()
            async let payments = remote.fetchPaymentMethods()
            return CheckoutOptionsMapper.options(addresses: try await addresses, payments: try await payments)
        } catch {
            throw CheckoutMapper.toDomainError(error)
        }
    }
}

enum CheckoutOptionsMapper {
    static func options(addresses: CheckoutAddressListResponseDTO,
                        payments: CheckoutPaymentOverviewResponseDTO) -> CheckoutOptions {
        let defaultPaymentID = payments.data?.defaultID
        return CheckoutOptions(
            addresses: (addresses.data ?? []).compactMap(address(from:))
                .sorted { $0.isDefault && !$1.isDefault },
            paymentMethods: (payments.data?.methods ?? []).compactMap { paymentMethod(from: $0, defaultID: defaultPaymentID) }
        )
    }

    static func address(from dto: CheckoutAddressDTO) -> CheckoutAddress? {
        guard let id = dto.id, let label = dto.label, let address = dto.address else { return nil }
        let location = dto.lat.flatMap { lat in dto.lng.map { GeoPoint(lat: lat, lng: $0) } }
        return CheckoutAddress(id: id, label: label, recipient: dto.recipient ?? "", phone: dto.phone ?? "",
                               address: address, isDefault: dto.isDefault ?? false, location: location)
    }

    static func paymentMethod(from dto: CheckoutPaymentMethodDTO, defaultID: String?) -> CheckoutPaymentMethod? {
        guard let id = dto.id, let name = dto.name,
              let type = dto.type?.uppercased(), ["ONLINE", "COD", "QRIS", "EWALLET"].contains(type) else { return nil }
        let detail = type == "EWALLET" ? dto.accountMasked : dto.description
        let fallbackIcon: String
        switch type {
        case "ONLINE": fallbackIcon = "creditcard.fill"
        case "COD": fallbackIcon = "banknote"
        case "QRIS": fallbackIcon = "qrcode"
        default: fallbackIcon = "wallet.pass.fill"
        }
        return CheckoutPaymentMethod(id: id, name: name, detail: detail,
                                     systemImage: dto.icon ?? fallbackIcon,
                                     isEnabled: dto.isEnabled ?? true,
                                     isDefault: dto.isDefault ?? (id == defaultID),
                                     isOnline: type == "ONLINE")
    }
}
