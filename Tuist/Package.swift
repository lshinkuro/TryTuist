// swift-tools-version: 5.10
import PackageDescription

// Dependency eksternal lewat integrasi Tuist (`.external(name:)`). Saat ini kosong.
//
// GoogleSignIn TIDAK ditaruh di sini: Tuist mengubah package menjadi .xcodeproj dengan
// versi iOS minimum dari manifest package (GoogleUtilities masih iOS 12), dan Xcode 26
// menolaknya. GoogleSignIn dipasang lewat SPM bawaan Xcode di Project.swift (`packages:`).
let package = Package(
    name: "PackageName",
    dependencies: []
)
