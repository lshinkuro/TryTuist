//
//  Ext+String.swift
//  TTUI
//
//  Created by Phincon on 24/08/24.
//

import Foundation
import UIKit
import Foundation
import Utility

public extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
    static func localized(_ string: String) -> String {
        return NSLocalizedString(string, comment: "")
    }
    
    func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }

    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    func isValidName() -> Bool {
        let regex = "^[a-zA-Z -]+$"
        let name = NSPredicate(format: "SELF MATCHES %@", regex)
        return name.evaluate(with: self)
    }

    func isValidAlphanum() -> Bool {
        let regex = "^[a-zA-Z0-9 -]+$"
        let alphaNum = NSPredicate(format: "SELF MATCHES %@", regex)
        return alphaNum.evaluate(with: self)
    }
    
    func notEmpty() -> Bool {
        return !isEmpty
    }
    
    func isDigits() -> Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    var htmlToAttributedString: NSAttributedString? {
        let modifiedFont = String(format: "<span style=\"font-family: 'Open Sans'; font-size: '12px'\">%@</span>", self)
        if let attrStr = try? NSAttributedString(
                    data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
                    options: [.documentType: NSAttributedString.DocumentType.html,
                              .characterEncoding: String.Encoding.utf8.rawValue],
                    documentAttributes: nil) {
            return attrStr
        }
        return nil
    }
    
    /// Convert nominal string to use currency format
    /// - Returns: return a string with currency format without IDR and decimal digits, e.g. `100,000`
    func convertToCurrency() -> String {
        guard let doubleValue = Double(self) else { return self }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "id_ID")
        formatter.currencyGroupingSeparator = ","
        formatter.currencySymbol = ""
        return formatter.string(from: NSNumber(value: doubleValue)) ?? self
    }
    
    /// Convert nominal string to use currency format with decimal
    /// - Returns: return a string with currency format with IDR and decimal digits, e.g. `IDR 10,000.00`
    func convertToCurrencyWithDecimal() -> String {
        guard let doubleValue = Double(self) else { return self }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_EN")
        formatter.currencyGroupingSeparator = ","
        formatter.currencyDecimalSeparator = "."
        formatter.currencySymbol = ""
        return formatter.string(from: NSNumber(value: doubleValue)) ?? self
    }
    
    /// Convert nominal string to use currency format without decimal and without rounding
    ///
    ///     "1.80".convertToCurrencyWithoutDecimal() -> "1"
    ///
    /// - Returns: string with currency format without decimal and without rounding
    func convertToCurrencyWithoutDecimal() -> String {
        let value = self.components(separatedBy: ".")
        return value.first?.convertToCurrency() ?? self.convertToCurrency()
    }

    /// Convert nominal string to use currency format with possibillity of >2 decimal point
    /// - Returns: return a string with currency format without IDR and decimal digits, e.g. `IDR 10,000.000`
    func convertToCurrencyWithManyDecimalPoint() -> String {
        let value = self.components(separatedBy: ".")
        if value.count == 2 {
            return "\(value[0].convertToCurrency()).\(value[1])"
        } else {
            return self
        }
    }
    
    func convertDateFormat(from currentFormat: String, to newFormat: String, isForceLocale: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = currentFormat
        if isForceLocale {
            dateFormatter.locale = Locale.current.language.languageCode?.identifier == Language.id.rawValue ?
            Locale(identifier: "id_ID") : Locale(identifier: "en_ID")
        }
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = newFormat
        return dateFormatter.string(from: date ?? Date())
    }

    func forceLocaleConvertDateFormat(from currentFormat: String, to newFormat: String, fromLocale: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = currentFormat
        dateFormatter.locale = Locale(identifier: fromLocale)
        let date = dateFormatter.date(from: self)
        if Locale.current.language.languageCode?.identifier == Language.id.rawValue {
            dateFormatter.locale = Locale(identifier: "id_ID")
        } else {
            dateFormatter.locale = Locale(identifier: "en_ID")
        }
        dateFormatter.dateFormat = newFormat
        return dateFormatter.string(from: date ?? Date())
    }
    
    func replace(myString: String, _ index: Int, _ newChar: Character) -> String {
        var chars = Array(myString)
        chars[index] = newChar
        let modifiedString = String(chars)
        return modifiedString
    }
    
    func dropSpaceLast() -> String {
        guard suffix(1).contains(" ") else { return self }
        return String(dropLast())
    }
    
    func containsIgnoringCase(_ anotherString: String) -> Bool {
        return self.range(of: anotherString, options: NSString.CompareOptions.caseInsensitive) != nil
    }
    
    var int: Int? {
        return Int(self)
    }
    
    var float: Float? {
        return Float(self)
    }
    
    var double: Double? {
        return Double(self)
    }
    
        /// SwifterSwift: Bool value from string (if applicable).
        ///
        ///        "1".bool -> true
        ///        "False".bool -> false
        ///        "Hello".bool = nil
        ///
    var bool: Bool? {
        let selfLowercased = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch selfLowercased {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            return nil
        }
    }
    
        /// SwifterSwift: Date object from "yyyy-MM-dd" formatted string.
        ///
        ///        "2007-06-29".date -> Optional(Date)
        ///
    var date: Date? {
        let selfLowercased = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: selfLowercased)
    }
    
        /// SwifterSwift: Date object from "yyyy-MM-dd HH:mm:ss" formatted string.
        ///
        ///        "2007-06-29 14:23:09".dateTime -> Optional(Date)
        ///
    var dateTime: Date {
        let selfLowercased = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: selfLowercased) ?? Date()
    }
    
    var dateTimeForceLocale: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale.current.language.languageCode?.identifier == Language.id.rawValue ?
        Locale(identifier: "id_ID") : Locale(identifier: "en_ID")
        return formatter.date(from: self) ?? Date()
    }
    
        /// SwifterSwift: Copy string to global pasteboard.
        ///
        ///        "SomeText".copyToPasteboard() // copies "SomeText" to pasteboard
        ///
    func copyToPasteboard() {
        UIPasteboard.general.string = self
    }
    
        /// SwifterSwift: Removes given prefix from the string.
        ///
        ///   "Hello, World!".removingPrefix("Hello, ") -> "World!"
        ///
        /// - Parameter prefix: Prefix to remove from the string.
        /// - Returns: The string after prefix removing.
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
    
        /// SwifterSwift: Removes given suffix from the string.
        ///
        ///   "Hello, World!".removingSuffix(", World!") -> "Hello"
        ///
        /// - Parameter suffix: Suffix to remove from the string.
        /// - Returns: The string after suffix removing.
    func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }
    
        /// SwifterSwift: Adds prefix to the string.
        ///
        ///     "www.apple.com".withPrefix("https://") -> "https://www.apple.com"
        ///
        /// - Parameter prefix: Prefix to add to the string.
        /// - Returns: The string with the prefix prepended.
    func withPrefix(_ prefix: String) -> String {
            // https://www.hackingwithswift.com/articles/141/8-useful-swift-extensions
        guard !hasPrefix(prefix) else { return self }
        return prefix + self
    }

    /// SwifterSwift: convert json string to json object.
    ///
    ///     "{\"Hello\":\"World\",\"dob\":\"01-01-1900\"}".toJSONObject() ->
    ///     {"Hello": "World", "dob": "01-01-1900"}
    ///
    func toJSONObject() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
    
    func toDecimalCurrencyOnType() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = ""
        formatter.locale = Locale(identifier: "en_EN")
        formatter.maximumFractionDigits = 2
        let plainNumber = self.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "").prefix(12)
        let double = (plainNumber as NSString).doubleValue
        let number = NSNumber(value: (double / 100))
        let result = formatter.string(for: number)
        return result ?? "0.00"
    }
    
    static func randomAlphanumeric(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in
            guard let letter = letters.randomElement() else { return Character("")}
            return letter
        })
    }
    
    static func setToAlphaOnly(str: String) -> String {
        return str.filter("qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM ".contains)
    }
    
    static func setToNumericOnly(str: String) -> String {
        return str.filter("0123456789".contains)
    }
    
    /// Masking string with specific character
    /// - Parameter indexs: index that want to masked.
    ///             masked:  masked character.
    /// - Returns: The string with the masking data, ex: 4111•••••••1111.
    func masking(indexs: [Int], with masked: Character) -> String {
        return String(self.enumerated().map { index, char in
          return indexs.contains(index) ? masked : char
       })
    }
    
    func insertSpacesIntoEvery4Digits() -> String {
        var cardWithAddedSpaces: String = ""
        for (index, char) in self.enumerated() {
            if index != 0 && index % 4 == 0 && index < 16 {
                cardWithAddedSpaces.append(" ")
            }
            cardWithAddedSpaces.append(char)
        }
        return cardWithAddedSpaces
    }
    
    func imageFromBase64() -> UIImage? {
            guard let data = Data(base64Encoded: self) else { return nil }

            return UIImage(data: data)
        }
    
    func capitalizedFirst() -> String {
            let first = self[self.startIndex ..< self.index(startIndex, offsetBy: 1)]
            let rest = self[self.index(startIndex, offsetBy: 1) ..< self.endIndex]
            return first.uppercased() + rest.lowercased()
        }
    
    func convertToDate(to newFormat: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = newFormat
        return formatter.date(from: self)
    }
    
    var space: String {
        return self + " "
    }
    
    func hexStringToUIColor() -> UIColor {
        var cString: String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            return UIColor.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    var toInlineError: String {
        if let pipeIndex = self.firstIndex(of: "|") {
            let pipeIndexAfter = self.index(after: pipeIndex)
            let text = self[pipeIndexAfter...]
            return String(text)
        } else {
            return self
        }
    }
    
    var toPopupBodyError: String {
        if let pipeIndex = self.firstIndex(of: "|") {
            let text = self[..<pipeIndex]
            return String(text)
        } else {
            return self
        }
    }
}

public enum Language: String {
    case en
    case id
}

