//
//  OnDeviceAI.swift
//  Utility
//
//  Status Apple Intelligence (FoundationModels, iOS 26+), dipakai semua feature yang punya fitur AI.
//
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public enum OnDeviceAI {
    /// Model siap dan bahasa perangkat didukung. Model menolak bahasa yang tidak didukung
    /// (Indonesia belum ada per iOS 27), jadi fitur AI disembunyikan.
    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            let model = SystemLanguageModel.default
            return model.isAvailable && model.supportsLocale()
        }
        #endif
        return false
    }

    /// Nama bahasa perangkat dalam bahasa Inggris (mis. "English") untuk instruksi "jawab dalam bahasa …".
    public static var replyLanguage: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }
}
