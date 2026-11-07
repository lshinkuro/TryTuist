//
//  AppleIntelligenceAssistant.swift
//  HomeFeature · Data
//
//  Pencarian bahasa natural & tanya-jawab produk pakai model on-device Apple Intelligence
//  (FoundationModels, iOS 26+). Tidak ada data yang dikirim ke server.
//
import Foundation
import Utility
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppleIntelligenceAssistant: SmartProductSearch, ProductAssistant {
    var isAvailable: Bool { OnDeviceAI.isAvailable }

    func search(_ query: String, in products: [Product]) async -> [String]? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), isAvailable else { return nil }
        let catalog = catalogLines(products)
        let session = LanguageModelSession(instructions: """
            You are the product search assistant of a grocery store. From the catalog (format: id | name | price | \
            description), pick the products matching the customer's request, most relevant first. Respect any price \
            limit mentioned. Only use ids from the catalog. Return an empty list if nothing matches.
            """)
        do {
            let response = try await session.respond(to: "Catalog:\n\(catalog)\n\nCustomer request: \(query)",
                                                      generating: ProductSearchResult.self)
            return response.content.productIDs
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    func suggest(for preferences: ShoppingPreferences, from products: [Product]) async -> ProductSuggestion? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), isAvailable, !preferences.isEmpty else { return nil }
        let session = LanguageModelSession(instructions: """
            You are a friendly shopping assistant on the home screen of a grocery store app. Based on what the \
            shopper likes and needs, write one short practical tip (at most 2 sentences, in the same language the \
            shopper used) and pick up to 4 matching products from the catalog (format: id | name | price | \
            description). Only use ids from the catalog; never make up prices or products.
            """)
        let prompt = """
            Likes: \(preferences.likes)
            Needs: \(preferences.needs)

            Catalog:
            \(catalogLines(products))
            """
        do {
            let result = try await session.respond(to: prompt, generating: SuggestionResult.self).content
            return ProductSuggestion(tip: result.tip, productIDs: result.productIDs)
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    func complements(for cart: [Product], from products: [Product]) async -> [String]? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), isAvailable, !cart.isEmpty else { return nil }
        let cartIDs = Set(cart.map(\.id))
        let session = LanguageModelSession(instructions: """
            You are a grocery shopping assistant. Given the shopper's cart, pick up to 3 products from the catalog \
            (format: id | name | price | description) that go well with it: ingredients commonly bought together \
            or things they may have forgotten. Only use ids from the catalog. Return an empty list if nothing fits.
            """)
        let prompt = """
            Cart: \(cart.map(\.name).joined(separator: ", "))

            Catalog:
            \(catalogLines(products.filter { $0.isAvailable && !cartIDs.contains($0.id) }))
            """
        let ids = try? await session.respond(to: prompt, generating: ProductSearchResult.self).content.productIDs
        return ids.map { Array($0.prefix(3)) }
        #else
        return nil
        #endif
    }

    func planShopping(_ request: String, from products: [Product]) async -> [PlannedItem]? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), isAvailable else { return nil }
        let session = LanguageModelSession(instructions: """
            You are a grocery shopping assistant. Turn the shopper's request (a recipe, a plan like "cooking for \
            5 people", or a shopping list) into products to buy from the catalog (format: id | name | price | \
            description), with a sensible quantity for each. Only use ids from the catalog; skip things the catalog \
            does not have.
            """)
        do {
            let result = try await session.respond(to: "Request:\n\(request)\n\nCatalog:\n\(catalogLines(products))",
                                                   generating: ShoppingPlanResult.self).content
            return result.items.map { PlannedItem(productID: $0.productID, quantity: $0.quantity) }
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    // shortcut: seluruh katalog masuk prompt (konteks model ±4K token, cukup untuk ±100 produk);
    // kalau katalog jauh lebih besar, saring dulu per kategori/kata kunci sebelum dikirim.
    private func catalogLines(_ products: [Product]) -> String {
        products.map { product in
            "\(product.id) | \(product.name) | Rp\(product.price.rupiahInt) | \(product.description.prefix(80))"
        }.joined(separator: "\n")
    }

    func ask(_ question: String, about product: Product) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26, *), isAvailable else { return nil }
        var facts = [
            "Name: \(product.name)",
            "Description: \(product.description)",
            "Price: Rp\(product.price.rupiahInt)",
            "Rating: \(product.rating)/5, sold \(product.soldCount)",
            "Stock: \(product.isAvailable ? "available" : "sold out")",
        ]
        if !product.options.isEmpty {
            facts.append("Options: " + product.options.map { "\($0.name) (+Rp\($0.extraPrice.rupiahInt))" }.joined(separator: ", "))
        }
        if let combo = product.combo {
            facts.append("Bundle contents: \(combo.summary); saves Rp\(combo.savings.rupiahInt)")
        }
        let session = LanguageModelSession(instructions: """
            You are a shopping assistant in a grocery store app. Answer the shopper's question about the product \
            below in the same language as the question, briefly (at most 5 sentences or bullet points), friendly and \
            practical: uses, storage/usage tips, recipe ideas, value for money. Price, stock and contents must come \
            only from the data below; never make them up. For health/medical topics, suggest checking the label or \
            asking a professional.

            Product data:
            \(facts.joined(separator: "\n"))
            """)
        do {
            return try await session.respond(to: question).content
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
}

private extension Decimal {
    var rupiahInt: Int { NSDecimalNumber(decimal: self).intValue }
}

#if canImport(FoundationModels)
@available(iOS 26, *)
@Generable
private struct ProductSearchResult {
    @Guide(description: "Ids of matching products, most relevant first")
    let productIDs: [String]
}

@available(iOS 26, *)
@Generable
private struct ShoppingPlanResult {
    @Guide(description: "Products to buy")
    let items: [PlanItem]

    @Generable
    struct PlanItem {
        @Guide(description: "Product id from the catalog")
        let productID: String
        @Guide(description: "How many to buy", .range(1...20))
        let quantity: Int
    }
}

@available(iOS 26, *)
@Generable
private struct SuggestionResult {
    @Guide(description: "One short practical shopping tip, at most 2 sentences")
    let tip: String
    @Guide(description: "Ids of up to 4 matching products, most relevant first", .maximumCount(4))
    let productIDs: [String]
}
#endif
