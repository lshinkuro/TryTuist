//
//  ProfileDTOs.swift
//  ProfileFeature · Data
//
//  Cermin JSON backend (API_PLAN.md §5.16, §5.17, §5.21–5.23). Semua field opsional:
//  Mapper yang memutuskan data mana yang wajib.
//
import Foundation
import NetworkManager

// MARK: - Profil (§5.16)

struct UserProfileDTO: Decodable {
    let id: String?
    let name: String?
    let email: String?
    let phone: String?
    let avatarURL: String?
    let memberTier: String?
    let points: Int?
    let voucherCount: Int?
    let balance: Int64?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, points, balance
        case avatarURL = "avatar_url"
        case memberTier = "member_tier"
        case voucherCount = "voucher_count"
    }
}

typealias UserProfileResponseDTO = APIEnvelope<UserProfileDTO>

// MARK: - Alamat (§5.17)

struct AddressDTO: Decodable {
    let id: String?
    let label: String?
    let recipient: String?
    let phone: String?
    let address: String?
    let notes: String?
    let isDefault: Bool?

    enum CodingKeys: String, CodingKey {
        case id, label, recipient, phone, address, notes
        case isDefault = "is_default"
    }
}

typealias AddressResponseDTO = APIEnvelope<AddressDTO>
typealias AddressListResponseDTO = APIEnvelope<[AddressDTO]>
typealias EmptyResponseDTO = APIEnvelope<EmptyDTO>

// MARK: - Metode pembayaran (§5.21)

struct PaymentMethodDTO: Decodable {
    let id: String?
    let type: String?
    let provider: String?
    let name: String?
    let description: String?
    let icon: String?
    let accountMasked: String?
    let accountName: String?
    let isEnabled: Bool?
    let isDefault: Bool?
    let isRemovable: Bool?

    enum CodingKeys: String, CodingKey {
        case id, type, provider, name, description, icon
        case accountMasked = "account_masked"
        case accountName = "account_name"
        case isEnabled = "is_enabled"
        case isDefault = "is_default"
        case isRemovable = "is_removable"
    }
}

struct EWalletProviderDTO: Decodable {
    let id: String?
    let name: String?
    let icon: String?
    let tint: String?
}

struct PaymentOverviewDTO: Decodable {
    let defaultID: String?
    let canAddEWallet: Bool?
    let methods: [PaymentMethodDTO]?
    let providers: [EWalletProviderDTO]?

    enum CodingKeys: String, CodingKey {
        case methods
        case defaultID = "default_id"
        case canAddEWallet = "can_add_ewallet"
        case providers = "ewallet_providers"
    }
}

typealias PaymentOverviewResponseDTO = APIEnvelope<PaymentOverviewDTO>

// MARK: - Pusat bantuan (§5.22)

struct HelpArticleDTO: Decodable {
    let id: String?
    let question: String?
    let answer: String?
}

struct HelpTopicDTO: Decodable {
    let id: String?
    let title: String?
    let icon: String?
    let articles: [HelpArticleDTO]?
}

struct HelpContactDTO: Decodable {
    let type: String?
    let label: String?
    let value: String?
    let icon: String?
    let url: String?
}

struct HelpCenterDTO: Decodable {
    let topics: [HelpTopicDTO]?
    let contacts: [HelpContactDTO]?
    let operatingHours: String?

    enum CodingKeys: String, CodingKey {
        case topics, contacts
        case operatingHours = "operating_hours"
    }
}

typealias HelpCenterResponseDTO = APIEnvelope<HelpCenterDTO>

// MARK: - Legal (§5.23)

struct LegalSectionDTO: Decodable {
    let heading: String?
    let body: String?
}

struct LegalDocumentDTO: Decodable {
    let slug: String?
    let title: String?
    let version: String?
    let summary: String?
    /// "YYYY-MM-DD"
    let effectiveAt: String?
    let sections: [LegalSectionDTO]?

    enum CodingKeys: String, CodingKey {
        case slug, title, version, summary, sections
        case effectiveAt = "effective_at"
    }
}

typealias LegalDocumentResponseDTO = APIEnvelope<LegalDocumentDTO>
