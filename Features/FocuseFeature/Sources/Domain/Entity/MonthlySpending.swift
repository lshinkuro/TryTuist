//
//  MonthlySpending.swift
//  FocuseFeature · Domain
//
import Foundation

/// Ringkasan belanja bulan berjalan (dihitung di aplikasi dari riwayat pesanan).
struct MonthlySpending: Equatable {
    let month: Date
    let total: Decimal
    let orderCount: Int
    /// Produk paling sering dipesan, terbanyak dulu (maks 3).
    let topProducts: [String]
}

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    let text: String
}
