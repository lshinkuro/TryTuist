//
//  OnboardingStore.swift
//  AuthenticationFeature · Presentation
//
import Foundation
import Utility

struct OnboardingItem: Equatable {
    let imageURL: URL?
    let title: String
    let subtitle: String
}

extension OnboardingItem {
    private static func unsplash(_ id: String) -> URL? {
        URL(string: "https://images.unsplash.com/photo-\(id)?w=800&q=80&auto=format&fit=crop")
    }

    static let defaults: [OnboardingItem] = [
        .init(imageURL: unsplash("1542838132-92c53300491e"),
              title: String(localized: "Semua kebutuhan di satu tempat"),
              subtitle: String(localized: "Sembako, sayur, daging, sampai sabun. Tinggal pilih.")),
        .init(imageURL: unsplash("1604719312566-8912e9227c6a"),
              title: String(localized: "Belanja cepat tanpa antre"),
              subtitle: String(localized: "Atur varian, jumlah, dan catatan sesuai kebutuhanmu.")),
        .init(imageURL: unsplash("1540420773420-3366772f4999"),
              title: String(localized: "Diantar segar ke rumah"),
              subtitle: String(localized: "Nikmati promo dan gratis ongkir setiap minggu."))
    ]
}

struct OnboardingState: Equatable {
    let items: [OnboardingItem]
    var currentPage = 0

    var isLastPage: Bool { currentPage >= items.count - 1 }
    var primaryButtonTitle: String { isLastPage ? String(localized: "Mulai Sekarang") : String(localized: "Lanjut") }
}

enum OnboardingAction {
    case pageChanged(Int)
    case nextTapped
    case skipTapped
}

enum OnboardingRoute {
    case finished
}

final class OnboardingStore: Store<OnboardingState, OnboardingAction> {
    private let completeOnboarding: CompleteOnboardingUseCase
    var onRoute: ((OnboardingRoute) -> Void)?

    init(items: [OnboardingItem] = OnboardingItem.defaults,
         completeOnboarding: CompleteOnboardingUseCase = CompleteOnboardingUseCase()) {
        self.completeOnboarding = completeOnboarding
        super.init(initialState: OnboardingState(items: items))
    }

    override func reduce(state: inout OnboardingState, action: OnboardingAction) -> Effect<OnboardingAction>? {
        switch action {
        case .pageChanged(let page):
            state.currentPage = min(max(page, 0), state.items.count - 1)
            return nil

        case .nextTapped:
            guard state.isLastPage else {
                state.currentPage += 1
                return nil
            }
            return finish()

        case .skipTapped:
            return finish()
        }
    }

    private func finish() -> Effect<OnboardingAction> {
        let completeOnboarding = self.completeOnboarding
        return .run { [weak self] in
            completeOnboarding.execute()
            self?.onRoute?(.finished)
        }
    }
}
