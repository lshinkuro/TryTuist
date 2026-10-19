//
//  ProfileMockDataSource.swift
//  ProfileFeature · Data
//
//  Meniru backend tanpa network (`USE_MOCK_DATA = YES`). State disimpan di memori
//  selama app berjalan, jadi tambah/ubah/hapus terasa seperti API asli.
//  Bentuk JSON & error sama dengan API_PLAN.md §5.16–5.23.
//
import Foundation
import NetworkManager

struct ProfileMockDataSource: ProfileRemoteDataSource {
    var latency: Duration = .milliseconds(400)
    private let store = MockProfileStore.shared

    func fetchProfile() async throws -> UserProfileResponseDTO {
        try await wait()
        return try envelope(await store.profileJSON())
    }

    func updateProfile(_ param: UpdateProfileParam) async throws -> UserProfileResponseDTO {
        try await wait()
        return try envelope(try await store.updateProfile(param))
    }

    func fetchAddresses() async throws -> AddressListResponseDTO {
        try await wait()
        return try envelope(await store.addressesJSON())
    }

    func createAddress(_ param: AddressParam) async throws -> AddressResponseDTO {
        try await wait()
        return try envelope(await store.saveAddress(id: nil, param), code: 201)
    }

    func updateAddress(id: String, _ param: AddressParam) async throws -> AddressResponseDTO {
        try await wait()
        return try envelope(try await store.saveAddress(id: id, param))
    }

    func deleteAddress(id: String) async throws -> EmptyResponseDTO {
        try await wait()
        try await store.deleteAddress(id: id)
        return try envelope(NSNull())
    }

    func fetchPaymentOverview() async throws -> PaymentOverviewResponseDTO {
        try await wait()
        return try envelope(await store.paymentJSON())
    }

    func addEWallet(_ param: AddEWalletParam) async throws -> PaymentOverviewResponseDTO {
        try await wait()
        return try envelope(try await store.addEWallet(param), code: 201)
    }

    func setDefaultPaymentMethod(id: String) async throws -> PaymentOverviewResponseDTO {
        try await wait()
        return try envelope(try await store.setDefaultPayment(id: id))
    }

    func deletePaymentMethod(id: String) async throws -> PaymentOverviewResponseDTO {
        try await wait()
        return try envelope(try await store.deletePayment(id: id))
    }

    func fetchHelpCenter(query: String?) async throws -> HelpCenterResponseDTO {
        try await wait()
        return try envelope(MockProfileStore.helpJSON(query: query))
    }

    func fetchLegalDocument(slug: String) async throws -> LegalDocumentResponseDTO {
        try await wait()
        guard let doc = MockProfileStore.legal[slug] else {
            throw APIServerError(statusCode: 404, type: "NOT_FOUND", message: "Dokumen tidak ditemukan.")
        }
        return try envelope(doc)
    }

    func changePassword(current: String, new: String) async throws -> PasswordSessionResponseDTO {
        try await wait()
        guard current == "12345678" else {
            throw APIServerError(statusCode: 400, type: "VALIDATION_ERROR", message: "Password saat ini salah.",
                                 fieldErrors: ["current_password": "salah"])
        }
        return try envelope(["access_token": "mock-access-\(UUID().uuidString)", "refresh_token": "mock-refresh-\(UUID().uuidString)",
                             "expires_at": Int(Date().addingTimeInterval(7 * 24 * 3600).timeIntervalSince1970)])
    }

    func sendEmailVerification() async throws -> EmptyResponseDTO {
        try await wait()
        return try envelope(NSNull())
    }

    /// Akun mock sudah terverifikasi; kode `123456` selalu diterima.
    func verifyEmail(code: String) async throws -> EmptyResponseDTO {
        try await wait()
        guard code == "123456" else {
            throw APIServerError(statusCode: 422, type: "INVALID_CODE", message: "Kode salah atau sudah kedaluwarsa.")
        }
        return try envelope(NSNull())
    }

    // MARK: - Helpers

    private func wait() async throws {
        try await Task.sleep(for: latency)
    }

