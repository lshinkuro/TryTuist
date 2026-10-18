//
//  CatalogMapper.swift
//  HomeFeature · Data
//
//  DTO → Entity. Item tanpa field wajib dibuang (compactMap), jadi satu data rusak
//  dari backend tidak membuat seluruh screen gagal.
//
import Foundation

enum CatalogMapper {
    // MARK: Product

    static func products(from response: ProductListResponseDTO) -> [Product] {
        (response.data ?? []).compactMap { product(from: $0) }
    }

    static func product(from dto: ProductDTO) -> Product? {
        guard let id = dto.id,
              let name = dto.name?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
              let price = dto.price, price >= 0 else {
            return nil
        }
        return Product(
            id: id,
            name: name,
            description: dto.description ?? "",
            categoryID: dto.categoryID ?? "other",
            price: Decimal(price),
            imageURL: url(from: dto.imageURL),
            rating: min(max(dto.rating ?? 0, 0), 5),
            soldCount: max(dto.soldCount ?? 0, 0),
            isAvailable: dto.isAvailable ?? true,
            isBestSeller: dto.tags?.contains("best_seller") ?? false,
            options: (dto.options ?? []).compactMap { option(from: $0) },
            // Harga normal yang tidak lebih mahal dari harga sekarang = bukan promo.
            originalPrice: dto.originalPrice.flatMap { $0 > price ? Decimal($0) : nil }
        )
    }

    // MARK: Promo popup

    /// `nil` bila server mengirim `data: null` atau datanya tidak lengkap.
    static func promoPopup(from response: PromoPopupResponseDTO) -> PromoPopup? {
        guard let dto = response.data,
              let id = dto.id, !id.isEmpty,
              let title = dto.title?.trimmingCharacters(in: .whitespaces), !title.isEmpty,
              let productDTO = dto.product, let product = product(from: productDTO) else {
            return nil
        }
        let badge = dto.badge?.trimmingCharacters(in: .whitespaces) ?? ""
        return PromoPopup(
            id: id,
            title: title,
            subtitle: dto.subtitle ?? "",
            badge: badge.isEmpty && product.isOnDeal ? "HEMAT \(product.discountPercent)%" : badge,
            imageURL: url(from: dto.imageURL) ?? product.imageURL,
            endsAt: dto.endsAt.flatMap { ISO8601DateFormatter().date(from: $0) },
            product: product
        )
    }

    static func option(from dto: ProductOptionDTO) -> ProductOption? {
        guard let id = dto.id, let name = dto.name else { return nil }
        return ProductOption(id: id, name: name, extraPrice: Decimal(max(dto.extraPrice ?? 0, 0)))
    }

    // MARK: Category & Banner

    static func outlets(from response: StoreListResponseDTO) -> [Outlet] {
        (response.data ?? []).compactMap(outlet(from:))
    }

    static func outlet(from dto: StoreDTO) -> Outlet? {
        guard let id = dto.id, !id.isEmpty, let name = dto.name, !name.isEmpty else { return nil }
        return Outlet(id: id,
                      name: name,
                      address: dto.address ?? "",
                      hoursLabel: dto.hoursLabel ?? "",
                      isOpenNow: dto.isOpen ?? false,
                      closedNote: dto.closedNote.flatMap { $0.isEmpty ? nil : $0 },
                      deliveryRadiusKM: dto.deliveryRadiusKM ?? 0,
                      distanceKM: dto.distanceKM,
                      isDeliverable: dto.isDeliverable)
    }

    static func categories(from response: CategoryListResponseDTO) -> [MenuCategory] {
        (response.data ?? []).compactMap { (dto) -> MenuCategory? in
            guard let id = dto.id, let name = dto.name else { return nil }
            return MenuCategory(id: id, name: name, icon: dto.icon ?? "🍽️")
        }
    }

    static func banners(from response: BannerListResponseDTO) -> [Banner] {
        (response.data ?? []).compactMap { (dto) -> Banner? in
            guard let id = dto.id, let title = dto.title else { return nil }
            return Banner(id: id, title: title, subtitle: dto.subtitle ?? "", imageURL: url(from: dto.imageURL))
        }
    }

    // MARK: Helpers

    private static func url(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    static func toDomainError(_ error: Error) -> CatalogError {
        switch error {
        case let error as CatalogError: return error
        case is URLError: return .network
        case is DecodingError: return .invalidResponse
        default: return .unknown
        }
    }
}
