//
//  FormView.swift
//  TryTuist
//
//  Created by Phincon on 13/08/24.
//

import Foundation
import UIKit

open class FormView: UIView {
    
    var cornerRadius: CGFloat = 16
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        applyShadow(on: self.frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
        applyShadow(on: self.frame)
    }
    
    func applyShadow(on rect: CGRect) {
        self.addShadow(
            color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.1),
            offset: CGSize(
                width: 0,
                height: 2),
            opacity: 0.5,
            radius: 5,
            path: nil)
        self.layer.masksToBounds = false
    }
    
    func setup() {
        self.addBorderLine(width: 0.5, color: UIColor(white: 0, alpha: 0.05))
        self.backgroundColor = .foodWhite100
        self.makeCornerRadius(cornerRadius, maskedCorner: [[.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]])
    }
}
