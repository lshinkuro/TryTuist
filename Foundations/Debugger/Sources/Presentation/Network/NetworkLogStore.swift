//
//  NetworkLogStore.swift
//  Debugger · Presentation
//
//  Daftar API yang di-hit (terbaru di atas), dengan pencarian & filter.
//
import Foundation
import NetworkManager
import Utility

enum NetworkFilter: String, CaseIterable, Identifiable {
    case all = "Semua"
    case failed = "Gagal"
    case pending = "Proses"

    var id: String { rawValue }
}

struct NetworkLogState: Equatable {
    var entries: [NetworkEntry] = []
    var searchText = ""
    var filter: NetworkFilter = .all

    var visibleEntries: [NetworkEntry] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return entries.filter { entry in
            switch filter {
            case .all: break
            case .failed: guard entry.phase == .failure else { return false }
            case .pending: guard entry.phase == .pending else { return false }
            }
            guard !query.isEmpty else { return true }
            return entry.url.lowercased().contains(query)
                || entry.method.lowercased().contains(query)
                || entry.statusCode.map { String($0).contains(query) } == true
        }
    }

    var failedCount: Int { entries.filter { $0.phase == .failure }.count }
}

enum NetworkLogAction {
    case entriesUpdated([NetworkEntry])
    case searchChanged(String)
    case filterChanged(NetworkFilter)
    case clearTapped
    case deleteTapped(String)
}

final class NetworkLogStore: Store<NetworkLogState, NetworkLogAction> {
    private let inspector: NetworkInspector

    init(inspector: NetworkInspector) {
        self.inspector = inspector
        super.init(initialState: NetworkLogState(entries: inspector.entries))
        bind(inspector.$entries) { .entriesUpdated($0) }
    }

    func makeDetailStore(for entryID: String) -> NetworkDetailStore {
        NetworkDetailStore(entryID: entryID, inspector: inspector)
    }

    override func reduce(state: inout NetworkLogState, action: NetworkLogAction) -> Effect<NetworkLogAction>? {
        switch action {
        case .entriesUpdated(let entries):
            state.entries = entries
            return nil

        case .searchChanged(let text):
            state.searchText = text
            return nil

        case .filterChanged(let filter):
            state.filter = filter
            return nil

        case .clearTapped:
            // Langsung kosong di UI; inspector menyusul lewat `entriesUpdated`.
            state.entries = []
            state.searchText = ""
            let inspector = self.inspector
            return .run { inspector.clear() }

        case .deleteTapped(let id):
            state.entries.removeAll { $0.id == id }
            let inspector = self.inspector
            return .run { inspector.remove(id: id) }
        }
    }
}
