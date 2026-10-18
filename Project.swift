import ProjectDescription

let appName = "TryTuist"
let prefixBundleID = "com.lshinkuro"
/// Minimal iOS version untuk seluruh target.
let minimumIOSVersion = "17.0"

/// ⚠️ Harus dideklarasikan SEBELUM `let project`. Manifest dijalankan sebagai script:
/// variabel global diinisialisasi berurutan dari atas, jadi kalau ditaruh di bawah,
/// nilainya masih kosong saat `project` dibuat (dan `merging` membuat Tuist crash).
let baseSettings: SettingsDictionary = [
    "OTHER_LDFLAGS": "$(inherited) -ObjC",
    "SWIFT_VERSION": "5.0",
    // Signing persisten: tidak perlu set ulang di Xcode setiap kali `tuist generate`.
    // CODE_SIGN_STYLE = Automatic → Xcode urus provisioning profile sendiri.
    // Ganti DEVELOPMENT_TEAM dengan Team ID kamu (dari developer.apple.com/account → Membership).
    "CODE_SIGN_STYLE": "Automatic",
    "DEVELOPMENT_TEAM": "44X7PP9237"
]

// MARK: - Environment (Dev / Staging / Prod)
//
// Tiap environment = 1 build configuration + 1 xcconfig (Configs/*.xcconfig) + 1 scheme.
// Nilai seperti API_BASE_URL dibaca app lewat Info.plist → `AppEnvironment` (modul Utility).
enum AppEnv: String, CaseIterable {
    case dev = "Dev"
    case staging = "Staging"
    case prod = "Prod"

    var configuration: Configuration {
        let xcconfig: Path = .relativeToManifest("Configs/\(rawValue).xcconfig")
        switch self {
        case .dev: return .debug(name: .configuration(rawValue), xcconfig: xcconfig)
        case .staging, .prod: return .release(name: .configuration(rawValue), xcconfig: xcconfig)
        }
    }

    var scheme: Scheme {
        let config: ConfigurationName = .configuration(rawValue)
        return .scheme(
            name: "\(appName)-\(rawValue)",
            shared: true,
            buildAction: .buildAction(targets: [.target(appName)]),
            runAction: .runAction(configuration: config),
            archiveAction: .archiveAction(configuration: config),
            profileAction: .profileAction(configuration: config),
            analyzeAction: .analyzeAction(configuration: config)
        )
    }
}

let project = Project(
    name: appName,
    // Package SPM diintegrasikan langsung oleh Xcode (bukan dikonversi Tuist ke .xcodeproj),
    // supaya versi iOS minimum package diatur Xcode sendiri. Tuist/Package.swift dibiarkan kosong.
    packages: [
        .remote(url: "https://github.com/google/GoogleSignIn-iOS", requirement: .upToNextMajor(from: "8.0.0"))
    ],
    settings: .settings(configurations: AppEnv.allCases.map(\.configuration)),
    targets: [
        .mainApp(appName,
                 dependencies: [
                    .Navigation,
                    .TTUI,
                    .Utility,
                    .NetworkManager,
                    .CoreDataManager,
                    .Debugger,
                    .AuthenticationFeature,
                    .HomeFeature,
                    .FocuseFeature,
                    .ProfileFeature
                 ]),
        //MARK: Foundations
        .framework(.TTUI,
                   sources: ["Foundations/TTUI/Sources/**/*.swift"],
                   resources: [
                    "Foundations/TTUI/Resources/**/*.xcassets"
                   ],
                   dependencies: [
                    .Utility
                   ]),
        // Router + tab bar: satu-satunya tempat SwiftUI dibungkus ke UIKit.
        .framework(.Navigation,
                   sources: ["Foundations/Navigation/Sources/**/*.swift"],
                   resources: [],
                   dependencies: []),
        .framework(.Utility,
                   sources: ["Foundations/Utility/**/*.swift"],
                   resources: [],
                   dependencies: []),
        .framework(.NetworkManager,
                   sources: ["Foundations/NetworkManager/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility
                   ]),
        // Debugger (shake device): log API, layar aktif, shortcut navigasi, ganti server. Non-Prod saja.
        .framework(.Debugger,
                   sources: ["Foundations/Debugger/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .NetworkManager, .Navigation
                   ]),
        .framework(.CoreDataManager,
                   sources: ["Foundations/CoreDataManager/**/*.swift"],
                   resources: ["Foundations/CoreDataManager/Resources/**/*.xcdatamodeld"],
                   dependencies: []),
        //MARK: Features
        .framework(.AuthenticationFeature,
                   sources: ["Features/AuthenticationFeature/Sources/**/*.swift"],
                   resources: ["Features/AuthenticationFeature/Resources/**/*.xcassets"],
                   dependencies: [
                    .Utility, .TTUI, .NetworkManager, .Navigation,
                    // Google Sign-In (SPM, lihat Tuist/Package.swift)
                    .GoogleSignIn
                   ]),
        .framework(.HomeFeature,
                   sources: ["Features/HomeFeature/Sources/**/*.swift"],
                   resources: ["Features/HomeFeature/Resources/**/*.xcassets"],
                   dependencies: [
                    .Utility, .TTUI, .NetworkManager, .Navigation
                   ]),
        .framework(.ProfileFeature,
                   sources: ["Features/ProfileFeature/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .NetworkManager, .Navigation
                   ]),
        .framework(.FocuseFeature,
                   sources: ["Features/FocuseFeature/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .NetworkManager, .Navigation
                   ])
    ],
    schemes: AppEnv.allCases.map(\.scheme)
)

