//
//  IntentActionCenter.swift
//  TryTuist
//
//  Aksi dari Siri / Shortcuts / Visual Intelligence. Ditahan sampai tab utama siap,
//  mis. app baru dibuka dan user masih harus login dulu.
//
import Foundation

@MainActor
final class IntentActionCenter {
    enum Action {
        case addToCart(productID: String, name: String, quantity: Int)
        case openProduct(id: String)
    }

    static let shared = IntentActionCenter()
    private var handler: ((Action) -> Void)?
    private var pending: Action?

    /// - Returns: `true` bila langsung dijalankan; `false` bila ditahan sampai tab utama tampil.
    @discardableResult
    func send(_ action: Action) -> Bool {
        guard let handler else {
            pending = action
            return false
        }
        handler(action)
        return true
    }

    /// Dipanggil AppRouter setelah tab utama tampil; aksi yang tertahan langsung dijalankan.
    func attach(_ handler: @escaping (Action) -> Void) {
        self.handler = handler
        if let pending {
            self.pending = nil
            handler(pending)
        }
    }

    func detach() {
        handler = nil
    }
}
