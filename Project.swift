import ProjectDescription
let appName = "TryTuist"
let prefixBundleID = "com.lshinkuro"

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
                    .ProfileFeature,
                    .CalenderFeature,
                    .FocuseFeature,
                    .alamofire,
                    .netfox,
                    .lottie,
                    .keychainSwift,
                    .keychainSwift,
                    .snapkit
                 ]),
        
        //MARK: Foundations
        .framework(.TTUI,
                   sources: ["Foundations/TTUI/Sources/**/*.swift"],
                   resources: [
                    "Foundations/TTUI/Sources/**/*.xib",
                    "Foundations/TTUI/Resources/**/*.xcassets",
                    "Foundations/TTUI/Resources/**/*.ttf",
                    "Foundations/TTUI/Resources/**/*.json"
                   ],
                   dependencies: [
                    .rxSwift, .rxRelay , .rxCocoa , .skeletonView, .lottie, .snapkit
                   ]),
        
            .framework(.Coordinator,
                       sources: ["Foundations/Coordinator/**/*.swift"],
                       resources: [],
                       dependencies: []),
        
            .framework(.Dependency,
                       sources: ["Foundations/Dependency/**/*.swift"],
                       resources: [],
                       dependencies: [
                        .target(name: "Coordinator"),
                       ]),
        .framework(.Utility,
                   sources: ["Foundations/Utility/**/*.swift"],
                   resources: [],
                   dependencies: [
                    .Coordinator,
                    .rxSwift, .rxRelay , .rxCocoa , .skeletonView, .lottie, .snapkit
                   ]),
        
            .framework(.NetworkManager,
                       sources: ["Foundations/NetworkManager/**/*.swift"],
                       resources: [],
                       dependencies: [
                        .Utility, .TTUI, .Coordinator,
                        .alamofire
                       ]),
        
        //MARK: Features
        .framework(.AuthenticationFeature,
                   sources: ["Features/AuthenticationFeature/Sources/**/*.swift",
                             "Features/AuthenticationFeature/Sources/**/*.xcassets",],
                   resources: [
                    "Features/AuthenticationFeature/Sources/**/*.xib",
                    "Features/AuthenticationFeature/Resources/**/*.xcassets",
                    
                   ],
                   dependencies: [
                    .Utility, .TTUI, .NetworkManager,
                    .rxSwift, .rxRelay , .rxCocoa , .skeletonView, .lottie
                   ]),
        
            .framework(.HomeFeature,
                       sources: ["Features/HomeFeature/Sources/**/*.swift"],
                       resources: ["Features/HomeFeature/Sources/**/*.xib",
                                   "Features/HomeFeature/Resources/**/*.xcassets"
                                  ],
                       dependencies: [
                        .Utility, .TTUI, .Dependency, .Coordinator,
                        .snapkit, .skeletonView
                       ]),
        
            .framework(.ProfileFeature,
                       sources: ["Features/ProfileFeature/Sources/**/*.swift"],
                       resources: ["Features/ProfileFeature/Sources/**/*.xib",
                                   "Features/ProfileFeature/Resources/**/*.xcassets"
                                  ],
                       dependencies: [
                        .Utility, .TTUI, .Dependency, .Coordinator,
                        .rxSwift, .rxRelay , .rxCocoa , .skeletonView
                       ]),
        
            .framework(.CalenderFeature,
                       sources: ["Features/CalenderFeature/Sources/**/*.swift"],
                       resources: ["Features/CalenderFeature/Sources/**/*.xib",
                                   "Features/CalenderFeature/Resources/**/*.xcassets"
                                  ],
                       dependencies: [
                        .Utility, .TTUI, .Dependency, .Coordinator,
                        .rxSwift, .rxRelay , .rxCocoa , .skeletonView
                       ]),
        .framework(.FocuseFeature,
                   sources: ["Features/FocuseFeature/Sources/**/*.swift"],
                   resources: ["Features/FocuseFeature/Sources/**/*.xib",
                               "Features/FocuseFeature/Resources/**/*.xcassets"
                              ],
                   dependencies: [
                    .Utility, .TTUI, .Dependency, .Coordinator,
                    .rxSwift, .rxRelay , .rxCocoa , .skeletonView
                    
                   ]),
        
            .framework(.TabBarFeature,
                       sources: ["Features/TabBarFeature/Sources/**/*.swift"],
                       resources: [],
                       dependencies: [
                        .Utility, .TTUI, .Dependency, .Coordinator
                       ]),
    ]
)



public extension ProjectDescription.Target {
    
    static func mainApp(_ name: String, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        .target(
            name: "\(name)",
            destinations: .iOS,
            product: .app,
            bundleId: "\(prefixBundleID).\(name.dashSeparator)",
            infoPlist: .file(path: .relativeToManifest("App/Info.plist")),
            sources: ["App/Sources/**/*.swift",],
            resources: ["App/Sources/**/*.xib",
                        "App/Resources/**/*.xcassets",
                        "App/Resources/**/*.ttf",
                        "App/Resources/**/*.json"],
            dependencies: dependencies,
            settings: .settings(
              base: ["OTHER_LDFLAGS": "$(inherited) -ObjC"])
        )
    }
    
    static func framework(_ targetName: String, sources: SourceFilesList?, resources: ResourceFileElements?, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        .target(
            name: targetName,
            destinations: .iOS,
            product: .framework,
            bundleId: "\(prefixBundleID).\(targetName.dashSeparator)",
            sources: sources,
            resources: resources,
            dependencies: dependencies,
            settings: .settings(
              base: ["OTHER_LDFLAGS": "$(inherited) -ObjC"])
        )
    }
    
    static func example(_ targetName: String, sources: SourceFilesList?, resources: ResourceFileElements?, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        .target(
            name: targetName,
            destinations: .iOS,
            product: .app,
            bundleId: "\(prefixBundleID).\(targetName.dashSeparator)",
            sources: sources,
            resources: resources,
            dependencies: dependencies,
            settings: .settings(
              base: ["OTHER_LDFLAGS": "$(inherited) -ObjC"])
        )
    }
    
}

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
    
    
    
    // MARK: TargetDependency External
    static let kingFisher = TargetDependency.external(name: "Kingfisher")
    static let skeletonView = TargetDependency.external(name: "SkeletonView")
    static let rxSwift = TargetDependency.external(name: "RxSwift")
    static let rxRelay = TargetDependency.external(name: "RxRelay")
    static let rxCocoa = TargetDependency.external(name: "RxCocoa")
    static let alamofire = TargetDependency.external(name: "Alamofire")
    static let netfox = TargetDependency.external(name: "netfox")
    static let lottie = TargetDependency.external(name: "Lottie")
    static let keychainSwift = TargetDependency.external(name: "KeychainSwift")
    static let snapkit = TargetDependency.external(name: "SnapKit")
    
}