public extension ProjectDescription.Target {
    static func mainApp(_ name: String, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        .target(
            name: "\(name)",
            destinations: .iOS,
            product: .app,
            bundleId: "\(prefixBundleID).\(name.dashSeparator)",
            deploymentTargets: .iOS(minimumIOSVersion),
            infoPlist: .file(path: .relativeToManifest("App/Info.plist")),
            sources: ["App/Sources/**/*.swift"],
            resources: ["App/Resources/**/*.xcassets",
                        "App/Resources/**/*.ttf",
                        "App/Resources/**/*.strings"],
            // Push Notifications (aps-environment). Butuh Apple Developer Program berbayar.
            entitlements: .file(path: .relativeToManifest("TryTuist.entitlements")),
            dependencies: dependencies,
            settings: .settings(base: baseSettings.merging([
                // Dev & Staging bisa terpasang berdampingan dengan Prod di satu device.
                "PRODUCT_BUNDLE_IDENTIFIER": .string("\(prefixBundleID).\(name.dashSeparator)$(BUNDLE_ID_SUFFIX)")
            ]) { _, new in new })
        )
    }

    static func framework(_ targetName: String, sources: SourceFilesList?, resources: ResourceFileElements?, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        .target(
            name: targetName,
            destinations: .iOS,
            product: .framework,
            bundleId: "\(prefixBundleID).\(targetName.dashSeparator)",
            deploymentTargets: .iOS(minimumIOSVersion),
            sources: sources,
            resources: resources,
            dependencies: dependencies,
            settings: .settings(base: baseSettings)
        )
    }
}


internal extension String {
    var dashSeparator: String {
        self.replacingOccurrences(of: " ", with: "-")
    }
    static let Navigation = "Navigation"
    static let TTUI = "TTUI"
    static let Utility = "Utility"
    static let NetworkManager = "NetworkManager"
    static let AuthenticationFeature = "AuthenticationFeature"
    static let HomeFeature = "HomeFeature"
    static let ProfileFeature = "ProfileFeature"
    static let FocuseFeature = "FocuseFeature"
    static let CoreDataManager = "CoreDataManager"
    static let Debugger = "Debugger"
}

extension TargetDependency {
    // MARK: TargetDependency Internal
    static let Navigation = TargetDependency.target(name: "Navigation")
    static let TTUI = TargetDependency.target(name: "TTUI")
    static let Utility = TargetDependency.target(name: "Utility")
    static let NetworkManager = TargetDependency.target(name: "NetworkManager")
    static let AuthenticationFeature = TargetDependency.target(name: "AuthenticationFeature")
    static let HomeFeature = TargetDependency.target(name: "HomeFeature")
    static let ProfileFeature = TargetDependency.target(name: "ProfileFeature")
    static let FocuseFeature = TargetDependency.target(name: "FocuseFeature")
    static let CoreDataManager = TargetDependency.target(name: "CoreDataManager")
    static let Debugger = TargetDependency.target(name: "Debugger")

    /// Google Sign-In (SPM bawaan Xcode, lihat `packages:` di atas).
    static let GoogleSignIn = TargetDependency.package(product: "GoogleSignIn")
}
