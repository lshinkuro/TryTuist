//
//  HomeView.swift
//  HomeFeature
//
import SwiftUI
import TTUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                TopBannerView(items: viewModel.banners)
                MenuSectionView()
                ForEach(viewModel.users, id: \.objectID) { _ in
                    MenuAdsView(imageName: "bg-1")
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemBackground))
    }
}
