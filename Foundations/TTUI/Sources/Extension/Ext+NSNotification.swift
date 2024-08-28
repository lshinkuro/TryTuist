//
//  Ext+NSNotification.swift
//  TTUI
//
//  Created by Phincon on 24/08/24.
//

import Foundation

extension NSNotification.Name {
    static let toLoginView = Notification.Name(rawValue: "toLoginView")
    static let toTransferView = Notification.Name(rawValue: "toTransferView")
    static let toOwnAccountView = Notification.Name(rawValue: "toOwnAccount")
}
