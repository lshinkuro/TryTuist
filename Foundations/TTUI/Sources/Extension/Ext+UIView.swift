//
//  Ext+UIView.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit

public extension UIView {
    
    func add(_ views: UIView...) {
        for i in views {
            self.addSubview(i)
        }
    }
    
    func makeCornerRadius(_ radius: CGFloat, maskedCorner: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]) {
        layer.cornerRadius = radius
        layer.maskedCorners = maskedCorner
        clipsToBounds = true
    }
    
    
    func addBorderLine(width: CGFloat = 1,
                       color: UIColor = .foodGrey3) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    func addShadow(color: UIColor = .foodBlack80,
                   offset: CGSize = CGSize(width: 0, height: 3),
                   opacity: Float = 0.5,
                   radius: CGFloat = 2,
                   path: UIBezierPath? = nil) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowPath = path?.cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView ?? UIView()
    }
    
    func addTapGestureTarget(_ target: Any?, action: Selector) {
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGesture)
    }
    
    typealias TapAction = () -> Void
    func addTapGestureAction(_ action: @escaping TapAction) {
        isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        objc_setAssociatedObject(self, UnsafeRawPointer(bitPattern: "TapAction".hashValue)!, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    @objc private func handleGesture(_ sender: UITapGestureRecognizer) {
        if let action = objc_getAssociatedObject(self, UnsafeRawPointer(bitPattern: "TapAction".hashValue)!) as? TapAction {
            action()
        }
    }
    
    
}

public extension UIStackView {
    func addArrange(_ views: UIView...) {
        for i in views {
            self.addArrangedSubview(i)
        }
    }
    
    /// SwifterSwift: Removes all views in stack’s array of arranged subviews.
    func removeArrangedSubviews() {
        for view in arrangedSubviews {
            removeArrangedSubview(view)
        }
    }
    
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
    
    /// SwifterSwift: Adds array of views to the end of the arrangedSubviews array.
    ///
    /// - Parameter views: views array.
    func addArrangedSubviews(_ views: [UIView]) {
        for view in views {
            addArrangedSubview(view)
        }
    }
    
    /// SwifterSwift: Exchanges two views of the arranged subviews.
    /// - Parameters:
    ///   - view1: first view to swap.
    ///   - view2: second view to swap.
    ///   - animated: set true to animate swap (default is true).
    ///   - duration: animation duration in seconds (default is 0.25 second).
    ///   - delay: animation delay in seconds (default is 0 second).
    ///   - options: animation options (default is AnimationOptions.curveEaseInOut).
    ///   - completion: optional completion handler to run with animation finishes (default is nil).
    func swap(_ view1: UIView, _ view2: UIView,
              animated: Bool = true,
              duration: TimeInterval = 0.25,
              delay: TimeInterval = 0,
              options: UIView.AnimationOptions = .curveEaseInOut,
              completion: ((Bool) -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: duration, delay: delay, options: options, animations: {
                self.swapViews(view1, view2)
                self.layoutIfNeeded()
            }, completion: completion)
        } else {
            self.swapViews(view1, view2)
        }
    }
    
    internal func swapViews(_ view1: UIView, _ view2: UIView) {
        guard let view1Index = arrangedSubviews.firstIndex(of: view1),
              let view2Index = arrangedSubviews.firstIndex(of: view2)
        else { return }
        removeArrangedSubview(view1)
        insertArrangedSubview(view1, at: view2Index)
        
        removeArrangedSubview(view2)
        insertArrangedSubview(view2, at: view1Index)
    }
}
