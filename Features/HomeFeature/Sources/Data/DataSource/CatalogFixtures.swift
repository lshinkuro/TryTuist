//
//  CatalogFixtures.swift
//  HomeFeature · Data
//
//  JSON contoh untuk Mock data source. Foto dari Unsplash (lisensi gratis):
//  https://unsplash.com/license
//
import Foundation

enum CatalogFixtures {
    private static func unsplash(_ id: String, width: Int = 800) -> String {
        "https://images.unsplash.com/photo-\(id)?w=\(width)&q=80&auto=format&fit=crop"
    }

    static let banners = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "id": "B1", "title": "Paket Sayur Segar cuma 19rb", "subtitle": "Belanja dapur hemat minggu ini",
          "image_url": "\(unsplash("1566385101042-1a0aa0c1268c", width: 1200))" },
        { "id": "B2", "title": "Gratis Ongkir 2x Seminggu", "subtitle": "Aktifkan kuponnya di keranjang saat checkout",
          "image_url": "\(unsplash("1604719312566-8912e9227c6a", width: 1200))" },
        { "id": "B3", "title": "Paket Hemat Sembako", "subtitle": "Minyak + gula mulai Rp 39rb",
          "image_url": "\(unsplash("1542838132-92c53300491e", width: 1200))" }
      ]
    }
    """

    static let categories = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "id": "sembako", "name": "Sembako", "icon": "🌾" },
        { "id": "minuman", "name": "Minuman & Susu", "icon": "🥛" },
        { "id": "segar", "name": "Sayur & Buah", "icon": "🥬" },
        { "id": "protein", "name": "Daging & Ikan", "icon": "🥩" },
        { "id": "rumah", "name": "Kebutuhan Rumah", "icon": "🧴" },
        { "id": "snack", "name": "Camilan", "icon": "🍪" }
      ]
    }
    """

    /// P07 sedang promo (dipakai juga oleh popup Beranda). Sama dengan seed backend D01.
    private static let sayurPromo = """
    { "product_id": "P07", "product_name": "Paket Sayur Segar", "category_id": "segar",
      "price": 19900, "original_price": 32000, "discount_percent": 37,
      "description": "Wortel, kentang, kol, dan buncis ±1,5 kg. Dipetik pagi, diantar hari itu juga.",
      "image_url": "\(unsplash("1540420773420-3366772f4999"))", "rating": 4.8, "sold_count": 1210,
      "is_available": true, "tags": ["best_seller", "promo"] }
    """

    /// Dua item terakhir sengaja tidak valid (tanpa nama / tanpa harga) → dibuang oleh Mapper.
    static let products = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "product_id": "P01", "product_name": "Minyak Goreng 1 L", "category_id": "sembako", "price": 22000,
          "description": "Minyak goreng sawit jernih, tidak mudah berbusa. Pilih kemasan pouch atau botol.",
          "image_url": "\(unsplash("1474979266404-7eaacbcd87c5"))", "rating": 4.9, "sold_count": 1520,
          "is_available": true, "tags": ["best_seller"],
          "options": [ { "id": "pouch", "name": "Pouch", "extra_price": 0 },
                       { "id": "botol", "name": "Botol", "extra_price": 5000 } ] },
        { "product_id": "P02", "product_name": "Beras Medium 2 kg", "category_id": "sembako", "price": 25000,
          "description": "Beras pulen hasil petani lokal, bersih dan wangi.",
          "image_url": "\(unsplash("1586201375761-83865001e31c"))", "rating": 4.7, "sold_count": 640,
          "is_available": true },
        { "product_id": "P03", "product_name": "Telur Ayam 1 kg", "category_id": "sembako", "price": 24000,
          "description": "Telur ayam negeri segar, isi ±16 butir.",
          "image_url": "\(unsplash("1582722872445-44dc5f7e3c8f"))", "rating": 4.6, "sold_count": 580,
          "is_available": true },
        { "product_id": "P04", "product_name": "Gula Pasir 1 kg", "category_id": "sembako", "price": 20000,
          "description": "Gula pasir putih kristal, cocok untuk masak dan minuman.",
          "image_url": "\(unsplash("1581441363689-1f3c3c414635"))", "rating": 4.5, "sold_count": 410,
          "is_available": true },
        { "product_id": "P05", "product_name": "Susu UHT Full Cream 1 L", "category_id": "minuman",
          "price": 17900, "original_price": 27000, "discount_percent": 33,
          "description": "Susu sapi segar UHT, tahan lama tanpa pengawet.",
          "image_url": "\(unsplash("1563636619-e9143da7973b"))", "rating": 4.8, "sold_count": 890,
          "is_available": true, "tags": ["best_seller"],
          "options": [ { "id": "plain", "name": "Plain", "extra_price": 0 },
                       { "id": "cokelat", "name": "Cokelat", "extra_price": 0 } ] },
        { "product_id": "P06", "product_name": "Kopi Bubuk Robusta 250 g", "category_id": "minuman", "price": 25000,
          "description": "Kopi robusta giling dari petani Lampung.",
          "image_url": "\(unsplash("1559056199-641a0ac8b55e"))", "rating": 4.4, "sold_count": 220,
          "is_available": false },
        \(sayurPromo),
        { "product_id": "P08", "product_name": "Apel Fuji 1 kg", "category_id": "segar", "price": 38000,
          "description": "Apel fuji manis dan renyah, isi 5–6 buah.",
          "image_url": "\(unsplash("1610832958506-aa56368176cf"))", "rating": 4.6, "sold_count": 530,
          "is_available": true },
        { "product_id": "P09", "product_name": "Daging Sapi Has 250 g", "category_id": "protein", "price": 45000,
          "description": "Daging sapi lokal bagian has dalam, empuk untuk tumis atau steak.",
          "image_url": "\(unsplash("1607623814075-e51df1bdc82f"))", "rating": 4.7, "sold_count": 760,
          "is_available": true,
          "options": [ { "id": "iris", "name": "Iris Tipis", "extra_price": 0 },
                       { "id": "dadu", "name": "Potong Dadu", "extra_price": 0 } ] },
        { "product_id": "P10", "product_name": "Fillet Dada Ayam 500 g", "category_id": "protein", "price": 29000,
          "description": "Dada ayam tanpa tulang dan kulit, dipotong higienis.",
          "image_url": "\(unsplash("1604503468506-a8da13d82791"))", "rating": 4.6, "sold_count": 980,
          "is_available": true,
          "options": [ { "id": "polos", "name": "Polos", "extra_price": 0 },
                       { "id": "marinasi", "name": "Bumbu Marinasi", "extra_price": 8000 } ] },
        { "product_id": "P11", "product_name": "Deterjen Cair 1,6 L", "category_id": "rumah", "price": 42000,
          "description": "Deterjen cair untuk mesin cuci dan tangan, wangi tahan lama.",
          "image_url": "\(unsplash("1585421514738-01798e348b17"))", "rating": 4.8, "sold_count": 1040,
          "is_available": true, "tags": ["best_seller"] },
        { "product_id": "P12", "product_name": "Keripik Kentang 160 g", "category_id": "snack",
          "price": 12000, "original_price": 18000, "discount_percent": 33,
          "description": "Keripik kentang renyah rasa original.",
          "image_url": "\(unsplash("1566478989037-eec170784d0b"))", "rating": 4.5, "sold_count": 870,
          "is_available": true },
        { "product_id": "P13", "product_name": "Biskuit Cokelat 300 g", "category_id": "snack", "price": 21000,
          "description": "Biskuit renyah isi krim cokelat, pas buat teman ngeteh.",
          "image_url": "\(unsplash("1558961363-fa8fdf82db35"))", "rating": 4.6, "sold_count": 450,
          "is_available": true },
        { "product_id": "P14", "product_name": "Sabun Mandi Cair 900 ml", "category_id": "rumah", "price": 35000,
          "description": "Sabun mandi cair pouch isi ulang, lembut di kulit.",
          "image_url": "\(unsplash("1556228578-8c89e6adf883"))", "rating": 4.9, "sold_count": 690,
          "is_available": true, "tags": ["best_seller"] },
        { "product_id": "P98", "product_name": null, "price": 12000 },
        { "product_id": "P99", "product_name": "Barang Rahasia" }
      ]
    }
    """

    /// Stok per outlet (harga sama): Kemang Utara kehabisan daging sapi, Kelapa Gading kehabisan sabun mandi.
    static let soldOutByStore: [String: Set<String>] = ["ST02": ["P09"], "ST03": ["P14"]]

    /// `products` dengan `is_available` mengikuti outlet `storeID` (nil = stok pusat).
    static func productsJSON(storeID: String?) -> String {
        guard let storeID, let soldOut = soldOutByStore[storeID],
              var root = try? JSONSerialization.jsonObject(with: Data(products.utf8)) as? [String: Any],
              let items = root["data"] as? [[String: Any]] else { return products }
        root["data"] = items.map { item -> [String: Any] in
            var item = item
            if let id = item["product_id"] as? String, soldOut.contains(id) { item["is_available"] = false }
            return item
        }
        guard let data = try? JSONSerialization.data(withJSONObject: root) else { return products }
        return String(decoding: data, as: UTF8.self)
    }

    /// `GET /v1/stores` (§5.26). Kelapa Gading buka 10:00–22:00 (status ikut jam perangkat).
    static var stores: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let gadingOpen = (10..<22).contains(hour)
        let gadingNote = gadingOpen ? "null" : "\"Outlet Kelapa Gading buka 10:00–22:00.\""
        return """
        {
          "code": 200,
          "message": "success",
          "data": [
            { "id": "ST01", "name": "Gandaria City", "address": "Jl. Sultan Iskandar Muda, Jakarta Selatan",
              "is_open": true, "hours_label": "24 jam", "delivery_radius_km": 7,
              "distance_km": 1.4, "is_deliverable": true, "closed_note": null },
            { "id": "ST02", "name": "Kemang Utara", "address": "Jl. Kemang Utara Raya, Jakarta Selatan",
              "is_open": true, "hours_label": "24 jam", "delivery_radius_km": 5,
              "distance_km": 4.2, "is_deliverable": true, "closed_note": null },
            { "id": "ST03", "name": "Kelapa Gading", "address": "Jl. Boulevard Raya, Jakarta Utara",
              "is_open": \(gadingOpen), "hours_label": "10:00–22:00", "delivery_radius_km": 6,
              "distance_km": 18.9, "is_deliverable": false, "closed_note": \(gadingNote) }
          ]
        }
        """
    }

    /// Popup promo Beranda (§5.24). Berakhir 30 hari dari sekarang supaya mock selalu tampil.
    static var promoPopup: String {
        let endsAt = ISO8601DateFormatter().string(from: Date().addingTimeInterval(30 * 24 * 3600))
        return """
        {
          "code": 200,
          "message": "success",
          "data": {
            "id": "D01",
            "title": "Paket Sayur Segar cuma 19rb!",
            "subtitle": "Belanja dapur hemat minggu ini. Selama persediaan ada.",
            "badge": "HEMAT 37%",
            "image_url": "\(unsplash("1540420773420-3366772f4999", width: 1200))",
            "ends_at": "\(endsAt)",
            "product": \(sayurPromo)
          }
        }
        """
    }
}
