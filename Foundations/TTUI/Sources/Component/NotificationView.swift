//
//  NotificationView.swift
//  TTUI
//
//  Created by Phincon on 29/08/24.
//

import Foundation
import UIKit
import SnapKit

public enum NotificationType {
    case success
    case error
    case neutral
}

public class NotificationView: UIView {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.omoBold(16)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.omoSemiBold(14)
        label.textColor = .lightGray
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    private let coinLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.foodBrightCoral4
        label.text = "+ 500"
        return label
    }()
    
    private let coinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "text") // Replace with your coin image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    public init(type: NotificationType, title: String, message: String) {
        super.init(frame: .zero)
        setupView(type: type, title: title, message: message)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupView(type: NotificationType, title: String, message: String) {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        if type == .neutral {
            addSubview(coinImageView)
            addSubview(coinLabel)
        }
        
        titleLabel.text = title
        messageLabel.text = message
        
        switch type {
        case .success:
            iconImageView.image = UIImage(named: "bell") // Replace with your checkmark image
            titleLabel.textColor = UIColor.foodBlack80
        case .error:
            iconImageView.image = UIImage(named: "notification") // Replace with your error image
            titleLabel.textColor = UIColor.red
        case .neutral:
            iconImageView.image = UIImage(named: "text") // Replace with your error image
            backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.5) // Neutral background
        }
        
        setupConstraints(type: type)
    }
    
    private func setupConstraints(type: NotificationType) {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(10)
        }
        
        if type == .neutral {
            coinImageView.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel.snp.leading)
                make.bottom.equalToSuperview().inset(10)
                make.width.height.equalTo(20)
            }
            
            coinLabel.snp.makeConstraints { make in
                make.leading.equalTo(coinImageView.snp.trailing).offset(5)
                make.centerY.equalTo(coinImageView)
            }
        }
    }
}

// how to use custom toast view
/*
 let customView: NotificationView = NotificationView(type: .error,
                                                     title: "Your complaint has been received",
                                                     message: "You will be notified as soon as it is processed by a moderator")

 let appleToastView = AppleToastView(child: customView)
 appleToastView.backgroundColor = .clear

 let toast = Toast.custom(view: appleToastView)
 toast.show()
 */
