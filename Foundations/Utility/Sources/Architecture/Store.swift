//
//  Store.swift
//  Utility
//
//  Inti Unidirectional Data Flow (UDF):
//
//      View ──send(Action)──▶ Store.reduce(state, action) ──▶ State baru ──▶ View render ulang
//                                       │
//                                       └──▶ Effect (async: repository/use case) ──▶ Action berikutnya
//
//  Aturan:
//  - State hanya berubah di dalam `reduce`.
//  - `reduce` sinkron & tanpa side effect; kerja async dikembalikan sebagai `Effect`.
//  - View hanya membaca `state` dan memanggil `send(_:)`.
//
import Combine
import SwiftUI

@MainActor
open class Store<State, Action>: ObservableObject {
    @Published public private(set) var state: State
    private var subscriptions = Set<AnyCancellable>()

    public init(initialState: State) {
        self.state = initialState
    }

    /// Satu-satunya pintu masuk perubahan state.
    public final func send(_ action: Action) {
        var newState = state
        let effect = reduce(state: &newState, action: action)
        state = newState

        guard let effect else { return }
        Task { [weak self] in
            guard let next = await effect.operation() else { return }
            self?.send(next)
        }
    }

    /// Override di subclass: ubah `state` sesuai `action`, kembalikan `Effect` bila perlu kerja async.
    open func reduce(state: inout State, action: Action) -> Effect<Action>? {
        nil
    }

    /// Berlangganan state bersama (mis. keranjang) dari repository.
    /// Setiap nilai baru diubah jadi Action, jadi tetap lewat `reduce`.
    public func bind<P: Publisher>(_ publisher: P, to action: @escaping (P.Output) -> Action) where P.Failure == Never {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                MainActor.assumeIsolated { self?.send(action(value)) }
            }
            .store(in: &subscriptions)
    }

    /// Binding dua arah untuk TextField/Toggle: membaca dari state, menulis lewat action.
    public func binding<Value>(_ keyPath: KeyPath<State, Value>,
                               send action: @escaping (Value) -> Action) -> Binding<Value> {
        Binding(
            get: { MainActor.assumeIsolated { self.state[keyPath: keyPath] } },
            set: { newValue in MainActor.assumeIsolated { self.send(action(newValue)) } }
        )
    }
}

/// Side effect yang dihasilkan reducer.
public struct Effect<Action> {
    let operation: () async -> Action?

    /// Kerja async (network, database). Kembalikan Action hasilnya, atau `nil`.
    public static func task(_ operation: @escaping () async -> Action?) -> Effect {
        Effect(operation: operation)
    }

    /// Kerja di main thread tanpa hasil, mis. navigasi atau analytics.
    public static func run(_ work: @escaping @MainActor () -> Void) -> Effect {
        Effect {
            await work()
            return nil
        }
    }
}
