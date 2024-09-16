//
//  MenuItemCell.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import SnapKit

class MenuItemCell: UICollectionViewCell {

    let imageView = UIImageView()
    let titleLabel = UILabel()
    let newBadgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Configure imageView
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "text") // Replace with actual image name
        
        // Configure titleLabel
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.text = "Only 9k"
        
        // Configure newBadgeLabel
        newBadgeLabel.font = UIFont.systemFont(ofSize: 10)
        newBadgeLabel.textColor = UIColor(red: 0.89, green: 0.62, blue: 0.36, alpha: 1.00)
        newBadgeLabel.text = "NEW"
        newBadgeLabel.textAlignment = .center
        
        // Add subviews to the cell
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(newBadgeLabel)
    }
    
    private func setupConstraints() {
        // Set up constraints for the imageView
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.width.height.equalTo(40)
        }
        
        // Set up constraints for the newBadgeLabel
        newBadgeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(imageView.snp.right).offset(-8)
            make.top.equalToSuperview().offset(4)
        }
        
        // Set up constraints for the titleLabel
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
}
