//
//  MenuSectionView.swift
//  HomeFeature
//
import SwiftUI
import TTUI

/// Card menu: baris item menu + baris tile horizontal.
struct MenuSectionView: View {
    private let menuCount = 4

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ForEach(0..<menuCount, id: \.self) { _ in
                    MenuItemView(title: "Only 9k", imageName: "text", showsNewBadge: true)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)

            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<menuCount, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray)
                                .frame(width: (proxy.size.width - 30) / CGFloat(menuCount), height: 80)
                        }
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .formCard()
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct MenuItemView: View {
    let title: String
    let imageName: String
    let showsNewBadge: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .overlay(alignment: .topTrailing) {
                    if showsNewBadge {
                        Text("NEW")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(red: 0.89, green: 0.62, blue: 0.36))
                            .offset(x: 8, y: -4)
                    }
                }
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.black)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