    private func envelope<T: Decodable>(_ data: Any, code: Int = 200) throws -> APIEnvelope<T> {
        let json: [String: Any] = ["code": code, "message": "success", "data": data]
        return try JSONDecoder().decode(APIEnvelope<T>.self, from: JSONSerialization.data(withJSONObject: json))
    }
}

/// State bersama semua instance mock (actor = aman dipanggil dari banyak Task).
actor MockProfileStore {
    static let shared = MockProfileStore()

    private var name = "Kholis"
    private var phone: String? = "081234567890"
    private var addresses: [[String: Any]] = [[
        "id": "addr-1", "label": "Rumah", "recipient": "Kholis", "phone": "081234567890",
        "address": "Jl. Kebayoran Lama No. 12, Jakarta Selatan", "notes": "Pagar hitam", "is_default": true
    ]]
    private var wallets: [[String: String]] = []
    private var defaultPayment = "COD"
    private var nextID = 2

    // MARK: Profil

    func profileJSON() -> [String: Any] {
        [
            "id": "mock-user", "name": name, "email": "kholis@gmail.com",
            "phone": phone.map { $0 as Any } ?? NSNull(), "avatar_url": NSNull(),
            "member_tier": "GOLD", "points": 1250, "voucher_count": 3, "balance": 50000
        ]
    }

    func updateProfile(_ param: UpdateProfileParam) throws -> [String: Any] {
        if let newName = param.name {
            guard !newName.isEmpty else { throw Self.validation("name", "wajib diisi") }
            name = newName
        }
        if let newPhone = param.phone {
            phone = newPhone.isEmpty ? nil : newPhone
        }
        return profileJSON()
    }

    // MARK: Alamat

    func addressesJSON() -> [[String: Any]] {
        addresses.sorted { ($0["is_default"] as? Bool ?? false) && !($1["is_default"] as? Bool ?? false) }
    }

    func saveAddress(id: String?, _ param: AddressParam) throws -> [String: Any] {
        let isFirst = addresses.isEmpty
        let makeDefault = param.isDefault || isFirst
        if makeDefault {
            for index in addresses.indices { addresses[index]["is_default"] = false }
        }
        let addressID = id ?? "addr-\(issueID())"
        let item: [String: Any] = [
            "id": addressID, "label": param.label, "recipient": param.recipient, "phone": param.phone,
            "address": param.address, "notes": param.notes.map { $0 as Any } ?? NSNull(), "is_default": makeDefault
        ]
        if let id {
            guard let index = addresses.firstIndex(where: { $0["id"] as? String == id }) else {
                throw APIServerError(statusCode: 404, type: "NOT_FOUND", message: "Alamat tidak ditemukan.")
            }
            addresses[index] = item
        } else {
            addresses.append(item)
        }
        ensureDefaultAddress()
        return addresses.first(where: { $0["id"] as? String == addressID }) ?? item
    }

    func deleteAddress(id: String) throws {
        guard addresses.contains(where: { $0["id"] as? String == id }) else {
            throw APIServerError(statusCode: 404, type: "NOT_FOUND", message: "Alamat tidak ditemukan.")
        }
        addresses.removeAll { $0["id"] as? String == id }
        ensureDefaultAddress()
    }

    /// Sama dengan backend: selama ada alamat, selalu ada satu yang utama.
    private func ensureDefaultAddress() {
        guard !addresses.isEmpty, !addresses.contains(where: { $0["is_default"] as? Bool == true }) else { return }
        addresses[addresses.count - 1]["is_default"] = true
    }

    // MARK: Pembayaran

    private static let providers: [[String: String]] = [
        ["id": "GOPAY", "name": "GoPay", "icon": "wallet.pass.fill", "tint": "teal"],
        ["id": "OVO", "name": "OVO", "icon": "wallet.pass.fill", "tint": "purple"],
        ["id": "DANA", "name": "DANA", "icon": "wallet.pass.fill", "tint": "blue"],
        ["id": "SHOPEEPAY", "name": "ShopeePay", "icon": "wallet.pass.fill", "tint": "orange"]
    ]

    func paymentJSON() -> [String: Any] {
        var methods: [[String: Any]] = [
            ["id": "COD", "type": "COD", "name": "Bayar di Tempat", "description": "Bayar tunai ke kurir saat pesanan tiba",
             "icon": "banknote", "is_enabled": true, "is_default": defaultPayment == "COD", "is_removable": false],
            ["id": "QRIS", "type": "QRIS", "name": "QRIS", "description": "Scan QR dari aplikasi bank atau e-wallet apa pun",
             "icon": "qrcode", "is_enabled": true, "is_default": defaultPayment == "QRIS", "is_removable": false]
        ]
        for wallet in wallets {
            let id = wallet["id"] ?? ""
            let number = wallet["account_number"] ?? ""
            let provider = Self.providers.first { $0["id"] == wallet["provider"] }
            methods.append([
                "id": id, "type": "EWALLET", "provider": wallet["provider"] ?? "",
                "name": provider?["name"] ?? wallet["provider"] ?? "", "icon": "wallet.pass.fill",
                "account_masked": Self.mask(number), "account_name": wallet["account_name"].map { $0 as Any } ?? NSNull(),
                "is_enabled": true, "is_default": defaultPayment == id, "is_removable": true
            ])
        }
        return [
            "default_id": defaultPayment,
            "can_add_ewallet": wallets.count < 10,
            "methods": methods,
            "ewallet_providers": Self.providers
        ]
    }

    func addEWallet(_ param: AddEWalletParam) throws -> [String: Any] {
        let provider = param.provider.uppercased()
        guard Self.providers.contains(where: { $0["id"] == provider }) else {
            throw Self.validation("provider", "penyedia e-wallet tidak dikenal")
        }
        guard !wallets.contains(where: { $0["provider"] == provider && $0["account_number"] == param.accountNumber }) else {
            throw APIServerError(statusCode: 409, type: "PAYMENT_METHOD_EXISTS", message: "E-wallet dengan nomor ini sudah tersimpan.")
        }
        guard wallets.count < 10 else {
            throw APIServerError(statusCode: 422, type: "PAYMENT_METHOD_LIMIT", message: "Maksimal 10 e-wallet tersimpan.")
        }
        let id = "pm-\(issueID())"
        var wallet = ["id": id, "provider": provider, "account_number": param.accountNumber]
        if let name = param.accountName, !name.isEmpty { wallet["account_name"] = name }
        wallets.append(wallet)
        if param.setDefault { defaultPayment = id }
        return paymentJSON()
    }

    func setDefaultPayment(id: String) throws -> [String: Any] {
        let builtin = ["COD", "QRIS"].contains(id.uppercased())
        guard builtin || wallets.contains(where: { $0["id"] == id }) else {
            throw APIServerError(statusCode: 404, type: "NOT_FOUND", message: "Metode pembayaran tidak ditemukan.")
        }
        defaultPayment = builtin ? id.uppercased() : id
        return paymentJSON()
    }

    func deletePayment(id: String) throws -> [String: Any] {
        guard wallets.contains(where: { $0["id"] == id }) else {
            throw APIServerError(statusCode: 404, type: "NOT_FOUND", message: "Metode pembayaran tidak ditemukan.")
        }
        wallets.removeAll { $0["id"] == id }
        if defaultPayment == id { defaultPayment = "COD" }
        return paymentJSON()
    }

    // MARK: Helpers

    private func issueID() -> Int {
        defer { nextID += 1 }
        return nextID
    }

    private static func mask(_ number: String) -> String {
        guard number.count > 8 else { return number }
        return String(number.prefix(4)) + "••••" + String(number.suffix(4))
    }

    private static func validation(_ field: String, _ message: String) -> APIServerError {
        APIServerError(statusCode: 400, type: "VALIDATION_ERROR", message: "Data yang dikirim tidak valid.",
                       fieldErrors: [field: message])
    }

    // MARK: Konten statis

    static func helpJSON(query: String?) -> [String: Any] {
        let topics: [[String: Any]] = [
            ["id": "order", "title": "Pesanan", "icon": "bag.fill", "articles": [
                ["id": "order-how", "question": "Bagaimana cara memesan?",
                 "answer": "Pilih menu di Beranda atau tab Menu, atur varian dan jumlah, lalu tekan \"Tambah ke keranjang\".\n\nBuka Keranjang, periksa pesanan, lalu tekan \"Pesan Sekarang\"."],
                ["id": "order-cancel", "question": "Bisakah saya membatalkan pesanan?",
                 "answer": "Bisa, selama status pesanan masih \"Menunggu\".\n\nPesanan yang sudah diproses outlet tidak bisa dibatalkan."]
            ]],
            ["id": "payment", "title": "Pembayaran", "icon": "creditcard.fill", "articles": [
                ["id": "payment-methods", "question": "Metode pembayaran apa saja yang tersedia?",
                 "answer": "Bayar di Tempat (COD), QRIS, dan e-wallet (GoPay, OVO, DANA, ShopeePay)."],
                ["id": "payment-ewallet", "question": "Bagaimana cara menautkan e-wallet?",
                 "answer": "Buka Profil > Metode Pembayaran > Tambah E-Wallet, lalu masukkan nomor HP yang terdaftar."]
            ]],
            ["id": "delivery", "title": "Pengiriman", "icon": "bicycle", "articles": [
                ["id": "delivery-time", "question": "Berapa lama pesanan sampai?",
                 "answer": "Rata-rata 20–40 menit, tergantung jarak outlet dan antrean pesanan."]
            ]]
        ]
        let q = query?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let filtered: [[String: Any]] = q.isEmpty ? topics : topics.compactMap { topic in
            let articles = (topic["articles"] as? [[String: String]] ?? []).filter {
                ($0["question"] ?? "").lowercased().contains(q) || ($0["answer"] ?? "").lowercased().contains(q)
            }
            guard !articles.isEmpty else { return nil }
            var copy = topic
            copy["articles"] = articles
            return copy
        }
        return [
            "query": q.isEmpty ? NSNull() as Any : q,
            "operating_hours": "Setiap hari, 08.00–22.00 WIB",
            "topics": filtered,
            "contacts": [
                ["type": "WHATSAPP", "label": "Chat WhatsApp", "value": "+62 812-1000-2000", "icon": "message.fill", "url": "https://wa.me/6281210002000"],
                ["type": "EMAIL", "label": "Email", "value": "halo@trytuist.com", "icon": "envelope.fill", "url": "mailto:halo@trytuist.com"],
                ["type": "PHONE", "label": "Telepon", "value": "1500-123", "icon": "phone.fill", "url": "tel:1500123"]
            ]
        ]
    }

    static let legal: [String: [String: Any]] = [
        "privacy-policy": [
            "slug": "privacy-policy", "title": "Kebijakan Privasi", "version": "1.0", "effective_at": "2026-10-01",
            "summary": "Kami hanya mengumpulkan data yang dibutuhkan untuk memproses pesananmu, dan tidak pernah menjual data pribadimu.",
            "sections": [
                ["heading": "1. Data yang kami kumpulkan", "body": "Nama, email, nomor HP, alamat pengiriman, riwayat pesanan, dan nomor HP e-wallet yang kamu tautkan."],
                ["heading": "2. Cara kami memakai data", "body": "Untuk memproses dan mengantar pesanan, menghubungimu soal pesanan, serta menjaga keamanan akun."],
                ["heading": "3. Hak kamu", "body": "Kamu bisa mengubah data di menu Profil atau meminta penghapusan akun lewat Pusat Bantuan."]
            ]
        ],
        "terms": [
            "slug": "terms", "title": "Syarat & Ketentuan", "version": "1.0", "effective_at": "2026-10-01",
            "sections": [["heading": "1. Akun", "body": "Kamu bertanggung jawab menjaga kerahasiaan password akunmu."]]
        ]
    ]
}
