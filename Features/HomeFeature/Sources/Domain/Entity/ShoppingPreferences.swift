//
//  ShoppingPreferences.swift
//  HomeFeature · Domain
//
//  Preferensi belanja yang diisi pembeli, dipakai AI untuk saran di Beranda. Disimpan lokal saja.
//
import Foundation

struct ShoppingPreferences: Equatable {
    static let maxLength = 200

    var likes = ""
    var needs = ""

    var isEmpty: Bool { likes.isEmpty && needs.isEmpty }

    /// Dipotong & dirapikan sebelum disimpan / masuk prompt AI.
    var sanitized: ShoppingPreferences {
        func clean(_ text: String) -> String {
            String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxLength))
        }
        return ShoppingPreferences(likes: clean(likes), needs: clean(needs))
    }
}

/// Saran AI di Beranda: tip singkat + produk yang cocok.
struct ProductSuggestion: Equatable {
    let tip: String
    let productIDs: [String]
}
