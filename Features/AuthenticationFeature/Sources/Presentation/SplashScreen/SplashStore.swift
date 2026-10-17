//
//  SplashStore.swift
//  AuthenticationFeature · Presentation
//
import Foundation
import Utility

struct SplashState: Equatable {
    let title: String
    var hasAppeared = false
    static let duration: Double = 2
}

enum SplashAction {
    case onAppear
    case timerFinished
}

final class SplashStore: Store<SplashState, SplashAction> {
    private let getDestination: GetLaunchDestinationUseCase
    var onRoute: ((LaunchDestination) -> Void)?

    init(title: String, getDestination: GetLaunchDestinationUseCase = GetLaunchDestinationUseCase()) {
        self.getDestination = getDestination
        super.init(initialState: SplashState(title: title))
    }

    override func reduce(state: inout SplashState, action: SplashAction) -> Effect<SplashAction>? {
        switch action {
        case .onAppear:
            guard !state.hasAppeared else { return nil }
            state.hasAppeared = true
            return .task {
                try? await Task.sleep(for: .seconds(SplashState.duration))
                return .timerFinished
            }

        case .timerFinished:
            // Membaca sesi = side effect → dilakukan di Effect, bukan langsung di reducer.
            let getDestination = self.getDestination
            return .run { [weak self] in self?.onRoute?(getDestination.execute()) }
        }
    }
}
