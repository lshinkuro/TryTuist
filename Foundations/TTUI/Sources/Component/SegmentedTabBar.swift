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
        HStack(spacing: Spacing.xs) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                let isSelected = index == selectedIndex
                Button {
                    withAnimation(.snappy) { selectedIndex = index }
                } label: {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
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
        .padding(Spacing.xs)
        .background(Color.cardBackground, in: Capsule())
    }
}
