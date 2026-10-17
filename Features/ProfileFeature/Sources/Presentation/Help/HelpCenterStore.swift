//
//  HelpCenterStore.swift
//  ProfileFeature · Presentation
//
//  Pusat Bantuan: FAQ per topik, pencarian (GET /v1/help?q=), dan kontak CS.
//
import Foundation
import Utility

struct HelpCenterState: Equatable {
    var content: Loadable<HelpCenter> = .idle
    var query = ""
    /// Query yang sedang/sudah dicari ke server (setelah debounce).
    var searchedQuery = ""
    var isSearching = false
    var expandedArticleIDs: Set<String> = []

    var trimmedQuery: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isFiltering: Bool { !searchedQuery.isEmpty }
}

enum HelpCenterAction {
    case onAppear
    case retryTapped
    case queryChanged(String)
    case searchFired(String)
    case response(query: String, Result<HelpCenter, ProfileError>)
    case articleToggled(String)
    case contactTapped(HelpContact)
}

enum HelpCenterRoute {
    case open(URL)
}

final class HelpCenterStore: Store<HelpCenterState, HelpCenterAction> {
    private let repository: SupportRepository
    var onRoute: ((HelpCenterRoute) -> Void)?

    static let searchDelay: Duration = .milliseconds(350)
    static let maxQueryLength = 100

    init(repository: SupportRepository) {
        self.repository = repository
        super.init(initialState: HelpCenterState())
    }

    override func reduce(state: inout HelpCenterState, action: HelpCenterAction) -> Effect<HelpCenterAction>? {
        switch action {
        case .onAppear:
            guard state.content.isIdle else { return nil }
            state.content = .loading
            return fetch(query: "")

        case .retryTapped:
            state.content = .loading
            return fetch(query: state.searchedQuery)

        case .queryChanged(let text):
            state.query = String(text.prefix(Self.maxQueryLength))
            let query = state.trimmedQuery
            guard query != state.searchedQuery else { return nil }
            // Debounce: hanya cari bila user berhenti mengetik sebentar.
            let delay = Self.searchDelay
            return .task {
                try? await Task.sleep(for: delay)
                return .searchFired(query)
            }

        case .searchFired(let query):
            // Sudah ada ketikan baru → abaikan pencarian lama.
            guard query == state.trimmedQuery, query != state.searchedQuery else { return nil }
            state.searchedQuery = query
            state.isSearching = true
            return fetch(query: query)

        case .response(let query, let result):
            // Response untuk query lama (user sudah mengetik lagi) dibuang.
            guard query == state.searchedQuery else { return nil }
            state.isSearching = false
            switch result {
            case .success(let content):
                state.content = .loaded(content)
                // Saat mencari, buka semua jawaban supaya hasil langsung terbaca.
                state.expandedArticleIDs = query.isEmpty
                    ? []
                    : Set(content.topics.flatMap { $0.articles.map(\.id) })
            case .failure(let error):
                state.content = .failed(error.message)
            }
            return nil

        case .articleToggled(let id):
            if state.expandedArticleIDs.contains(id) {
                state.expandedArticleIDs.remove(id)
            } else {
                state.expandedArticleIDs.insert(id)
            }
            return nil

        case .contactTapped(let contact):
            return .run { [weak self] in self?.onRoute?(.open(contact.url)) }
        }
    }

    private func fetch(query: String) -> Effect<HelpCenterAction> {
        let repository = self.repository
        return .task {
            do {
                return .response(query: query, .success(try await repository.helpCenter(query: query.isEmpty ? nil : query)))
            } catch {
                return .response(query: query, .failure(error as? ProfileError ?? .unknown))
            }
        }
    }
}
