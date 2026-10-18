//
//  UserDefaultsPromoPopupDismissalStore.swift
//  HomeFeature · Data
//
//  Menyimpan "popup X sudah ditutup pada tanggal Y". Hanya tanggal terakhir per promo
//  yang disimpan, dan promo yang sudah lama tidak muncul dibersihkan.
//
import Foundation

struct UserDefaultsPromoPopupDismissalStore: PromoPopupDismissalStore {
    static let key = "home.promoPopup.dismissedOn"
    private static let maxEntries = 20

    var defaults: UserDefaults = .standard
    var calendar: Calendar = .current

    func isDismissed(promoID: String, on date: Date) -> Bool {
        entries[promoID] == day(date)
    }

    func markDismissed(promoID: String, on date: Date) {
        var entries = self.entries
        entries[promoID] = day(date)
        if entries.count > Self.maxEntries {
            // Hapus yang paling lama ("yyyy-MM-dd" bisa diurutkan sebagai teks).
            let oldest = entries.sorted { $0.value < $1.value }.prefix(entries.count - Self.maxEntries)
            oldest.forEach { entries.removeValue(forKey: $0.key) }
        }
        defaults.set(entries, forKey: Self.key)
    }

    private var entries: [String: String] {
        defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
    }

    private func day(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
