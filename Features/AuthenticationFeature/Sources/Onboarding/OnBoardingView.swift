//
//  OnBoardingView.swift
//  AuthenticationFeature
//
import SwiftUI
import TTUI

struct OnboardingItem: Equatable {
    let imageName: String
    let title: String
    let subtitle: String
    let bgImageName: String
}

struct OnBoardingView: View {
    let items: [OnboardingItem]
    let onNext: () -> Void
    let onSkip: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.appDarkBackground.ignoresSafeArea()

            // Background berganti (cross-dissolve) mengikuti halaman aktif.
            Image(items[currentPage].bgImageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.3)
                .id(currentPage)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button("Skip", action: onSkip)
                        .foregroundStyle(.white)
                        .frame(height: 34)
                }
                .padding(.horizontal, 16)

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        OnBoardingPageView(item: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 400)

                PageIndicator(numberOfPages: items.count,
                              currentPage: currentPage,
                              pageColor: .foodBrightCoral1,
                              currentPageColor: .gray)
                    .frame(height: 20)

                Spacer()

                PrimaryButton("NEXT", action: onNext)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }
        }
    }
}

private struct OnBoardingPageView: View {
    let item: OnboardingItem

    var body: some View {
        VStack(spacing: 0) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .padding(.top, 10)
                .accessibilityHidden(true)

            Text(item.title)
                .font(.system(size: 16, weight: .bold))
                .padding(.top, 20)

            Text(item.subtitle)
                .font(.system(size: 14))
                .padding(.top, 10)
                .padding(.horizontal, 40)

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
    }
}
