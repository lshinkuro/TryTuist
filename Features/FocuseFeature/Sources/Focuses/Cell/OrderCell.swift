//
//  OrderCell.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
import UIKit
import TTUI
// MARK: - OrderCell

class OrderCell: UITableViewCell {
    
    let productImageView = UIImageView()
    let productNameLabel = UILabel()
    let storeLabel = UILabel()
    let dateLabel = UILabel()
    let priceLabel = UILabel()
    let itemCountLabel = UILabel()
    let reorderButton = UIButton()
    let rateButton = UIButton()
    let containerView = FormView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        selectionStyle = .none
        
        addSubview(containerView)

        containerView.addSubview(productImageView)
        containerView.addSubview(productNameLabel)
        containerView.addSubview(storeLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(itemCountLabel)
        containerView.addSubview(reorderButton)
        containerView.addSubview(rateButton)
        
        
        
        // Setup Layout using SnapKit
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        productImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(50)
        }
        
        productNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.equalTo(productImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        storeLabel.snp.makeConstraints { make in
            make.top.equalTo(productNameLabel.snp.bottom).offset(4)
            make.leading.equalTo(productNameLabel)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(storeLabel.snp.bottom).offset(4)
            make.leading.equalTo(productNameLabel)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(4)
            make.leading.equalTo(productNameLabel)
        }
        
        itemCountLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(4)
            make.leading.equalTo(productNameLabel)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        reorderButton.setTitle("Reorder", for: .normal)
        reorderButton.setTitleColor(.black, for: .normal)
        reorderButton.layer.borderColor = UIColor.black.cgColor
        reorderButton.layer.borderWidth = 1
        reorderButton.layer.cornerRadius = 20
        reorderButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(80)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        rateButton.setTitle("Rate +2", for: .normal)
        rateButton.setTitleColor(.orange, for: .normal)
        rateButton.layer.borderColor = UIColor.orange.cgColor
        rateButton.layer.borderWidth = 1
        rateButton.layer.cornerRadius = 20
        rateButton.snp.makeConstraints { make in
            make.trailing.equalTo(reorderButton.snp.leading).offset(-8)
            make.centerY.equalTo(reorderButton.snp.centerY)
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        
        dateLabel.font = UIFont.omoBold(20)
    }
    
    func configure(with order: Order) {
        // Here you can set the data from order to UI elements
        productNameLabel.text = order.productName
        storeLabel.text = order.store
        dateLabel.text = order.date
        priceLabel.text = order.price
        itemCountLabel.text = order.itemCount
    }
}

