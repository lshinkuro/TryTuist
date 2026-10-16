import ProjectDescription

let appName = "TryTuist"
let prefixBundleID = "com.lshinkuro"
/// Minimal iOS version untuk seluruh target.
let minimumIOSVersion = "17.0"

let project = Project(
    name: appName,
    targets: [
        .mainApp(appName,
                 dependencies: [
                    .Dependency,
                    .TTUI,
                    .Coordinator,
                    .NetworkManager,
                    .TabBarFeature,
                    .AuthenticationFeature,
                    .HomeFeature,
                    .Utility,
                    .ProfileFeature,
                    .CalenderFeature,
                    .FocuseFeature,
                    .CoreDataManager
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
        .framework(.Coordinator,
                   sources: ["Foundations/Coordinator/**/*.swift"],
                   resources: [],
                   dependencies: []),
        .framework(.Dependency,
                   sources: ["Foundations/Dependency/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Coordinator
                   ]),
        .framework(.Utility,
                   sources: ["Foundations/Utility/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Coordinator
                   ]),
        .framework(.NetworkManager,
                   sources: ["Foundations/NetworkManager/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility
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
                    .Utility, .TTUI, .NetworkManager, .Dependency, .Coordinator
                   ]),
        .framework(.HomeFeature,
                   sources: ["Features/HomeFeature/Sources/**/*.swift"],
                   resources: ["Features/HomeFeature/Resources/**/*.xcassets"],
                   dependencies: [
                    .Utility, .TTUI, .Dependency, .Coordinator, .CoreDataManager
                   ]),
        .framework(.ProfileFeature,
                   sources: ["Features/ProfileFeature/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .Dependency, .Coordinator
                   ]),
        .framework(.CalenderFeature,
                   sources: ["Features/CalenderFeature/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .Dependency, .Coordinator
                   ]),
        .framework(.FocuseFeature,
                   sources: ["Features/FocuseFeature/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .Dependency, .Coordinator
                   ]),
        .framework(.TabBarFeature,
                   sources: ["Features/TabBarFeature/Sources/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Utility, .TTUI, .Dependency, .Coordinator
                   ])
    ]
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
            dependencies: dependencies,
            settings: .settings(base: baseSettings)
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

private let baseSettings: SettingsDictionary = [
    "OTHER_LDFLAGS": "$(inherited) -ObjC",
    "SWIFT_VERSION": "5.0"
]

internal extension String {
    var dashSeparator: String {
        self.replacingOccurrences(of: " ", with: "-")
    }
    static let TabBarFeature = "TabBarFeature"
    static let Dependency = "Dependency"
    static let TTUI = "TTUI"
    static let Coordinator = "Coordinator"
    static let Utility = "Utility"
    static let NetworkManager = "NetworkManager"
    static let AuthenticationFeature = "AuthenticationFeature"
    static let HomeFeature = "HomeFeature"
    static let ProfileFeature = "ProfileFeature"
    static let CalenderFeature = "CalenderFeature"
    static let FocuseFeature = "FocuseFeature"
    static let CoreDataManager = "CoreDataManager"
}

extension TargetDependency {
    // MARK: TargetDependency Internal
    static let Dependency = TargetDependency.target(name: "Dependency")
    static let TTUI = TargetDependency.target(name: "TTUI")
    static let Coordinator = TargetDependency.target(name: "Coordinator")
    static let Utility = TargetDependency.target(name: "Utility")
    static let NetworkManager = TargetDependency.target(name: "NetworkManager")
    static let TabBarFeature = TargetDependency.target(name: "TabBarFeature")
    static let AuthenticationFeature = TargetDependency.target(name: "AuthenticationFeature")
    static let HomeFeature = TargetDependency.target(name: "HomeFeature")
    static let ProfileFeature = TargetDependency.target(name: "ProfileFeature")
    static let CalenderFeature = TargetDependency.target(name: "CalenderFeature")
    static let FocuseFeature = TargetDependency.target(name: "FocuseFeature")
    static let CoreDataManager = TargetDependency.target(name: "CoreDataManager")
}
