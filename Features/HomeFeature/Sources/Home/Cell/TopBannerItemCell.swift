//
//  TopBannerItemCell.swift
//  HomeFeature
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import SnapKit

class TopBannerItemCell: UICollectionViewCell {
    
    // Membuat imageView, titleLabel, dan subtitleLabel
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        
        setupConstraints()
        setupStyles()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupConstraints()
        setupStyles()
    }
    
    // Mengatur constraints dengan SnapKit
    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // Mengatur gaya tampilan (opsional)
    private func setupStyles() {
        imageView.contentMode = .scaleToFill
    }
    
    // Metode untuk mengatur data cell
    func configure(with data: TopBannerItem) {
        imageView.image = data.bgImage
    }
}
