//
//  ProfileMapper.swift
//  ProfileFeature · Data
//
//  Satu-satunya tempat yang "menerjemahkan" backend:
//  DTO → Entity, Entity → Param request, error network → ProfileError.
//  Item yang field wajibnya kosong dibuang (compactMap), bukan membuat app crash.
//
import Foundation
import NetworkManager

enum ProfileMapper {
    // MARK: - Profil

    static func profile(from response: UserProfileResponseDTO) throws -> UserProfile {
        guard let dto = response.data, let id = dto.id, let email = dto.email else { throw ProfileError.unknown }
        return UserProfile(
            id: id,
            name: dto.name?.nonEmpty ?? email.components(separatedBy: "@").first ?? email,
            email: email,
            phone: dto.phone?.nonEmpty,
            avatarURL: dto.avatarURL.flatMap({ URL(string: $0) }),
            tier: UserProfile.Tier(rawValue: dto.memberTier?.uppercased() ?? "") ?? .silver,
            points: max(dto.points ?? 0, 0),
            voucherCount: max(dto.voucherCount ?? 0, 0),
            balance: Decimal(dto.balance ?? 0)
        )
    }

    static func param(from changes: ProfileChanges) -> UpdateProfileParam {
        UpdateProfileParam(name: changes.name, phone: changes.phone)
    }

    // MARK: - Alamat

    static func address(from dto: AddressDTO) -> Address? {
        guard let id = dto.id, let label = dto.label, let address = dto.address else { return nil }
        return Address(id: id,
                       label: label,
                       recipient: dto.recipient ?? "",
                       phone: dto.phone ?? "",
                       address: address,
                       notes: dto.notes?.nonEmpty,
                       isDefault: dto.isDefault ?? false)
    }

    static func address(from response: AddressResponseDTO) throws -> Address {
        guard let dto = response.data, let address = address(from: dto) else { throw ProfileError.unknown }
        return address
    }

    /// Alamat utama selalu di atas (backend juga mengurutkan begitu).
    static func addresses(from response: AddressListResponseDTO) -> [Address] {
        (response.data ?? []).compactMap(address(from:)).sorted { $0.isDefault && !$1.isDefault }
    }

    static func param(from draft: AddressDraft) -> AddressParam {
        AddressParam(label: draft.label, recipient: draft.recipient, phone: draft.phone,
                     address: draft.address, notes: draft.notes.nonEmpty, isDefault: draft.isDefault)
    }

    // MARK: - Metode pembayaran

    static func paymentOverview(from response: PaymentOverviewResponseDTO) throws -> PaymentOverview {
        guard let dto = response.data else { throw ProfileError.unknown }
        let methods = (dto.methods ?? []).compactMap(paymentMethod(from:))
        let defaultID = dto.defaultID ?? methods.first(where: \.isDefault)?.id ?? "COD"
        return PaymentOverview(
            defaultID: defaultID,
            methods: methods,
            providers: (dto.providers ?? []).compactMap(provider(from:)),
            canAddEWallet: dto.canAddEWallet ?? false
        )
    }

    static func paymentMethod(from dto: PaymentMethodDTO) -> PaymentMethod? {
        guard let id = dto.id, let name = dto.name else { return nil }
        let kind: PaymentMethod.Kind
        switch dto.type?.uppercased() {
        case "ONLINE": kind = .online
        case "COD": kind = .cashOnDelivery
        case "QRIS": kind = .qris
        case "EWALLET": kind = .eWallet(provider: dto.provider ?? "")
        default: return nil // tipe baru yang belum dikenal app: disembunyikan
        }
        let detail: String?
        if case .eWallet = kind {
            detail = [dto.accountMasked, dto.accountName?.nonEmpty].compactMap { $0 }.joined(separator: " · ").nonEmpty
        } else {
            detail = dto.description?.nonEmpty
        }
        return PaymentMethod(id: id, kind: kind, name: name, detail: detail,
                             systemImage: dto.icon?.nonEmpty ?? defaultIcon(for: kind),
                             isEnabled: dto.isEnabled ?? true,
                             isDefault: dto.isDefault ?? false,
                             isRemovable: dto.isRemovable ?? false)
    }

