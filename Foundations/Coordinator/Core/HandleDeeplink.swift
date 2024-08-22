//
//  HandleDeeplink.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation

public protocol HandleDeeplink {
  func handleDeepLink(_ url: URL) -> Bool
}
