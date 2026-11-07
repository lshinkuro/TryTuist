//
//  ProductIntents.swift
//  TryTuist
//
//  Siri & Shortcuts ("Tambah beras ke keranjang"), dan Visual Intelligence (iOS 26+):
//  arahkan kamera ke produk → hasil dari katalog → tap untuk membuka detail produk.
//
import AppIntents
import HomeFeature
import TTUI
#if canImport(VisualIntelligence)
import VisualIntelligence
#endif

struct ProductEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Produk"
    static let defaultQuery = ProductEntityQuery()

    let id: String
    let name: String
    let price: Decimal
    let imageURL: URL?

    init(_ product: CatalogProductSummary) {
        id = product.id
        name = product.name
        price = product.price
        imageURL = product.imageURL
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(price.rupiahFormatted)", image: imageURL.map { .init(url: $0) })
    }
}

struct ProductEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ProductEntity] {
        await CatalogIntents.products(ids: identifiers).map(ProductEntity.init)
    }

    func entities(matching string: String) async throws -> [ProductEntity] {
        await CatalogIntents.search([string]).map(ProductEntity.init)
    }

    /// Juga jadi daftar nama produk yang dikenali Siri di frasa "Tambah <produk> ke keranjang".
    func suggestedEntities() async throws -> [ProductEntity] {
        await CatalogIntents.suggested().map(ProductEntity.init)
    }
}

struct AddToCartIntent: AppIntent {
    static let title: LocalizedStringResource = "Tambah ke Keranjang"
    static let description = IntentDescription("Tambahkan produk ke keranjang belanja.")
    static let openAppWhenRun = true

    @Parameter(title: "Produk")
    var product: ProductEntity

    @Parameter(title: "Jumlah", default: 1, inclusiveRange: (1, 20))
    var quantity: Int

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let handled = IntentActionCenter.shared.send(.addToCart(productID: product.id, name: product.name, quantity: quantity))
        let dialog: IntentDialog = handled
            ? "\(product.name) ditambahkan ke keranjang."
            : "Masuk dulu ya, nanti \(product.name) langsung ditambahkan ke keranjang."
        return .result(dialog: dialog)
    }
}

/// Membuka detail produk; dipakai hasil Visual Intelligence & Shortcuts.
struct OpenProductIntent: OpenIntent {
    static let title: LocalizedStringResource = "Buka Produk"

    @Parameter(title: "Produk")
    var target: ProductEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        IntentActionCenter.shared.send(.openProduct(id: target.id))
        return .result()
    }
}

#if canImport(VisualIntelligence)
/// Visual Intelligence: label gambar (mis. "rice", "cooking oil") dicocokkan ke katalog.
@available(iOS 26, *)
struct ProductVisualSearchQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [ProductEntity] {
        await CatalogIntents.search(input.labels).map(ProductEntity.init)
    }
}
#endif

struct TryTuistShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddToCartIntent(), phrases: [
            "Tambah \(\.$product) ke keranjang \(.applicationName)",
            "Add \(\.$product) to my \(.applicationName) cart",
            "Tambah ke keranjang \(.applicationName)",
            "Add to cart in \(.applicationName)",
        ], shortTitle: "Tambah ke Keranjang", systemImageName: "cart.badge.plus")
    }
}
