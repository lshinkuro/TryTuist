//
//  SegmentedTabBar.swift
//  TTUI
//
//  Tab segmen berbentuk kapsul dengan indikator yang beranimasi.
//
import SwiftUI

public struct SegmentedTabBar: View {
    private let titles: [String]
    @Binding private var selectedIndex: Int
    @Namespace private var selectorNamespace

    public init(titles: [String], selectedIndex: Binding<Int>) {
        self.titles = titles
        self._selectedIndex = selectedIndex
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                let isSelected = index == selectedIndex
                Button {
                    withAnimation(.snappy) { selectedIndex = index }
                } label: {
                    Text(title)
                        .font(.appCaptionStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            Capsule()
                                .fill(Color.cardBackground)
                                .overlay(Capsule().strokeBorder(Color.cardLine))
                            if isSelected {
                                Capsule()
                                    .fill(Color.brand)
                                    .matchedGeometryEffect(id: "selector", in: selectorNamespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
