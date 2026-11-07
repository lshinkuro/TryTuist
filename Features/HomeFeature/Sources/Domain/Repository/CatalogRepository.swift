//
//  CatalogRepository.swift
//  HomeFeature · Domain
//
import Combine
import Foundation

protocol CatalogRepository {
    func fetchBanners() async throws -> [Banner]
    func fetchCategories() async throws -> [MenuCategory]
    /// `storeID` nil = stok pusat; diisi = ketersediaan mengikuti outlet itu (harga tetap sama).
    func fetchProducts(storeID: String?) async throws -> [Product]
    func fetchProduct(id: String, storeID: String?) async throws -> Product
    /// Outlet aktif, yang buka & menjangkau `point` lebih dulu.
    func fetchOutlets(near point: GeoPoint?) async throws -> [Outlet]
    /// `nil` = tidak ada promo popup yang berlaku.
    /// Promo pusat + promo outlet `storeID` (nil = promo pusat saja).
    func fetchPromoPopup(storeID: String?) async throws -> PromoPopup?
    /// Harga & stok mengikuti outlet `storeID`.
    func fetchFavorites(storeID: String?) async throws -> [Product]
    func setFavorite(productID: String, isFavorite: Bool) async throws
}

/// Pencarian bahasa natural ("camilan manis di bawah 20rb") dengan AI on-device.
protocol SmartProductSearch {
    var isAvailable: Bool { get }
    /// ID produk yang cocok, paling relevan dulu. `nil` = AI tidak tersedia / gagal → pakai pencarian kata kunci.
    func search(_ query: String, in products: [Product]) async -> [String]?
}

/// Tanya-jawab seputar produk (kegunaan, tips, ide olahan) dengan AI on-device.
protocol ProductAssistant {
    var isAvailable: Bool { get }
    /// `nil` = AI tidak tersedia / gagal menjawab.
    func ask(_ question: String, about product: Product) async -> String?
    /// Tip + produk yang cocok dengan preferensi pembeli. `nil` = AI tidak tersedia / gagal.
    func suggest(for preferences: ShoppingPreferences, from products: [Product]) async -> ProductSuggestion?
    /// Maks 3 id produk yang cocok melengkapi isi keranjang. `nil` = AI tidak tersedia / gagal.
    func complements(for cart: [Product], from products: [Product]) async -> [String]?
    /// Resep / rencana / daftar belanja → produk + jumlah. `nil` = AI tidak tersedia / gagal.
    func planShopping(_ request: String, from products: [Product]) async -> [PlannedItem]?
}

enum VoiceSearchEvent: Equatable {
    /// Teks sementara selama bicara; `isFinal` = selesai mendengarkan.
    case transcript(String, isFinal: Bool)
    case failed(String)
}

/// Pencarian suara: dimulai hanya dari aksi user (tombol mic).
@MainActor
protocol VoiceSearch {
    var events: AnyPublisher<VoiceSearchEvent, Never> { get }
    func start() async
    /// Berhenti mendengarkan; teks terakhir dikirim sebagai final.
    func finish()
}

/// Baca teks dari foto (mis. catatan belanja). `nil` = tidak ada teks terbaca.
protocol TextRecognizer {
    func recognizeText(in imageData: Data) async -> String?
}

protocol PurchaseHistoryRepository {
    func load() -> [PurchaseRecord]
    func save(_ records: [PurchaseRecord])
}

/// Mengganti semua pengingat beli ulang yang terjadwal dengan `reminders`.
protocol RestockReminderScheduler {
    func schedule(_ reminders: [RestockReminder])
}

protocol ShoppingPreferencesRepository {
    func load() -> ShoppingPreferences
    func save(_ preferences: ShoppingPreferences)
}

/// Mengingat popup yang sudah ditutup supaya tidak muncul terus (sekali per hari per promo).
protocol PromoPopupDismissalStore {
    func isDismissed(promoID: String, on date: Date) -> Bool
    func markDismissed(promoID: String, on date: Date)
}

enum CatalogError: LocalizedError, Equatable {
    case network
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .network: return String(localized: "Tidak ada koneksi internet.")
        case .invalidResponse: return String(localized: "Data produk dari server tidak valid.")
        case .unknown: return String(localized: "Gagal memuat produk. Coba lagi.")
        }
    }
}
