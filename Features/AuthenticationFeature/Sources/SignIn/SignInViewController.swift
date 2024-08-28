//
//  SignInViewController.swift
//  TTUI
//
//  Created by Phincon on 13/08/24.
//

import UIKit
import TTUI
import RxSwift
import RxCocoa
import NetworkManager
import Utility
//import Alamofire

public class SignInViewController: BaseViewController {
    
    let formView: FormView = {
        let fvw = FormView()
        return fvw
    }()
    
    let signButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Login", for: .normal)
        btn.layer.cornerRadius = 20
        btn.backgroundColor = UIColor.foodBrightBlue
        return btn
    }()
    
    let signUpLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "belum punya Akun ?"
        lbl.textAlignment = .center
        return lbl
    }()
    
    let signUpButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("Sign Up", for: .normal)
        btn.titleLabel?.tintColor = UIColor.foodBrightBlue
        btn.setTitleColor(UIColor.foodBrightBlue, for: .normal)
        return btn
    }()
    
    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Login Aplikasi"
        lbl.textAlignment = .center
        return lbl
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        return stackView
    }()
    
    let nameField = InputField()
    let passwordField = InputField()
    
    weak var coordinator: SignInCoordinator!
    let vm = SignInViewModel()
    var name = "kholis"
    var password = ""
    
    // MARK: used if screen using NIB file
    init(coordinator: SignInCoordinator!) {
        self.coordinator = coordinator
        super.init(nibName: "SignInViewController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func configView() {
        super.configView()
        setupView()
        setupViewConstraint()
        
        signButton.rx.tap.subscribe(onNext:  { [weak self] _ in
            guard let self = self else { return }
            let email = nameField.getText()
            let password = passwordField.getText()
            let param = LoginParam(email: email ?? "", password: password ?? "")
            vm.fetchLogin(param: param )
        }).disposed(by: disposeBag)
        
        signUpButton.rx.tap.subscribe(onNext:  { [weak self] _ in
            guard let self = self else { return }
            self.coordinator.goToSignUp()
        }).disposed(by: disposeBag)
        
    }
    
    public override func bindingData() {
        nameField.passwordTF.text = name
        passwordField.passwordTF.text = password

        super.bindingData()
        
        vm.loginData.asObservable().subscribe(onNext: { [weak self] result in
            guard let self = self, let validData = result else { return }
            self.storeToken(with: validData.accessToken)
        }).disposed(by: disposeBag)
        
        vm.loadingState.asObservable().subscribe(onNext: {[weak self] state in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch state {
                case .notLoad:
                    self.afterDissmissed(self.signButton, title: "Sign In")
                case .loading:
                    self.addLoading(self.signButton)
                case .failed:
                    self.afterDissmissed(self.signButton, title: "Sign In")
                case .finished:
                    self.afterDissmissed(self.signButton, title: "Sign In")
                    self.displayAlert(title: "sukses", message: "Please Sign In to continue", completion:  {
                        self.coordinator.goToDashboard()
                    })
                }
            }
        }).disposed(by: disposeBag)
        
    }
    
    func setupView() {
        nameField.setTitle("UserName", "masukan nama")
    }
    
    func setupViewConstraint() {
        view.addSubview(formView)
        formView.add(titleLabel, nameField, passwordField,signButton, stackView)
        stackView.addArrange(signUpLabel, signUpButton)

        
        formView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(15)
            make.height.equalTo(80)
        }
        
        nameField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.height.equalTo(80)
        }
        
        passwordField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(nameField.snp.bottom).offset(20)
            make.height.equalTo(80)
        }
        
        signButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(passwordField.snp.bottom).offset(50)
            make.height.equalTo(40)
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(signButton.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }
        
    }
}
