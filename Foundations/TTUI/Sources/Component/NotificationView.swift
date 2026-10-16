//
//  NotificationView.swift
//  TTUI
//
//  Created by Phincon on 29/08/24.
//
import SwiftUI

public enum NotificationType {
    case success
    case error
    case neutral
}

/// Banner notifikasi custom (versi SwiftUI).
public struct NotificationView: View {
    private let type: NotificationType
    private let title: String
    private let message: String

    public init(type: NotificationType, title: String, message: String) {
        self.type = type
        self.title = title
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.omoBold(16))
                    .foregroundStyle(titleColor)
                Text(message)
                    .font(.omoSemiBold(14))
                    .foregroundStyle(Color(.lightGray))
                if type == .neutral {
                    HStack(spacing: 5) {
                        Image("text")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .accessibilityHidden(true)
                        Text("+ 500")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.foodBrightCoral4)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(type == .neutral ? Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.5) : .clear)
    }

    private var iconName: String {
        switch type {
        case .success: return "bell"
        case .error: return "notification"
        case .neutral: return "text"
        }
    }

    private var titleColor: Color {
        switch type {
        case .success: return .foodBlack80
        case .error: return .red
        case .neutral: return .white
        }
    }
}
