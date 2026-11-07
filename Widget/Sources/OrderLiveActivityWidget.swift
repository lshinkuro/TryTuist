//
//  OrderLiveActivityWidget.swift
//  TryTuistWidget
//
//  Live Activity status pesanan: Lock Screen & Dynamic Island. Isinya dikirim app
//  (`OrderLiveActivity` di Utility); judul status sudah diterjemahkan app.
//
import ActivityKit
import SwiftUI
import WidgetKit

@main
struct TryTuistWidgetBundle: WidgetBundle {
    var body: some Widget {
        BestSellerWidget()
        OrderLiveActivityWidget()
    }
}

struct OrderLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderActivityAttributes.self) { context in
            OrderLockScreenView(attributes: context.attributes, state: context.state)
                .padding()
                .activityBackgroundTint(Color(.systemBackground).opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: OrderStep.icon(context.state.step))
                        .font(.title2)
                        .foregroundStyle(Color.brand)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let end = context.state.arrivalEnd {
                        Text(end, style: .time).font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.title).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    OrderStepsView(step: context.state.step)
                }
            } compactLeading: {
                Image(systemName: OrderStep.icon(context.state.step)).foregroundStyle(Color.brand)
            } compactTrailing: {
                if let end = context.state.arrivalEnd {
                    Text(end, style: .time).font(.caption2)
                } else {
                    Text("\(context.state.step + 1)/4").font(.caption2)
                }
            } minimal: {
                Image(systemName: OrderStep.icon(context.state.step)).foregroundStyle(Color.brand)
            }
        }
    }
}

private enum OrderStep {
    static func icon(_ step: Int) -> String {
        switch step {
        case 1: return "frying.pan.fill"
        case 2: return "scooter"
        case 3: return "checkmark.circle.fill"
        default: return "bag.fill"
        }
    }
}

private struct OrderLockScreenView: View {
    let attributes: OrderActivityAttributes
    let state: OrderActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: OrderStep.icon(state.step))
                    .font(.title3)
                    .foregroundStyle(Color.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title).font(.headline)
                    Text([attributes.storeName, "#\(attributes.orderNumber)"].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let end = state.arrivalEnd {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "clock").font(.caption).foregroundStyle(.secondary)
                        Text(end, style: .time).font(.headline)
                    }
                }
            }
            OrderStepsView(step: state.step)
        }
    }
}

/// Diterima → Diproses → Diantar → Selesai.
private struct OrderStepsView: View {
    let step: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.brand : Color.secondary.opacity(0.25))
                    .frame(height: 6)
            }
        }
        .accessibilityLabel("Langkah \(step + 1) dari 4")
    }
}
