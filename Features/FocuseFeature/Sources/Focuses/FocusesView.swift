//
//  FocusesView.swift
//  FocuseFeature
//
import SwiftUI
import TTUI

struct FocusesView: View {
    private let tabTitles = ["Recent", "Pending", "Completed", "Failed"]
    @State private var selectedTab = 0

    private var displayedOrders: [Order] {
        selectedTab == 0 ? orders : vouchers
    }

    var body: some View {
        VStack(spacing: 16) {
            SegmentedTabBar(titles: tabTitles, selectedIndex: $selectedTab)
                .frame(height: 40)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(displayedOrders.enumerated()), id: \.offset) { _, order in
                        OrderRowView(order: order)
                    }
                }
            }
        }
        .background(Color.white)
    }
}

struct OrderRowView: View {
    let order: Order

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 50, height: 50)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(order.productName)
                Text(order.store)
                Text(order.date)
                    .font(.omoBold(20))
                Text(order.price)
                Text(order.itemCount)
            }
            .foregroundStyle(.black)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 8) {
                OutlineButton(title: "Rate +2", color: .orange)
                OutlineButton(title: "Reorder", color: .black)
            }
            .padding(16)
        }
        .formCard()
        .padding(16)
    }
}

private struct OutlineButton: View {
    let title: String
    let color: Color

    var body: some View {
        Button(title) {}
            .foregroundStyle(color)
            .frame(width: 80, height: 40)
            .overlay(Capsule().stroke(color, lineWidth: 1))
    }
}
