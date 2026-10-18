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
        { "id": "B1", "title": "Diskon 30% Makan Siang", "subtitle": "Semua menu makanan, khusus jam 11–14",
          "image_url": "\(unsplash("1547573854-74d2a71d0826", width: 1200))" },
        { "id": "B2", "title": "Gratis Ongkir Rp 0", "subtitle": "Min. belanja Rp 50.000 se-Jakarta",
          "image_url": "\(unsplash("1424847651672-bf20a4b0982b", width: 1200))" },
        { "id": "B3", "title": "Kopi Pagi Cuma 15rb", "subtitle": "Setiap hari sebelum jam 10 pagi",
          "image_url": "\(unsplash("1596018589878-217d8603c4c6", width: 1200))" }
      ]
    }
    """

    static let categories = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "id": "coffee", "name": "Kopi", "icon": "☕️" },
        { "id": "non_coffee", "name": "Non-Kopi", "icon": "🍵" },
        { "id": "rice", "name": "Nasi & Mie", "icon": "🍛" },
        { "id": "fast_food", "name": "Burger & Ayam", "icon": "🍔" },
        { "id": "snack", "name": "Camilan", "icon": "🍟" },
        { "id": "dessert", "name": "Dessert", "icon": "🍰" }
      ]
    }
    """

    private static let drinkOptions = """
    [ { "id": "regular", "name": "Regular", "extra_price": 0 },
      { "id": "large", "name": "Large", "extra_price": 5000 } ]
    """

    private static let foodOptions = """
    [ { "id": "normal", "name": "Normal", "extra_price": 0 },
      { "id": "spicy", "name": "Pedas", "extra_price": 0 },
      { "id": "jumbo", "name": "Porsi Jumbo", "extra_price": 8000 } ]
    """

    /// P07 sedang promo (dipakai juga oleh popup Beranda). Sama dengan seed backend D01.
    private static let nasiGorengPromo = """
    { "product_id": "P07", "product_name": "Nasi Goreng Spesial", "category_id": "rice",
      "price": 19900, "original_price": 32000, "discount_percent": 37,
      "description": "Nasi goreng bumbu rumahan dengan telur, ayam suwir, dan kerupuk.",
      "image_url": "\(unsplash("1512058564366-18510be2db19"))", "rating": 4.8, "sold_count": 1210,
      "is_available": true, "tags": ["best_seller", "promo"], "options": \(foodOptions) }
    """

    /// Dua item terakhir sengaja tidak valid (tanpa nama / tanpa harga) → dibuang oleh Mapper.
    static let products = """
    {
      "code": 200,
      "message": "success",
      "data": [
        { "product_id": "P01", "product_name": "Es Kopi Susu Gula Aren", "category_id": "coffee", "price": 22000,
          "description": "Espresso, susu segar, dan gula aren asli. Manisnya pas, cocok buat semangat seharian.",
          "image_url": "\(unsplash("1767471716700-2b3aa77b1ab6"))", "rating": 4.9, "sold_count": 1520,
          "is_available": true, "tags": ["best_seller"], "options": \(drinkOptions) },
        { "product_id": "P02", "product_name": "Cappuccino", "category_id": "coffee", "price": 25000,
          "description": "Espresso dengan foam susu yang lembut dan tebal.",
          "image_url": "\(unsplash("1563311977-d285756282dc"))", "rating": 4.7, "sold_count": 640,
          "is_available": true, "options": \(drinkOptions) },
        { "product_id": "P03", "product_name": "Caffe Latte", "category_id": "coffee", "price": 24000,
          "description": "Espresso dan susu steamed dengan latte art cantik.",
          "image_url": "\(unsplash("1593443320739-77f74939d0da"))", "rating": 4.6, "sold_count": 580,
          "is_available": true, "options": \(drinkOptions) },
        { "product_id": "P04", "product_name": "Iced Americano", "category_id": "coffee", "price": 20000,
          "description": "Double shot espresso dengan air dingin dan es batu. Segar tanpa gula.",
          "image_url": "\(unsplash("1676506739319-70bff65bfc48"))", "rating": 4.5, "sold_count": 410,
          "is_available": true, "options": \(drinkOptions) },
        { "product_id": "P05", "product_name": "Iced Matcha Latte", "category_id": "non_coffee",
          "price": 17900, "original_price": 27000, "discount_percent": 33,
          "description": "Matcha premium dari Uji, Jepang, dengan susu segar dan es.",
          "image_url": "\(unsplash("1749280447307-31a68eb38673"))", "rating": 4.8, "sold_count": 890,
          "is_available": true, "tags": ["best_seller"], "options": \(drinkOptions) },
        { "product_id": "P06", "product_name": "Hot Matcha", "category_id": "non_coffee", "price": 25000,
          "description": "Matcha hangat yang creamy, pas untuk sore hari.",
          "image_url": "\(unsplash("1515823064-d6e0c04616a7"))", "rating": 4.4, "sold_count": 220,
          "is_available": false, "options": \(drinkOptions) },
        \(nasiGorengPromo),
        { "product_id": "P08", "product_name": "Nasi Goreng Udang", "category_id": "rice", "price": 38000,
          "description": "Nasi goreng dengan udang segar dan sayuran.",
          "image_url": "\(unsplash("1551326844-4df70f78d0e9"))", "rating": 4.6, "sold_count": 530,
          "is_available": true, "options": \(foodOptions) },
        { "product_id": "P09", "product_name": "Ramen Pedas", "category_id": "rice", "price": 45000,
          "description": "Kuah kaldu kaya rasa, mie kenyal, telur ajitama, dan chashu.",
          "image_url": "\(unsplash("1509680859026-7d8cfc6894f4"))", "rating": 4.7, "sold_count": 760,
          "is_available": true, "options": \(foodOptions) },
        { "product_id": "P10", "product_name": "Ayam Goreng Krispi", "category_id": "fast_food", "price": 29000,
          "description": "Ayam goreng tepung renyah dengan saus sambal spesial.",
          "image_url": "\(unsplash("1585703900468-13c7a978ad86"))", "rating": 4.6, "sold_count": 980,
          "is_available": true, "options": \(foodOptions) },
        { "product_id": "P11", "product_name": "Classic Beef Burger", "category_id": "fast_food", "price": 42000,
          "description": "Patty daging sapi, keju cheddar, selada, dan saus rahasia.",
          "image_url": "\(unsplash("1543339469-94ba2391431f"))", "rating": 4.8, "sold_count": 1040,
          "is_available": true, "tags": ["best_seller"] },
        { "product_id": "P12", "product_name": "Kentang Goreng", "category_id": "snack",
          "price": 12000, "original_price": 18000, "discount_percent": 33,
          "description": "Kentang goreng renyah dengan saus tomat.",
          "image_url": "\(unsplash("1716042998725-0e0b957b9d99"))", "rating": 4.5, "sold_count": 870,
          "is_available": true },
        { "product_id": "P13", "product_name": "Butter Croissant", "category_id": "snack", "price": 21000,
          "description": "Croissant mentega yang flaky, dipanggang setiap pagi.",
          "image_url": "\(unsplash("1623334044303-241021148842"))", "rating": 4.6, "sold_count": 450,
          "is_available": true },
        { "product_id": "P14", "product_name": "Chocolate Cake", "category_id": "dessert", "price": 35000,
          "description": "Kue cokelat lembap dengan ganache dark chocolate.",
          "image_url": "\(unsplash("1517427294546-5aa121f68e8a"))", "rating": 4.9, "sold_count": 690,
          "is_available": true, "tags": ["best_seller"] },
        { "product_id": "P98", "product_name": null, "price": 12000 },
        { "product_id": "P99", "product_name": "Menu Rahasia" }
      ]
    }
    """

    /// Stok per outlet (harga sama): Kemang Utara kehabisan Ramen Pedas, Kelapa Gading kehabisan Chocolate Cake.
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
            "title": "Nasi Goreng Spesial cuma 19rb!",
            "subtitle": "Promo makan hemat minggu ini. Selama persediaan ada.",
            "badge": "HEMAT 37%",
            "image_url": "\(unsplash("1512058564366-18510be2db19", width: 1200))",
            "ends_at": "\(endsAt)",
            "product": \(nasiGorengPromo)
          }
        }
        """
    }
}
