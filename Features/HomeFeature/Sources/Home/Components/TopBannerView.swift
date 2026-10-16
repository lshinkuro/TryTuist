//
//  TopBannerView.swift
//  HomeFeature
//
import SwiftUI
import TTUI

/// Carousel banner + header sapaan yang menumpuk di bagian bawah.
struct TopBannerView: View {
    let items: [TopBannerItem]
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    TabView(selection: $currentPage) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            Image(item.bgImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .tag(index)
                                .accessibilityLabel(item.title)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    PageIndicator(numberOfPages: items.count, currentPage: currentPage)
                        .frame(height: 20)
                        .padding(.trailing, 16)
                        .padding(.bottom, 20)
                }
                .frame(height: 400)

                Spacer().frame(height: 40)
            }

            HomeHeaderView()
                .frame(height: 60)
                .padding(.horizontal, 16)
        }
    }
}

struct HomeHeaderView: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Hi, Ishinkuro")
                .font(.system(size: 18, weight: .medium))
            Spacer(minLength: 16)
            Image(systemName: "ticket")
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
            Text("1")
                .font(.system(size: 16))
                .accessibilityLabel("1 ticket")
            Image(systemName: "star.circle")
                .frame(width: 20, height: 20)
                .padding(.leading, 8)
                .accessibilityHidden(true)
            Text("104 pts")
                .font(.system(size: 16))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .formCard()
    }
}
