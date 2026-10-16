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
}
