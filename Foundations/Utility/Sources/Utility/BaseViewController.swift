//
//  BaseViewController.swift
//  TTUI
//
//  Created by Phincon on 13/08/24.
//

import Foundation
import UIKit
import RxSwift

open class BaseViewController: UIViewController {
    
    public let disposeBag = DisposeBag()
    public let activityIndicator = UIActivityIndicatorView(style: .medium)

    
    open override func viewDidLoad() {
        super.viewDidLoad()
        configView()
        bindingData()
    }
    
    open func configView() {}
    
    open func bindingData() {}
    
}


public extension BaseViewController {
    func validateEmail(candidate: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: candidate)
    }
    
    func validatePassword(candidate: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: candidate)
    }
    
    func displayAlert(title: String, message: String, action: (() -> UIAlertAction)? = nil, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        if let anotherAction = action {
            alertController.addAction(anotherAction())
        }
        present(alertController, animated: true, completion: nil)
    }
    
    func addLoading(_ button: UIButton) {
        button.isEnabled = false
        button.isUserInteractionEnabled = false
        button.layer.backgroundColor = UIColor.systemGray5.cgColor
        activityIndicator.center = CGPoint(x: button.bounds.width / 2 , y: button.bounds.height / 2)
        button.addSubview(activityIndicator)
        button.setTitle("", for: .disabled)
        activityIndicator.startAnimating()
    }
    
    func afterDissmissed(_ button: UIButton, title: String) {
        activityIndicator.stopAnimating()
        button.isEnabled = true
        button.isUserInteractionEnabled = true
        button.layer.backgroundColor = UIColor.systemBlue.cgColor
        button.setTitle(title, for: .normal)
    }
}

public extension BaseViewController {
    func storeToken(with token: String) {
        // Prepare the data to be stored (your authentication token)
        let tokenData = token.data(using: .utf8)
        
        // Create a dictionary to specify the keychain item attributes
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "AuthToken",
            kSecValueData: tokenData!,
        ]
        
        // Add the item to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("Token saved to Keychain")
        } else {
            print("Failed to save token to Keychain")
        }
    }
    
    func isTokenExistInKeychain() -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "AuthToken",
            kSecReturnData: kCFBooleanTrue as Any,
        ]
        
        var tokenData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &tokenData)
        
        return status == errSecSuccess ? true : false
    }
    
    func deleteToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: "AuthToken",
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("Token deleted from Keychain")
        } else {
            print("Failed to delete token from Keychain")
        }
    }
}
