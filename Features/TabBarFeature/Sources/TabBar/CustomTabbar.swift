//
//  CustomTabbar.swift
//  TabBarFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import UIKit


open class CustomTabbar: UITabBarController {
    
    let btnMiddle : UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        btn.setTitle("", for: .normal)
        btn.backgroundColor = UIColor.foodBrightBlue
        btn.layer.cornerRadius = 30
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.2
        btn.layer.shadowOffset = CGSize(width: 4, height: 4)
        btn.setBackgroundImage(UIImage(named: "ic_cart"), for: .normal)
        
        return btn
    }()

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hidesBottomBarWhenPushed = false
        navigationController?.isNavigationBarHidden = true
        
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        btnMiddle.frame = CGRect(x: Int(self.tabBar.bounds.width)/2 - 30, y: -20, width: 60, height: 60)
    }
    
    public override func loadView() {
        setupCustomTabBar()
    }
    
    func setupCustomTabBar() {
        let path: UIBezierPath = getPathForTabBar()
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.lineWidth = 3
        shape.strokeColor = UIColor.foodBrightBlue.cgColor
        shape.fillColor = UIColor.foodBrightBlue.cgColor
        self.tabBar.layer.insertSublayer(shape, at: 0)
        self.tabBar.itemWidth = 40
        self.tabBar.itemPositioning = .centered
        self.tabBar.itemSpacing = 70
        self.tabBar.tintColor = UIColor.foodBrightBlue
        self.tabBar.unselectedItemTintColor = UIColor.white
        self.tabBar.barTintColor = UIColor.clear
        self.tabBar.backgroundColor = UIColor.clear
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            self.tabBar.standardAppearance = appearance
            self.tabBar.scrollEdgeAppearance = appearance
        }
        
    }
    
    func getPathForTabBar() -> UIBezierPath {
        let holeWidth: CGFloat = 170
        let holeHeight: CGFloat = 70
        let frameWidth = self.tabBar.bounds.width
        let frameHeight = self.tabBar.bounds.height + 40
        let leftXUntilHole = frameWidth / 2 - holeWidth / 2

        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: leftXUntilHole, y: 0))
        path.addCurve(to: CGPoint(x: leftXUntilHole + (holeWidth / 3), y: holeHeight / 2),
                      controlPoint1: CGPoint(x: leftXUntilHole + ((holeWidth / 3) / 8) * 6, y: 0),
                      controlPoint2: CGPoint(x: leftXUntilHole + ((holeWidth / 3) / 8) * 8, y: holeHeight / 2))
        path.addCurve(to: CGPoint(x: leftXUntilHole + (2 * holeWidth) / 3, y: holeHeight / 2),
                      controlPoint1: CGPoint(x: leftXUntilHole + (holeWidth / 3) + (holeWidth / 3) / 3 * 2 / 5, y: (holeHeight / 2) * 6 / 4),
                      controlPoint2: CGPoint(x: leftXUntilHole + (holeWidth / 3) + (holeWidth / 3) / 3 * 2 + (holeWidth / 3) / 3 * 3 / 5, y: (holeHeight / 2) * 6 / 4))
        path.addCurve(to: CGPoint(x: leftXUntilHole + holeWidth, y: 0),
                      controlPoint1: CGPoint(x: leftXUntilHole + (2 * holeWidth) / 3, y: holeHeight / 2),
                      controlPoint2: CGPoint(x: leftXUntilHole + (2 * holeWidth) / 3 + (holeWidth / 3) * 2 / 8, y: 0))
        path.addLine(to: CGPoint(x: frameWidth, y: 0))
        path.addLine(to: CGPoint(x: frameWidth, y: frameHeight))
        path.addLine(to: CGPoint(x: 0, y: frameHeight))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.close()
        
        return path
    }
}
