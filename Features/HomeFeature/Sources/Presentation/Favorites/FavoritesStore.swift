//
//  FavoritesStore.swift
//  HomeFeature · Presentation
//
//  Menu Favorit (dibuka dari tab Profil). ❤️ diubah di Detail produk atau di baris ini.
//
import Foundation
import TTUI
import Utility

struct FavoritesState: Equatable {
    var favorites: Loadable<[Product]> = .idle
    var toast: ToastMessage?
}

enum FavoritesAction {
    case onAppear
    case retryTapped
    case favoritesResponse(Result<[Product], CatalogError>)
    case productTapped(Product)
    case removeTapped(Product)
    case removeResponse(Product, Result<Void, CatalogError>)
    case toastRequested(ToastMessage)
    case toastDismissed(UUID)
}

enum FavoritesRoute {
    case productDetail(Product)
}

final class FavoritesStore: Store<FavoritesState, FavoritesAction> {
    private let getFavorites: GetFavoritesUseCase
    private let setFavorite: SetFavoriteUseCase
    var onRoute: ((FavoritesRoute) -> Void)?

    init(getFavorites: GetFavoritesUseCase, setFavorite: SetFavoriteUseCase) {
        self.getFavorites = getFavorites
        self.setFavorite = setFavorite
        super.init(initialState: FavoritesState())
    }

    override func reduce(state: inout FavoritesState, action: FavoritesAction) -> Effect<FavoritesAction>? {
        switch action {
        case .onAppear:
            // Kembali dari Detail: ❤️ mungkin berubah → muat ulang tanpa loading.
            guard state.favorites.isIdle else { return fetch() }
            state.favorites = .loading
            return fetch()

        case .retryTapped:
            state.favorites = .loading
            return fetch()

        case .favoritesResponse(.success(let products)):
            state.favorites = .loaded(products)
            return nil

        case .favoritesResponse(.failure(let error)):
            guard state.favorites.value == nil else { return nil }
            state.favorites = .failed(error.errorDescription ?? "")
            return nil

        case .productTapped(let product):
            return .run { [weak self] in self?.onRoute?(.productDetail(product)) }

        case .removeTapped(let product):
            // Optimis: hilang dulu dari daftar, dikembalikan bila server gagal.
            state.favorites = .loaded((state.favorites.value ?? []).filter { $0.id != product.id })
            let setFavorite = self.setFavorite
            return .task {
                do {
                    try await setFavorite.execute(productID: product.id, isFavorite: false)
                    return .removeResponse(product, .success(()))
                } catch {
                    return .removeResponse(product, .failure(error as? CatalogError ?? .unknown))
                }
            }

        case .removeResponse(let product, .success):
            return reduce(state: &state, action: .toastRequested(ToastMessage(String(localized: "\(product.name) dihapus dari favorit"))))

        case .removeResponse(let product, .failure):
            var products = state.favorites.value ?? []
            if !products.contains(where: { $0.id == product.id }) { products.append(product) }
            state.favorites = .loaded(products)
            return reduce(state: &state, action: .toastRequested(.error(String(localized: "Gagal menghapus favorit. Coba lagi."))))

        case .toastRequested(let toast):
            state.toast = toast
            return dismissToastEffect(id: toast.id) { .toastDismissed($0) }

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    private func fetch() -> Effect<FavoritesAction> {
        let getFavorites = self.getFavorites
        return .task {
            do {
                return .favoritesResponse(.success(try await getFavorites.execute()))
            } catch {
                return .favoritesResponse(.failure(error as? CatalogError ?? .unknown))
            }
        }
    }
}
