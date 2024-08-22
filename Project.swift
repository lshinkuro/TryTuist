import ProjectDescription
let appName = "TryTuist"
let prefixBundleID = "com.lshinkuro"

let project = Project(
  name: appName,
  targets: [
    .mainApp(appName,
             dependencies: [
              .target(name: "TTUI"),
              .target(name: "Coordinator"),
              .target(name: "Dependency"),
              .target(name: "NetworkManager"),
              .target(name: "TabBarFeature"),
              .target(name: "AuthenticationFeature"),
              .target(name: "HomeFeature"),
              .target(name: "ProfileFeature"),
              .target(name: "CalenderFeature"),
              .target(name: "FocuseFeature"),
              .external(name: "Alamofire"),
              .external(name: "netfox"),
              .external(name: "Lottie"),
              .external(name: "KeychainSwift"),
              .external(name: "Firebase")
]),
    
    //MARK: Foundations
    .framework("TTUI",
               sources: ["Foundations/TTUI/Sources/**/*.swift"],
               resources: [
                "Foundations/TTUI/Sources/**/*.xib",
                "Foundations/TTUI/Resources/**/*.xcassets",
                "Foundations/TTUI/Resources/**/*.ttf",
                "Foundations/TTUI/Resources/**/*.json"
                          ],
               dependencies: [
                .external(name: "RxSwift"),
                .external(name: "RxRelay"),
                .external(name: "RxCocoa"),
                .external(name: "SnapKit")
               ]),
    
    .framework("Coordinator",
               sources: ["Foundations/Coordinator/**/*.swift"],
               resources: [],
               dependencies: []),
    
    .framework("Dependency",
               sources: ["Foundations/Dependency/**/*.swift"],
               resources: [],
               dependencies: [
                .target(name: "Coordinator"),
               ]),

    .framework("NetworkManager",
               sources: ["Foundations/NetworkManager/**/*.swift"],
               resources: [],
               dependencies: [
                .target(name: "TTUI"),
                .target(name: "Coordinator"),
                .external(name: "Alamofire")
               ]),
    
    //MARK: Features
    .framework("AuthenticationFeature",
               sources: ["Features/AuthenticationFeature/Sources/**/*.swift",
                         "Features/AuthenticationFeature/Sources/**/*.xcassets",],
               resources: [
                "Features/AuthenticationFeature/Sources/**/*.xib",
                "Features/AuthenticationFeature/Resources/**/*.xcassets",

                          ],
               dependencies: [
                .target(name: "TTUI"),
                .external(name: "RxSwift"),
                .external(name: "RxRelay"),
                .external(name: "RxCocoa"),
                .target(name: "NetworkManager")
               ]),
    
    .framework("HomeFeature",
               sources: ["Features/HomeFeature/Sources/**/*.swift"],
               resources: ["Features/HomeFeature/Sources/**/*.xib",
                           "Features/HomeFeature/Resources/**/*.xcassets"
                          ],
               dependencies: [
                .target(name: "TTUI"),
                .target(name: "Dependency"),
                .target(name: "Coordinator"),
                .external(name: "SnapKit"),
               ]),
    
    .framework("ProfileFeature",
               sources: ["Features/ProfileFeature/Sources/**/*.swift"],
               resources: ["Features/ProfileFeature/Sources/**/*.xib",
                           "Features/ProfileFeature/Resources/**/*.xcassets"
                          ],
               dependencies: [
                .target(name: "TTUI"),
                .target(name: "Dependency"),
                .target(name: "Coordinator"),
                .external(name: "RxSwift"),
                .external(name: "RxRelay"),
                .external(name: "RxCocoa"),
                .external(name: "RxSwift"),

               ]),
    
        .framework("CalenderFeature",
                   sources: ["Features/CalenderFeature/Sources/**/*.swift"],
                   resources: ["Features/CalenderFeature/Sources/**/*.xib",
                               "Features/CalenderFeature/Resources/**/*.xcassets"
                              ],
                   dependencies: [
                    .target(name: "TTUI"),
                    .target(name: "Dependency"),
                    .target(name: "Coordinator"),
                    .external(name: "RxSwift"),
                    .external(name: "RxRelay"),
                    .external(name: "RxCocoa"),
                    .external(name: "RxSwift"),

                   ]),
    .framework("FocuseFeature",
               sources: ["Features/FocuseFeature/Sources/**/*.swift"],
               resources: ["Features/FocuseFeature/Sources/**/*.xib",
                           "Features/FocuseFeature/Resources/**/*.xcassets"
                          ],
               dependencies: [
                .target(name: "TTUI"),
                .target(name: "Dependency"),
                .target(name: "Coordinator"),
                .external(name: "RxSwift"),
                .external(name: "RxRelay"),
                .external(name: "RxCocoa"),
                .external(name: "RxSwift"),
               ]),
    
    .framework("TabBarFeature",
               sources: ["Features/TabBarFeature/Sources/**/*.swift"],
               resources: [],
               dependencies: [
                .target(name: "TTUI"),
                .target(name: "Dependency"),
                .target(name: "Coordinator"),
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
                  "App/Resources/**/*.ttf"],
      dependencies: dependencies
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
      dependencies: dependencies
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
      dependencies: dependencies
    )
  }
  
}

extension String {
  var dashSeparator: String {
    self.replacingOccurrences(of: " ", with: "-")
  }
}
