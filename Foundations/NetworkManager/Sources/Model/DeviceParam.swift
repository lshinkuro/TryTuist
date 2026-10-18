//
//  DeviceParam.swift
//  NetworkManager
//
//  Body `PUT /v1/me/devices` (API_PLAN.md §5.28): device token APNs untuk notifikasi push.
//
import Foundation

public struct RegisterDeviceParam {
    /// Device token APNs dalam hex.
    public let token: String
    /// `apns-topic` di server, mis. "com.lshinkuro.try-tuist.dev".
    public let bundleID: String
    /// "sandbox" (build Debug / development) | "production" (TestFlight / App Store).
    public let environment: String

    public init(token: String, bundleID: String, environment: String) {
        self.token = token
        self.bundleID = bundleID
        self.environment = environment
    }

    var body: [String: Any] {
        ["token": token, "bundle_id": bundleID, "environment": environment]
    }
}
