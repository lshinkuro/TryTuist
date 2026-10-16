//
//  PageIndicator.swift
//  TTUI
//
//  Pengganti `UIPageControl` untuk carousel SwiftUI.
//
import SwiftUI

public struct PageIndicator: View {
    private let numberOfPages: Int
    private let currentPage: Int
    private let pageColor: Color
    private let currentPageColor: Color

    public init(numberOfPages: Int,
                currentPage: Int,
                pageColor: Color = .white.opacity(0.5),
                currentPageColor: Color = .white) {
        self.numberOfPages = numberOfPages
        self.currentPage = currentPage
        self.pageColor = pageColor
        self.currentPageColor = currentPageColor
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? currentPageColor : pageColor)
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(currentPage + 1) of \(numberOfPages)")
    }
}
