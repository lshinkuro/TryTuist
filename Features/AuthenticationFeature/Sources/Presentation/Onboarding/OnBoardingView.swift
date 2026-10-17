//
//  OnBoardingView.swift
//  AuthenticationFeature · Presentation
//
import SwiftUI
import TTUI

struct OnBoardingView: View {
    @StateObject private var store: OnboardingStore

    init(store: OnboardingStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: OnboardingState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Lewati") { store.send(.skipTapped) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .opacity(state.isLastPage ? 0 : 1)
                    .disabled(state.isLastPage)
            }
            .padding(.horizontal, 24)
            .frame(height: 44)

            TabView(selection: store.binding(\.currentPage, send: { .pageChanged($0) })) {
                ForEach(Array(state.items.enumerated()), id: \.offset) { index, item in
                    OnBoardingPageView(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: state.currentPage)

            VStack(spacing: 24) {
                PageIndicator(numberOfPages: state.items.count, currentPage: state.currentPage)
                PrimaryButton(state.primaryButtonTitle) { store.send(.nextTapped) }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}

private struct OnBoardingPageView: View {
    let item: OnboardingItem

    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer(minLength: 0)

            Color.clear
                .frame(width: 260, height: 260)
                .overlay { RemoteImage(url: item.imageURL) }
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.brandSoft, lineWidth: 12))
                .shadow(color: Color.brand.opacity(0.2), radius: 24, y: 12)

            Text(item.title)
                .font(.title.bold())
                .padding(.top, Spacing.xxl)

            Text(item.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
    }
}
