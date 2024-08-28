//
//  Ext+RefreshControl.swift
//  TTUI
//
//  Created by Phincon on 24/08/24.
//

import Foundation
import UIKit

public extension UIRefreshControl {
    
    typealias RefreshAction = () -> Void

    func addAction(_ action: @escaping RefreshAction) {
        self.addTarget(self, action: #selector(handleRefreshControl(_:)), for: .valueChanged)
        objc_setAssociatedObject(self, UnsafeRawPointer(bitPattern: "RefreshAction".hashValue)!, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc private func handleRefreshControl(_ sender: UIRefreshControl) {
        if let action = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "RefreshAction".hashValue)!) as? RefreshAction {
            action()
        }
    }
}