    static func provider(from dto: EWalletProviderDTO) -> EWalletProvider? {
        guard let id = dto.id, let name = dto.name else { return nil }
        return EWalletProvider(id: id, name: name, systemImage: dto.icon?.nonEmpty ?? "wallet.pass.fill", tint: dto.tint ?? "")
    }

    static func param(from wallet: NewEWallet) -> AddEWalletParam {
        AddEWalletParam(provider: wallet.providerID, accountNumber: wallet.accountNumber,
                        accountName: wallet.accountName.nonEmpty, setDefault: wallet.setAsDefault)
    }

    private static func defaultIcon(for kind: PaymentMethod.Kind) -> String {
        switch kind {
        case .online: return "creditcard.fill"
        case .cashOnDelivery: return "banknote"
        case .qris: return "qrcode"
        case .eWallet: return "wallet.pass.fill"
        }
    }

    // MARK: - Bantuan

    static func helpCenter(from response: HelpCenterResponseDTO) throws -> HelpCenter {
        guard let dto = response.data else { throw ProfileError.unknown }
        let topics: [HelpTopic] = (dto.topics ?? []).compactMap { topic in
            guard let id = topic.id, let title = topic.title else { return nil }
            let articles: [HelpArticle] = (topic.articles ?? []).compactMap { article in
                guard let id = article.id, let question = article.question, let answer = article.answer else { return nil }
                return HelpArticle(id: id, question: question, answer: answer)
            }
            guard !articles.isEmpty else { return nil }
            return HelpTopic(id: id, title: title, systemImage: topic.icon?.nonEmpty ?? "questionmark.circle.fill", articles: articles)
        }
        let contacts: [HelpContact] = (dto.contacts ?? []).compactMap { contact in
            // Hanya skema yang aman dibuka dari app.
            guard let label = contact.label, let raw = contact.url, let url = URL(string: raw),
                  let scheme = url.scheme?.lowercased(), ["https", "mailto", "tel"].contains(scheme) else { return nil }
            return HelpContact(kind: HelpContact.Kind(rawValue: contact.type?.uppercased() ?? "") ?? .other,
                               label: label,
                               value: contact.value ?? "",
                               systemImage: contact.icon?.nonEmpty ?? "bubble.left.fill",
                               url: url)
        }
        return HelpCenter(topics: topics, contacts: contacts, operatingHours: dto.operatingHours?.nonEmpty)
    }

    // MARK: - Legal

    static func legalDocument(_ kind: LegalDocumentKind, from response: LegalDocumentResponseDTO) throws -> LegalDocument {
        guard let dto = response.data else { throw ProfileError.unknown }
        let sections = (dto.sections ?? []).enumerated().compactMap { index, section -> LegalDocument.Section? in
            guard let body = section.body?.nonEmpty else { return nil }
            return LegalDocument.Section(id: index, heading: section.heading ?? "", body: body)
        }
        return LegalDocument(kind: kind,
                             title: dto.title?.nonEmpty ?? kind.title,
                             version: dto.version ?? "",
                             summary: dto.summary?.nonEmpty,
                             effectiveDate: dto.effectiveAt.flatMap({ dayFormatter.date(from: $0) }),
                             sections: sections)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Jakarta")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Error

    static func toDomainError(_ error: Error) -> ProfileError {
        switch error {
        case let error as ProfileError:
            return error
        case let server as APIServerError:
            return domainError(from: server)
        case APIManager.APIError.invalidStatusCode(let status):
            return domainError(from: APIServerError(statusCode: status))
        case is URLError:
            return .network
        default:
            return .unknown
        }
    }

    private static func domainError(from server: APIServerError) -> ProfileError {
        let message = server.message?.nonEmpty
        switch server.statusCode {
        case 400:
            return .validation(message: message ?? "Periksa lagi data yang kamu isi.", fields: server.fieldErrors)
        case 401: return .sessionExpired
        case 404: return .notFound
        case 409: return .conflict(message ?? "Data sudah ada.")
        case 422: return .rejected(message ?? "Permintaan tidak bisa diproses.")
        default: return .unknown
        }
    }
}

extension String {
    /// `nil` bila kosong setelah di-trim.
    var nonEmpty: String? {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }
}
