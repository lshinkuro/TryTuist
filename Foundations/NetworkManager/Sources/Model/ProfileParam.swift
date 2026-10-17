//
//  ProfileParam.swift
//  NetworkManager
//
//  Body request fitur Profil (API_PLAN.md §5.16, §5.17, §5.21).
//
import Foundation

/// `PATCH /v1/me`. Field `nil` tidak dikirim (tidak diubah). String kosong = hapus nilai.
public struct UpdateProfileParam {
    public let name: String?
    public let phone: String?
    public let avatarURL: String?

    public init(name: String? = nil, phone: String? = nil, avatarURL: String? = nil) {
        self.name = name
        self.phone = phone
        self.avatarURL = avatarURL
    }

    var body: [String: Any] {
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let phone { body["phone"] = phone }
        if let avatarURL { body["avatar_url"] = avatarURL }
        return body
    }
}

/// `POST /v1/me/addresses` (semua field) dan `PATCH /v1/me/addresses/{id}`.
public struct AddressParam {
    public let label: String
    public let recipient: String
    public let phone: String
    public let address: String
    public let notes: String?
    public let isDefault: Bool

    public init(label: String, recipient: String, phone: String, address: String, notes: String?, isDefault: Bool) {
        self.label = label
        self.recipient = recipient
        self.phone = phone
        self.address = address
        self.notes = notes
        self.isDefault = isDefault
    }

    var body: [String: Any] {
        [
            "label": label,
            "recipient": recipient,
            "phone": phone,
            "address": address,
            // "" → backend menghapus catatan.
            "notes": notes ?? "",
            "is_default": isDefault
        ]
    }
}

/// `POST /v1/me/payment-methods` — tautkan e-wallet.
public struct AddEWalletParam {
    public let provider: String
    public let accountNumber: String
    public let accountName: String?
    public let setDefault: Bool

    public init(provider: String, accountNumber: String, accountName: String?, setDefault: Bool) {
        self.provider = provider
        self.accountNumber = accountNumber
        self.accountName = accountName
        self.setDefault = setDefault
    }

    var body: [String: Any] {
        var body: [String: Any] = [
            "provider": provider,
            "account_number": accountNumber,
            "set_default": setDefault
        ]
        if let accountName, !accountName.isEmpty { body["account_name"] = accountName }
        return body
    }
}
