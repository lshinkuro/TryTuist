//
//  OnBoardCell.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import UIKit
import SnapKit

class OnBoardCell: UICollectionViewCell {
    
    // Membuat imageView, titleLabel, dan subtitleLabel
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Menambahkan imageView, titleLabel, dan subtitleLabel ke contentView
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
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
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(250) // Ukuran gambar bisa disesuaikan
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(20)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(40)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
    }
    
    // Mengatur gaya tampilan (opsional)
    private func setupStyles() {
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .white
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        imageView.contentMode = .scaleAspectFit
    }
    
    // Metode untuk mengatur data cell
    func configure(with data: OnboardingItem) {
        imageView.image = data.image
        titleLabel.text = data.title
        subtitleLabel.text = data.subtitle
    }
}
