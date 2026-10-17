//
//  PageIndicator.swift
//  TTUI
//
//  Indikator halaman: halaman aktif berbentuk kapsul yang lebih panjang.
//
import SwiftUI

public struct PageIndicator: View {
    private let numberOfPages: Int
    private let currentPage: Int
    private let pageColor: Color
    private let currentPageColor: Color

    public init(numberOfPages: Int,
                currentPage: Int,
                pageColor: Color = Color.secondary.opacity(0.3),
                currentPageColor: Color = .brand) {
        self.numberOfPages = numberOfPages
        self.currentPage = currentPage
        self.pageColor = pageColor
        self.currentPageColor = currentPageColor
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? currentPageColor : pageColor)
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
            }
        }
        .animation(.snappy, value: currentPage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Halaman \(currentPage + 1) dari \(numberOfPages)")
    }
}
