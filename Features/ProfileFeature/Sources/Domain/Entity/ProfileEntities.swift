//
//  ProfileEntities.swift
//  ProfileFeature · Domain
//
//  Model yang dipakai Presentation. Tidak tahu apa-apa soal JSON backend.
//
import Foundation

struct UserProfile: Equatable {
    enum Tier: String, Equatable {
        case silver = "SILVER"
        case gold = "GOLD"
        case platinum = "PLATINUM"

        var title: String {
            switch self {
            case .silver: return String(localized: "Member Silver")
            case .gold: return String(localized: "Member Gold")
            case .platinum: return String(localized: "Member Platinum")
            }
        }
    }

    let id: String
    var name: String
    let email: String
    var phone: String?
    var avatarURL: URL?
    let tier: Tier
    let points: Int
    let voucherCount: Int
    let balance: Decimal
}

/// Perubahan dari form Edit Profil. `nil` = tidak diubah, `phone == ""` = hapus nomor HP.
struct ProfileChanges: Equatable {
    var name: String?
    var phone: String?

    var isEmpty: Bool { name == nil && phone == nil }
}

// MARK: - Alamat

struct Address: Identifiable, Equatable {
    let id: String
    var label: String
    var recipient: String
    var phone: String
    var address: String
    var notes: String?
    var isDefault: Bool
}

/// Isi form alamat (tambah / ubah).
struct AddressDraft: Equatable {
    var label = ""
    var recipient = ""
    var phone = ""
    var address = ""
    var notes = ""
    var isDefault = false

    init() {}

    init(_ address: Address) {
        label = address.label
        recipient = address.recipient
        phone = address.phone
        self.address = address.address
        notes = address.notes ?? ""
        isDefault = address.isDefault
    }
}

// MARK: - Metode pembayaran

struct PaymentMethod: Identifiable, Equatable {
    enum Kind: Equatable {
        /// Bayar Online lewat Midtrans (GoPay, QRIS, ShopeePay, VA, kartu).
        case online
        case cashOnDelivery
        case qris
        case eWallet(provider: String)
    }

    let id: String
    let kind: Kind
    let name: String
    /// Deskripsi metode bawaan, atau nomor tersamar e-wallet ("0812••••7890").
    let detail: String?
    let systemImage: String
    let isEnabled: Bool
    let isDefault: Bool
    let isRemovable: Bool
}

struct EWalletProvider: Identifiable, Equatable {
    let id: String
    let name: String
    let systemImage: String
    /// Nama warna dari backend ("teal", "purple", …). Presentation yang menerjemahkan ke Color.
    let tint: String
}

struct PaymentOverview: Equatable {
    let defaultID: String
    let methods: [PaymentMethod]
    let providers: [EWalletProvider]
    let canAddEWallet: Bool

    var builtins: [PaymentMethod] { methods.filter { !$0.isRemovable } }
    var eWallets: [PaymentMethod] { methods.filter { $0.isRemovable } }
}

struct NewEWallet: Equatable {
    var providerID: String
    var accountNumber: String
    var accountName: String
    var setAsDefault: Bool
}

// MARK: - Bantuan

struct HelpArticle: Identifiable, Equatable {
    let id: String
    let question: String
    let answer: String
}

struct HelpTopic: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let articles: [HelpArticle]
}

struct HelpContact: Identifiable, Equatable {
    enum Kind: String, Equatable {
        case whatsapp = "WHATSAPP"
        case email = "EMAIL"
        case phone = "PHONE"
        case other
    }

    var id: String { url.absoluteString }
    let kind: Kind
    let label: String
    let value: String
    let systemImage: String
    let url: URL
}

struct HelpCenter: Equatable {
    let topics: [HelpTopic]
    let contacts: [HelpContact]
    let operatingHours: String?

    var articleCount: Int { topics.reduce(0) { $0 + $1.articles.count } }
}

// MARK: - Legal

enum LegalDocumentKind: String, Equatable {
    case privacyPolicy = "privacy-policy"
    case terms = "terms"

    var title: String {
        switch self {
        case .privacyPolicy: return String(localized: "Kebijakan Privasi")
        case .terms: return String(localized: "Syarat & Ketentuan")
        }
    }
}

struct LegalDocument: Equatable {
    struct Section: Identifiable, Equatable {
        let id: Int
        let heading: String
        let body: String
    }

    let kind: LegalDocumentKind
    let title: String
    let version: String
    let summary: String?
    let effectiveDate: Date?
    let sections: [Section]
}
