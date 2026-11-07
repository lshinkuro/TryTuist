//
//  Color+Theme.swift
//  TTUI
//
import SwiftUI
import UIKit

public extension UIColor {
    /// Warna utama aplikasi F&B: oranye hangat (#D9480F). Kontras cukup untuk teks putih.
    static let brand = UIColor(red: 0.851, green: 0.282, blue: 0.059, alpha: 1)
}

public extension Color {
    // MARK: Semantic — otomatis menyesuaikan light / dark mode.
    static let brand = Color(uiColor: .brand)
    static let brandSoft = Color(uiColor: .brand).opacity(0.12)
    /// Background screen.
    static let appBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.systemGroupedBackground.resolvedColor(with: trait)
            : UIColor(red: 0.980, green: 0.965, blue: 0.941, alpha: 1)
    })
    /// Background card di atas `appBackground`.
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    /// Garis tepi card.
    static let cardLine = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.separator.resolvedColor(with: trait)
            : UIColor(red: 0.922, green: 0.886, blue: 0.843, alpha: 1)
    })
    /// Cokelat gelap untuk elemen kecil di atas warna brand.
    static let brandDark = Color(red: 0.165, green: 0.09, blue: 0.063)
    /// Background text field.
    static let fieldBackground = Color(uiColor: .tertiarySystemFill)

    // MARK: Palet lama (dipertahankan untuk kompatibilitas).
    static let foodBrightBlue = Color(uiColor: .foodBrightBlue)
    static let foodBrightCoral1 = Color(uiColor: .foodBrightCoral1)
    static let foodBrightCoral4 = Color(uiColor: .foodBrightCoral4)
    static let foodBlack80 = Color(uiColor: .foodBlack80)
    static let foodWhite100 = Color(uiColor: .foodWhite100)
    static let foodGrey3 = Color(uiColor: .foodGrey3)
    static let appDarkBackground = Color(red: 0.0706, green: 0.0706, blue: 0.0706)
}

/// Skala jarak & radius yang dipakai semua screen.
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 28
}

public enum Radius {
    public static let control: CGFloat = 14
    public static let card: CGFloat = 20
}
