//
//  GoogleSignInClients.swift
//  AuthenticationFeature · Data
//
//  Sheet "Lanjutkan dengan Google" → ID token. Token ini yang dikirim ke backend
//  (`POST /v1/auth/google`, API_PLAN.md §5.3b); backend yang memverifikasi & membuat akun.
//
//  Setup (sekali):
//  1. Google Cloud Console → OAuth client ID tipe iOS untuk bundle ID tiap environment.
//  2. Isi `GOOGLE_CLIENT_ID` & `GOOGLE_REVERSED_CLIENT_ID` di Configs/<Env>.xcconfig.
//  3. Backend: `GOOGLE_CLIENT_IDS` di .env berisi client ID yang sama.
//
import Foundation
import GoogleSignIn
import UIKit

/// Google Sign-In asli lewat SDK GoogleSignIn-iOS.
struct GoogleSDKSignInClient: GoogleSignInClient {
    @MainActor
    func signIn() async throws -> GoogleAccount {
        guard let clientID = GoogleSignInConfig.clientID else { throw AuthError.googleNotConfigured }
        guard let presenter = Self.topViewController() else { throw AuthError.googleFailed }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthError.googleFailed }
            let account = GoogleAccount(idToken: idToken,
                                        email: result.user.profile?.email,
                                        name: result.user.profile?.name)
            // Sesi app dipegang backend (access/refresh token); sesi Google tidak perlu disimpan.
            // Dengan sign out, pemilih akun Google selalu muncul di percobaan berikutnya.
            GIDSignIn.sharedInstance.signOut()
            return account
        } catch let error as GIDSignInError where error.code == .canceled {
            throw AuthError.googleCancelled
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.googleFailed
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

/// Dipakai saat `USE_MOCK_DATA = YES`: tanpa sheet Google, langsung "berhasil" sebagai akun demo.
struct MockGoogleSignInClient: GoogleSignInClient {
    static let token = "mock-google-id-token"

    @MainActor
    func signIn() async throws -> GoogleAccount {
        try await Task.sleep(for: .milliseconds(400))
        return GoogleAccount(idToken: Self.token, email: "kholis@gmail.com", name: "Kholis")
    }
}

/// Membaca konfigurasi dari Info.plist (`GIDClientID` & URL scheme dari xcconfig).
enum GoogleSignInConfig {
    /// `nil` bila client ID kosong atau URL scheme callback belum terdaftar —
    /// SDK akan crash bila dipanggil tanpa keduanya, jadi dicek di sini dulu.
    static var clientID: String? {
        let bundle = Bundle.main
        guard let raw = bundle.object(forInfoDictionaryKey: "GIDClientID") as? String else { return nil }
        let clientID = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty, !clientID.hasPrefix("$("), clientID.hasSuffix(".apps.googleusercontent.com") else {
            return nil
        }
        return registeredSchemes.contains(reversed(clientID)) ? clientID : nil
    }

    /// "1234-abc.apps.googleusercontent.com" → "com.googleusercontent.apps.1234-abc"
    static func reversed(_ clientID: String) -> String {
        clientID.split(separator: ".").reversed().joined(separator: ".")
    }

    private static var registeredSchemes: Set<String> {
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
        return Set(types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] })
    }
}

/// Dipanggil SceneDelegate saat app dibuka lewat URL (callback dari halaman login Google).
public enum GoogleSignInURLHandler {
    @MainActor
    @discardableResult
    public static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
