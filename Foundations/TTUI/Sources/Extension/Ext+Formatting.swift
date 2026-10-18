//
//  Ext+Formatting.swift
//  TTUI
//
//  Format tampilan untuk nilai dari Entity (dipakai di layer Presentation).
//
import Foundation

private let indonesianLocale = Locale(identifier: "id_ID")

/// Bahasa app yang aktif (iOS Settings → TryTuist → Bahasa). Rupiah tetap format Indonesia.
public let appLocale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "id")

public extension Decimal {
    /// 15000 → "Rp 15.000"
    var rupiahFormatted: String {
        formatted(.currency(code: "IDR").locale(indonesianLocale).precision(.fractionLength(0)))
    }
}

public extension Date {
    /// "20 Agu 2024, 12.46"
    var shortDateTimeFormatted: String {
        formatted(.dateTime.day().month(.abbreviated).year().hour().minute().locale(appLocale))
    }
}
