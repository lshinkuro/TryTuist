//
//  NetworkDetailStore.swift
//  Debugger · Presentation
//
//  Detail satu request. Ikut ter-update bila response datang saat screen terbuka.
//
import Foundation
import NetworkManager
import TTUI
import Utility

enum NetworkDetailSection: String, CaseIterable, Identifiable {
    case request = "Request"
    case response = "Response"

    var id: String { rawValue }
}

struct NetworkDetailState: Equatable {
    var entry: NetworkEntry?
    var section: NetworkDetailSection = .response
    var toast: ToastMessage?
}

enum NetworkDetailAction {
    case entriesUpdated([NetworkEntry])
    case sectionChanged(NetworkDetailSection)
    case copyTapped(label: String, text: String)
    case toastDismissed(UUID)
}

final class NetworkDetailStore: Store<NetworkDetailState, NetworkDetailAction> {
    private let entryID: String

    init(entryID: String, inspector: NetworkInspector) {
        self.entryID = entryID
        let entry = inspector.entries.first { $0.id == entryID }
        super.init(initialState: NetworkDetailState(entry: entry,
                                                    section: entry?.phase == .pending ? .request : .response))
        bind(inspector.$entries) { .entriesUpdated($0) }
    }

    override func reduce(state: inout NetworkDetailState, action: NetworkDetailAction) -> Effect<NetworkDetailAction>? {
        switch action {
        case .entriesUpdated(let entries):
            // Log dibersihkan → tetap tampilkan data terakhir.
            if let latest = entries.first(where: { $0.id == entryID }) {
                state.entry = latest
            }
            return nil

        case .sectionChanged(let section):
            state.section = section
            return nil

        case .copyTapped(let label, let text):
            let toast = ToastMessage("\(label) disalin", systemImage: "doc.on.doc.fill")
            state.toast = toast
            return copyEffect(text, toastID: toast.id) { .toastDismissed($0) }

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }
}
