//
//  SignUpViewModel.swift
//  AuthenticationFeature
//
//  Created by Phincon on 20/08/24.
//

import Foundation
import RxSwift
import RxCocoa
import NetworkManager
import TTUI
import Utility

internal class SignUpViewModel: BaseViewModel {
    
    var loginData = BehaviorRelay<LoginResponse?>(value: nil)
    let appService = APIManager.shared
    
    public override init() {
        super.init()
    }
    
    public func fetchLogin(param: RegisterParam) {
        loadingState.accept(.loading)
        appService.fetchRequest(endpoint: .register(param: param), expecting: BaseResponse.self) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let data):
                self.loadingState.accept(.finished)
                self.loginData.accept(data.data)
            case .failure(_):
                self.loadingState.accept(.failed)
            }
        }
    }
    
}
