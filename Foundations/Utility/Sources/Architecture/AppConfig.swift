//
//  AppConfig.swift
//  Utility
//
import Foundation

public enum AppConfig {
    /// `true` = semua repository memakai Mock data source (tanpa backend).
    /// Diatur per environment lewat `USE_MOCK_DATA` di Configs/<Env>.xcconfig.
    public static var useMockData: Bool { AppEnvironment.useMockData }
}
