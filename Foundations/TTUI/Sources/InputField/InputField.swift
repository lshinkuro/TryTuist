//
//  InputField.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//

import Foundation
import SnapKit
import UIKit

public class InputField: UIView {

  // Elements
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 16)
    label.textColor = .black
    return label
  }()

  let passwordLabel: UILabel = {
    let label = UILabel()
    label.text = "Password"
    label.font = UIFont.systemFont(ofSize: 17)
    label.textColor = .label
    return label
  }()

  let passwordErrLabel: UILabel = {
    let label = UILabel()
    label.text = "errorLabel"
    label.font = UIFont.systemFont(ofSize: 12)
    label.textColor = UIColor(red: 0.702, green: 0.049, blue: 0.132, alpha: 1)
    return label
  }()

  let passwordView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemBackground
    view.layer.cornerRadius = 20
    return view
  }()

  public let passwordTF: UITextField = {
    let textField = UITextField()
    textField.placeholder = "password"
    textField.textAlignment = .natural
    textField.minimumFontSize = 17
    textField.font = UIFont.systemFont(ofSize: 14)
    textField.borderStyle = .none
    return textField
  }()

  // Initializer
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

    public override var intrinsicContentSize: CGSize {
    return .init(width: 350, height: 60)
  }

  // Setup UI
  private func setupUI() {
    addSubview(passwordLabel)
    addSubview(passwordView)
    addSubview(passwordErrLabel)

    passwordLabel.snp.makeConstraints { make in
      make.leading.equalToSuperview()
      make.top.equalToSuperview().offset(0)
    }

    passwordView.snp.makeConstraints { make in
      make.leading.equalToSuperview()
      make.trailing.equalToSuperview()
      make.top.equalTo(passwordLabel.snp.bottom).offset(8)
      make.height.equalTo(60)
    }

    passwordView.addSubview(passwordTF)

    passwordTF.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(15)
      make.trailing.equalToSuperview().offset(-15)
      make.centerY.equalToSuperview() // Center vertically inside passwordView
      make.height.equalTo(30)
    }

    passwordErrLabel.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(10)
      make.top.equalTo(passwordView.snp.bottom).offset(8)

    }

    passwordView.addShadow()
    passwordErrLabel.isHidden = true

  }

  // Public method to set title text
  public func setTitle(_ title: String, _ placeholder: String) {
    passwordLabel.text = title
    passwordTF.placeholder = placeholder
  }

  // Public method to get text from text field
  public func getText() -> String? {
    return passwordTF.text
  }
}
