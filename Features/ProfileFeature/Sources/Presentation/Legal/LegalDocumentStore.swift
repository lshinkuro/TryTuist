//
//  LegalDocumentStore.swift
//  ProfileFeature · Presentation
//
//  Kebijakan Privasi / Syarat & Ketentuan dari GET /v1/legal/{slug}.
//
import Foundation
import Utility

struct LegalDocumentState: Equatable {
    let kind: LegalDocumentKind
    var document: Loadable<LegalDocument> = .idle
}

enum LegalDocumentAction {
    case onAppear
    case retryTapped
    case response(Result<LegalDocument, ProfileError>)
}

final class LegalDocumentStore: Store<LegalDocumentState, LegalDocumentAction> {
    private let repository: SupportRepository

    init(kind: LegalDocumentKind, repository: SupportRepository) {
        self.repository = repository
        super.init(initialState: LegalDocumentState(kind: kind))
    }

    override func reduce(state: inout LegalDocumentState, action: LegalDocumentAction) -> Effect<LegalDocumentAction>? {
        switch action {
        case .onAppear:
            guard state.document.isIdle else { return nil }
            state.document = .loading
            return fetch(state.kind)

        case .retryTapped:
            state.document = .loading
            return fetch(state.kind)

        case .response(.success(let document)):
            state.document = .loaded(document)
            return nil

        case .response(.failure(let error)):
            state.document = .failed(error.message)
            return nil
        }
    }

    private func fetch(_ kind: LegalDocumentKind) -> Effect<LegalDocumentAction> {
        let repository = self.repository
        return .task {
            do {
                return .response(.success(try await repository.legalDocument(kind)))
            } catch {
                return .response(.failure(error as? ProfileError ?? .unknown))
            }
        }
    }
}
