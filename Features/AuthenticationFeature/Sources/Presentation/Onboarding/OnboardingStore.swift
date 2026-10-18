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
        .init(imageURL: unsplash("1512058564366-18510be2db19"),
              title: String(localized: "Semua favoritmu di sini"),
              subtitle: String(localized: "Kopi, nasi goreng, burger, sampai dessert. Tinggal pilih.")),
        .init(imageURL: unsplash("1767471716700-2b3aa77b1ab6"),
              title: String(localized: "Pesan cepat tanpa antre"),
              subtitle: String(localized: "Atur varian, jumlah, dan catatan sesuai seleramu.")),
        .init(imageURL: unsplash("1543339469-94ba2391431f"),
              title: String(localized: "Diantar hangat ke rumah"),
              subtitle: String(localized: "Nikmati promo dan gratis ongkir setiap hari."))
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
