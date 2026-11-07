//
//  Font+Theme.swift
//  TTUI
//
import SwiftUI

/// Versi SwiftUI dari font OpenSans di `Ext+Font.swift`.
public extension Font {
    static func omoRegular(_ size: CGFloat) -> Font { .custom("OpenSans-Regular", size: size) }
    static func omoSemiBold(_ size: CGFloat) -> Font { .custom("OpenSans-SemiBold", size: size) }
    static func omoBold(_ size: CGFloat) -> Font { .custom("OpenSans-Bold", size: size) }
    static func omoExtraBold(_ size: CGFloat) -> Font { .custom("OpenSans-ExtraBold", size: size) }
    static func omoLight(_ size: CGFloat) -> Font { .custom("OpenSans-Light", size: size) }
    static func omoItalic(_ size: CGFloat) -> Font { .custom("OpenSans-Italic", size: size) }

    // MARK: Skala teks (sama dengan text style di Figma); `relativeTo` menjaga Dynamic Type.
    static let appLargeTitle = Font.custom("OpenSans-Bold", size: 30, relativeTo: .largeTitle)
    static let appTitle = Font.custom("OpenSans-Bold", size: 22, relativeTo: .title2)
    static let appTitle3 = Font.custom("OpenSans-Bold", size: 20, relativeTo: .title3)
    static let appHeadline = Font.custom("OpenSans-SemiBold", size: 17, relativeTo: .headline)
    static let appBody = Font.custom("OpenSans-Regular", size: 15, relativeTo: .body)
    static let appSubhead = Font.custom("OpenSans-Regular", size: 14, relativeTo: .subheadline)
    static let appSubheadStrong = Font.custom("OpenSans-SemiBold", size: 14, relativeTo: .subheadline)
    static let appCaption = Font.custom("OpenSans-Regular", size: 12, relativeTo: .caption)
    static let appCaptionStrong = Font.custom("OpenSans-SemiBold", size: 12, relativeTo: .caption)
    static let appMicro = Font.custom("OpenSans-Bold", size: 11, relativeTo: .caption2)
}
