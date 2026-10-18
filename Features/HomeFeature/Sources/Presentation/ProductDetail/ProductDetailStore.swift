//
//  ProductDetailStore.swift
//  HomeFeature · Presentation
//
//  Semua logika detail produk ada di sini: pilihan opsi, jumlah, catatan,
//  favorit, perhitungan harga, dan tambah ke keranjang. View hanya merender.
//
import Foundation
import TTUI
import Utility

struct ProductDetailState: Equatable {
    let product: Product
    var selectedOptionID: String?
    var quantity = 1
    var note = ""
    var isFavorite = false
    var isAdding = false
    var errorMessage: String?

    static let noteLimit = 100

    var selectedOption: ProductOption? {
        product.options.first { $0.id == selectedOptionID }
    }

    /// Harga promo sudah termasuk di `product.price`; extra varian tetap ditambahkan.
    var unitPrice: Decimal { product.price + (selectedOption?.extraPrice ?? 0) }
    var totalPrice: Decimal { unitPrice * Decimal(quantity) }

    /// Harga normal per item (sebelum promo), `nil` bila tidak promo.
    var originalUnitPrice: Decimal? {
        guard product.isOnDeal, let original = product.originalPrice else { return nil }
        return original + (selectedOption?.extraPrice ?? 0)
    }

    /// Total potongan untuk jumlah yang dipilih.
    var totalSavings: Decimal {
        guard let originalUnitPrice else { return 0 }
        return (originalUnitPrice - unitPrice) * Decimal(quantity)
    }

    var canDecrease: Bool { quantity > AddToCartUseCase.quantityRange.lowerBound && !isAdding }
    var canIncrease: Bool { quantity < AddToCartUseCase.quantityRange.upperBound && !isAdding }
    var canAddToCart: Bool { product.isAvailable && !isAdding }

    var addButtonTitle: String {
        product.isAvailable ? String(localized: "Tambah · \(totalPrice.rupiahFormatted)") : String(localized: "Sedang Habis")
    }
}

enum ProductDetailAction {
    case onAppear
    case favoriteStatusLoaded(Bool)
    case favoriteResponse(Result<Void, CatalogError>)
    case optionSelected(String)
    case incrementTapped
    case decrementTapped
    case noteChanged(String)
    case favoriteToggled
    case addToCartTapped
    case addToCartResponse(Result<Void, CartError>)
}

enum ProductDetailRoute {
    /// Berhasil ditambah → tutup detail, screen sebelumnya menampilkan toast.
    case addedToCart(ToastMessage)
}

final class ProductDetailStore: Store<ProductDetailState, ProductDetailAction> {
    private let addToCart: AddToCartUseCase
    private let getFavorites: GetFavoritesUseCase
    private let setFavorite: SetFavoriteUseCase
    var onRoute: ((ProductDetailRoute) -> Void)?

    init(product: Product, addToCart: AddToCartUseCase,
         getFavorites: GetFavoritesUseCase, setFavorite: SetFavoriteUseCase) {
        self.addToCart = addToCart
        self.getFavorites = getFavorites
        self.setFavorite = setFavorite
        super.init(initialState: ProductDetailState(product: product, selectedOptionID: product.defaultOption?.id))
    }

    override func reduce(state: inout ProductDetailState, action: ProductDetailAction) -> Effect<ProductDetailAction>? {
        switch action {
        case .onAppear:
            let (getFavorites, id) = (self.getFavorites, state.product.id)
            return .task {
                // Gagal (mis. belum login) → ❤️ tetap kosong, tidak perlu pesan.
                guard let favorites = try? await getFavorites.execute() else { return nil }
                return .favoriteStatusLoaded(favorites.contains { $0.id == id })
            }

        case .favoriteStatusLoaded(let isFavorite):
            state.isFavorite = isFavorite
            return nil

        case .favoriteResponse(.success):
            return nil

        case .favoriteResponse(.failure(let error)):
            // Kembalikan ❤️ ke status sebelum di-tap.
            state.isFavorite.toggle()
            state.errorMessage = error == .network ? error.errorDescription : String(localized: "Gagal menyimpan favorit. Coba lagi.")
            return nil

        case .optionSelected(let id):
            guard state.product.options.contains(where: { $0.id == id }) else { return nil }
            state.selectedOptionID = id
            return nil

        case .incrementTapped:
            guard state.canIncrease else { return nil }
            state.quantity += 1
            return nil

        case .decrementTapped:
            guard state.canDecrease else { return nil }
            state.quantity -= 1
            return nil

        case .noteChanged(let note):
            state.note = String(note.prefix(ProductDetailState.noteLimit))
            return nil

        case .favoriteToggled:
            state.isFavorite.toggle()
            state.errorMessage = nil
            let (setFavorite, id, isFavorite) = (self.setFavorite, state.product.id, state.isFavorite)
            return .task {
                do {
                    try await setFavorite.execute(productID: id, isFavorite: isFavorite)
                    return .favoriteResponse(.success(()))
                } catch {
                    return .favoriteResponse(.failure(error as? CatalogError ?? .unknown))
                }
            }

        case .addToCartTapped:
            guard state.canAddToCart else { return nil }
            state.isAdding = true
            state.errorMessage = nil
            let (product, option, quantity, note) = (state.product, state.selectedOption, state.quantity, state.note)
            let addToCart = self.addToCart
            return .task {
                do {
                    try await addToCart.execute(product: product, option: option, quantity: quantity, note: note)
                    return .addToCartResponse(.success(()))
                } catch {
                    return .addToCartResponse(.failure(error as? CartError ?? .productUnavailable))
                }
            }

        case .addToCartResponse(.success):
            state.isAdding = false
            let toast = ToastMessage(String(localized: "\(state.quantity)× \(state.product.name) masuk keranjang"))
            return .run { [weak self] in self?.onRoute?(.addedToCart(toast)) }

        case .addToCartResponse(.failure(let error)):
            state.isAdding = false
            state.errorMessage = error.errorDescription
            return nil
        }
    }
}
