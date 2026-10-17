//
//  RemoteImage.swift
//  TTUI
//
//  Gambar dari URL (mis. Unsplash) dengan placeholder & fallback.
//  Pakai di dalam frame tetap:  Color.clear.frame(height: 160).overlay { RemoteImage(url: url) }.clipped()
//
import SwiftUI

public struct RemoteImage: View {
    private let url: URL?
    private let contentMode: ContentMode
    private let fallbackSymbol: String

    public init(url: URL?, contentMode: ContentMode = .fill, fallbackSymbol: String = "fork.knife") {
        self.url = url
        self.contentMode = contentMode
        self.fallbackSymbol = fallbackSymbol
    }

    public var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            case .failure:
                placeholder(showsIcon: true)
            default:
                placeholder(showsIcon: false)
                    .overlay { ProgressView().controlSize(.small) }
            }
        }
        .accessibilityHidden(true)
    }

    private func placeholder(showsIcon: Bool) -> some View {
        Rectangle()
            .fill(Color.brandSoft)
            .overlay {
                if showsIcon {
                    Image(systemName: fallbackSymbol)
                        .font(.title2)
                        .foregroundStyle(Color.brand.opacity(0.6))
                }
            }
    }
}
