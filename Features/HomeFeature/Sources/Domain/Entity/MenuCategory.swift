//
//  MenuCategory.swift
//  HomeFeature · Domain
//
import Foundation

struct MenuCategory: Identifiable, Hashable {
    let id: String
    let name: String
    /// Ikon kategori dari backend (emoji), mis. "☕️".
    let icon: String
}
