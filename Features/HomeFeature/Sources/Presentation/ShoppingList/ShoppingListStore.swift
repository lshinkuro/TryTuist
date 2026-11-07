//
//  ShoppingListStore.swift
//  HomeFeature · Presentation
//
//  "Daftar Belanja": ketik resep / rencana / daftar, atau scan foto catatan → pilih → masuk keranjang.
//
import Foundation
import TTUI
import Utility

struct ShoppingListState: Equatable {
    static let textLimit = 1000

    var text = ""
    var isRecognizing = false
    var isPlanning = false
    var isAdding = false
    var items: [ShoppingListItem] = []
    /// Sudah pernah disusun (untuk membedakan "belum" dan "tidak ada yang cocok").
    var didPlan = false
    var errorMessage: String?
    /// Resep / rencana dipahami AI; tanpa AI hanya daftar per baris.
    let isSmart: Bool

    var selectedCount: Int { items.filter(\.isSelected).count }
    var canPlan: Bool { !isPlanning && !isRecognizing && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var canAdd: Bool { selectedCount > 0 && !isAdding }
}

enum ShoppingListAction {
    case textChanged(String)
    case photoPicked(Data)
    case textRecognized(String?)
    case planTapped
    case planResponse(Result<[ShoppingListItem], CatalogError>)
    case itemToggled(String)
    case quantityChanged(id: String, delta: Int)
    case addTapped
    case addResponse(added: Int, failed: [String])
}

enum ShoppingListRoute {
    case added(ToastMessage)
}

final class ShoppingListStore: Store<ShoppingListState, ShoppingListAction> {
    private let plan: PlanShoppingListUseCase
    private let recognizer: TextRecognizer
    private let addToCart: AddToCartUseCase
    var onRoute: ((ShoppingListRoute) -> Void)?

    init(plan: PlanShoppingListUseCase, recognizer: TextRecognizer, addToCart: AddToCartUseCase, isSmart: Bool) {
        self.plan = plan
        self.recognizer = recognizer
        self.addToCart = addToCart
        super.init(initialState: ShoppingListState(isSmart: isSmart))
    }

    override func reduce(state: inout ShoppingListState, action: ShoppingListAction) -> Effect<ShoppingListAction>? {
        switch action {
        case .textChanged(let text):
            state.text = String(text.prefix(ShoppingListState.textLimit))
            return nil

        case .photoPicked(let data):
            state.isRecognizing = true
            state.errorMessage = nil
            let recognizer = self.recognizer
            return .task { .textRecognized(await recognizer.recognizeText(in: data)) }

        case .textRecognized(let text):
            state.isRecognizing = false
            guard let text else {
                state.errorMessage = String(localized: "Tidak ada tulisan yang terbaca. Coba foto lebih dekat dan terang.")
                return nil
            }
            state.text = String(text.prefix(ShoppingListState.textLimit))
            return plan(&state)

        case .planTapped:
            return plan(&state)

        case .planResponse(.success(let items)):
            state.isPlanning = false
            state.didPlan = true
            state.items = items
            return nil

        case .planResponse(.failure(let error)):
            state.isPlanning = false
            state.errorMessage = error.errorDescription
            return nil

        case .itemToggled(let id):
            guard let index = state.items.firstIndex(where: { $0.id == id }) else { return nil }
            state.items[index].isSelected.toggle()
            return nil

        case .quantityChanged(let id, let delta):
            guard let index = state.items.firstIndex(where: { $0.id == id }) else { return nil }
            let range = AddToCartUseCase.quantityRange
            state.items[index].quantity = min(max(state.items[index].quantity + delta, range.lowerBound), range.upperBound)
            return nil

        case .addTapped:
            guard state.canAdd else { return nil }
            state.isAdding = true
            let (addToCart, items) = (self.addToCart, state.items.filter(\.isSelected))
            return .task {
                var failed: [String] = []
                for item in items {
                    do {
                        try await addToCart.execute(product: item.product, option: nil, quantity: item.quantity)
                    } catch {
                        failed.append(item.product.name)
                    }
                }
                return .addResponse(added: items.count - failed.count, failed: failed)
            }

        case .addResponse(let added, let failed):
            state.isAdding = false
            guard added > 0 else {
                state.errorMessage = String(localized: "Gagal menambahkan: \(failed.joined(separator: ", "))")
                return nil
            }
            let toast = failed.isEmpty
                ? ToastMessage(String(localized: "\(added) produk masuk keranjang"))
                : .error(String(localized: "\(added) produk masuk keranjang, gagal: \(failed.joined(separator: ", "))"))
            return .run { [weak self] in self?.onRoute?(.added(toast)) }
        }
    }

    private func plan(_ state: inout ShoppingListState) -> Effect<ShoppingListAction>? {
        guard state.canPlan else { return nil }
        state.isPlanning = true
        state.errorMessage = nil
        let (plan, text) = (self.plan, state.text)
        return .task {
            do {
                return .planResponse(.success(try await plan.execute(text)))
            } catch {
                return .planResponse(.failure(error as? CatalogError ?? .unknown))
            }
        }
    }
}
