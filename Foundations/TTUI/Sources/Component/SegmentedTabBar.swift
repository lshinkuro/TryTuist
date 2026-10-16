//
//  SegmentedTabBar.swift
//  TTUI
//
//  Pengganti `CustomTabBar` (UIKit): tab segmen dengan indikator yang beranimasi.
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
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(title)
                            .font(.omoBold(16))
                            .foregroundStyle(index == selectedIndex ? .white : .gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background {
                                if index == selectedIndex {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.blue)
                                        .frame(height: proxy.size.height * 0.8)
                                        .matchedGeometryEffect(id: "selector", in: selectorNamespace)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
                }
            }
        }
    }
}
