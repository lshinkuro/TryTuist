//
//  ProfileViewController.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import UIKit
import RxSwift
import RxRelay
import TTUI
import Utility

class ProfileViewController: BaseViewController {
    
    
    // MARK: - UI Elements
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    
    let headerView = UIView()
    let greetingLabel = UILabel()
    let promoView = UIView()
    let promoTitleLabel = UILabel()
    let promoSubtitleLabel = UILabel()
    let activateButton = UIButton()
    
    let versionLabel = UILabel()
    let subVersionLable = UILabel()
    
    let quickVersiontack = UIStackView()

    
    let quickActionStack = UIStackView()
    let vouchersView = QuickActionView(title: "Vouchers", value: "1", image: UIImage(systemName: "ticket.fill"))
    let pointsView = QuickActionView(title: "TOMORO Points", value: "78 pts", image: UIImage(systemName: "clock.fill"))
    let qrCodeView = QuickActionView(title: "QR Code", value: "", image: UIImage(systemName: "qrcode"))
    
    let promotionBanner = UIImageView(image: UIImage(named: "promo_banner"))
    
    let settingsStack = UIStackView()
    let myAddressesButton = SettingsButton(title: "My Addresses", icon: UIImage(systemName: "location.fill"))
    let helpCenterButton = SettingsButton(title: "Help Center", icon: UIImage(systemName: "questionmark.circle.fill"))
    let languageButton = SettingsButton(title: "Language", icon: UIImage(systemName: "globe"))
    let termsOfServiceButton = SettingsButton(title: "Terms of Services", icon: UIImage(systemName: "doc.text.fill"))
    let privacyPolicyButton = SettingsButton(title: "Privacy Policy", icon: UIImage(systemName: "lock.fill"))
    let settingsButton = SettingsButton(title: "Settings", icon: UIImage(systemName: "gearshape.fill"))
    
    weak var coordinator: ProfileCoordinator!
    
    init(coordinator: ProfileCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: "ProfileViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        view.backgroundColor = .white
        
        // Add ScrollView and ContentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.contentInsetAdjustmentBehavior = .never
        
        // ScrollView Layout
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // ContentView Layout
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Add subviews to contentView
        contentView.addSubview(headerView)
        headerView.addSubview(greetingLabel)
        headerView.addSubview(promoView)
        promoView.addSubview(promoTitleLabel)
        promoView.addSubview(promoSubtitleLabel)
        promoView.addSubview(activateButton)
        
        contentView.addSubview(quickActionStack)
        contentView.addSubview(promotionBanner)
        contentView.addSubview(settingsStack)
        contentView.addSubview(quickVersiontack)
        
        // Header View Layout
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(200)
        }
        
        greetingLabel.text = "Hi, Ishinkuro"
        greetingLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        greetingLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.equalToSuperview().offset(16)
        }
        
        promoView.backgroundColor = .black
        promoView.layer.cornerRadius = 10
        promoView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(greetingLabel.snp.bottom).offset(8)
            make.height.equalTo(100)
        }
        
        promoTitleLabel.text = "DAILY COFFEE HAPPINESS"
        promoTitleLabel.textColor = .white
        promoTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        promoTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        promoSubtitleLabel.text = "Weekly | 1 Cup Only 15K"
        promoSubtitleLabel.textColor = .white
        promoSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(promoTitleLabel)
            make.top.equalTo(promoTitleLabel.snp.bottom).offset(8)
        }
        
        activateButton.setTitle("Activate", for: .normal)
        activateButton.backgroundColor = .systemYellow
        activateButton.layer.cornerRadius = 10
        activateButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(40)
        }
        
        activateButton.addTapGestureAction {
            self.quickActionStack.swap(self.vouchersView, self.pointsView)
        }
        
        // Quick Actions
        quickActionStack.axis = .horizontal
        quickActionStack.distribution = .fillEqually
        quickActionStack.addArrangedSubview(vouchersView)
        quickActionStack.addArrangedSubview(pointsView)
        quickActionStack.addArrangedSubview(qrCodeView)
        quickActionStack.snp.makeConstraints { make in
            make.top.equalTo(promoView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(80)
        }
        
        // Promotion Banner
        promotionBanner.contentMode = .scaleAspectFill
        promotionBanner.snp.makeConstraints { make in
            make.top.equalTo(quickActionStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
        
        // Settings Stack
        settingsStack.axis = .vertical
        settingsStack.spacing = 8
        settingsStack.addArrangedSubview(myAddressesButton)
        settingsStack.addArrangedSubview(helpCenterButton)
        settingsStack.addArrangedSubview(languageButton)
        settingsStack.addArrangedSubview(termsOfServiceButton)
        settingsStack.addArrangedSubview(privacyPolicyButton)
        settingsStack.addArrangedSubview(settingsButton)
        settingsStack.snp.makeConstraints { make in
            make.top.equalTo(promotionBanner.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        
        versionLabel.text = "version 1.2.0"
        subVersionLable.text = "app.com.contol"
        quickVersiontack.addArrangedSubview(versionLabel)
        quickVersiontack.addArrangedSubview(subVersionLable)
        quickVersiontack.axis = .vertical
        quickVersiontack.spacing = 8
        quickVersiontack.alignment = .center
        quickVersiontack.snp.makeConstraints { make in
            make.top.equalTo(settingsStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(60)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
}

class QuickActionView: UIView {
    
    let titleLabel = UILabel()
    let valueLabel = UILabel()
    let imageView = UIImageView()
    
    init(title: String, value: String, image: UIImage?) {
        super.init(frame: .zero)
        setupView(title: title, value: value, image: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String, value: String, image: UIImage?) {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        
        imageView.image = image?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 28, height: 28))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
        }
        
     

    }
}

class SettingsButton: UIButton {
    
    init(title: String, icon: UIImage?) {
        super.init(frame: .zero)
        setupView(title: title, icon: icon)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String, icon: UIImage?) {
        setTitle(title, for: .normal)
        setTitleColor(.black, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        setImage(icon, for: .normal)
        contentHorizontalAlignment = .left
        backgroundColor = .white
        layer.cornerRadius = 10
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 0)
        snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
}

