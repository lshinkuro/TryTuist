//
//  ShoppingListUseCases.swift
//  HomeFeature · Domain
//
import Foundation

/// Teks bebas ("masak rendang 5 porsi", atau daftar per baris) → produk + jumlah dari katalog.
/// AI dipakai bila tersedia; selain itu (atau bila AI gagal) dicocokkan per baris dengan kata kunci.
@MainActor
struct PlanShoppingListUseCase {
    let repository: CatalogRepository
    let outlets: OutletSelectionRepository
    let assistant: ProductAssistant

    func execute(_ text: String) async throws -> [ShoppingListItem] {
        let products = try await repository.fetchProducts(storeID: outlets.selected?.id ?? outlets.savedOutletID)
            .filter(\.isAvailable)
        if assistant.isAvailable, let planned = await assistant.planShopping(text, from: products) {
            let items = planned.compactMap { plan in
                products.first { $0.id == plan.productID }.map { ShoppingListItem(product: $0, quantity: plan.quantity) }
            }
            if !items.isEmpty { return Self.merged(items) }
        }
        return Self.match(text, in: products)
    }

    /// Per baris: "2 beras", "Gula pasir 1", "- minyak goreng" → produk pertama yang namanya memuat kata kuncinya.
    static func match(_ text: String, in products: [Product]) -> [ShoppingListItem] {
        let items = text.split(whereSeparator: \.isNewline).compactMap { line -> ShoppingListItem? in
            let quantity = line.split(whereSeparator: { !$0.isNumber }).first.flatMap { Int($0) } ?? 1
            let keyword = line.filter { $0.isLetter || $0 == " " }.trimmingCharacters(in: .whitespaces)
            guard keyword.count >= 2 else { return nil }
            let firstWord = keyword.split(separator: " ").first.map(String.init) ?? keyword
            let product = products.first { $0.name.localizedStandardContains(keyword) }
                ?? (firstWord.count >= 3 ? products.first { $0.name.localizedStandardContains(firstWord) } : nil)
            return product.map { ShoppingListItem(product: $0, quantity: quantity) }
        }
        return merged(items)
    }

    /// Produk yang sama digabung; jumlah dibatasi aturan keranjang.
    static func merged(_ items: [ShoppingListItem]) -> [ShoppingListItem] {
        var result: [ShoppingListItem] = []
        for item in items {
            if let index = result.firstIndex(where: { $0.id == item.id }) {
                result[index].quantity += item.quantity
            } else {
                result.append(item)
            }
        }
        let range = AddToCartUseCase.quantityRange
        return result.map { item in
            var item = item
            item.quantity = min(max(item.quantity, range.lowerBound), range.upperBound)
            return item
        }
    }
}

/// Dicatat setiap pesanan berhasil; menjadwalkan ulang pengingat "waktunya beli lagi".
struct RecordPurchaseUseCase {
    static let maxDatesPerProduct = 6
    static let maxReminders = 5
    /// Jarak beli ulang minimum, supaya belanja dua kali seminggu tidak jadi pengingat harian.
    static let minimumInterval: TimeInterval = 3 * 24 * 60 * 60

    let history: PurchaseHistoryRepository
    let scheduler: RestockReminderScheduler

    func execute(_ items: [CartItem], at date: Date = Date(), calendar: Calendar = .current) {
        var records = history.load()
        for item in items {
            if let index = records.firstIndex(where: { $0.productID == item.product.id }) {
                records[index].name = item.product.name
                if let last = records[index].dates.last, calendar.isDate(last, inSameDayAs: date) { continue }
                records[index].dates = Array((records[index].dates + [date]).suffix(Self.maxDatesPerProduct))
            } else {
                records.append(PurchaseRecord(productID: item.product.id, name: item.product.name, dates: [date]))
            }
        }
        history.save(records)
        scheduler.schedule(Self.reminders(from: records, now: date, calendar: calendar))
    }

    /// Produk yang sudah dibeli ≥ 2 kali: jatuh tempo = pembelian terakhir + rata-rata jarak, jam 10.00.
    /// Yang jatuh temponya sudah lewat dilewati (menunggu pembelian berikutnya).
    static func reminders(from records: [PurchaseRecord], now: Date, calendar: Calendar) -> [RestockReminder] {
        let reminders = records.compactMap { record -> RestockReminder? in
            guard record.dates.count >= 2, let first = record.dates.first, let last = record.dates.last else { return nil }
            let interval = max(last.timeIntervalSince(first) / Double(record.dates.count - 1), minimumInterval)
            guard let due = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: last.addingTimeInterval(interval)),
                  due > now else { return nil }
            return RestockReminder(productID: record.productID, name: record.name, date: due)
        }
        return Array(reminders.sorted { $0.date < $1.date }.prefix(maxReminders))
    }
}
