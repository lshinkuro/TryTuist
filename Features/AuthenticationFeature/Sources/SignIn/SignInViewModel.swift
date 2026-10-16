//
//  SignInViewModel.swift
//  AuthenticationFeature
//
//  Created by Phincon on 16/08/24.
//
import Foundation
import NetworkManager
import Utility

final class SignInViewModel: BaseViewModel {
    @Published private(set) var loginData: LoginResponse?
    private let appService = APIManager.shared

    func fetchLogin(param: LoginParam) {
        loadingState = .loading
        appService.fetchRequest(endpoint: .login(param: param), expecting: BaseResponse.self) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                if let data = response.data {
                    TokenStorage.save(data.accessToken)
                }
                self.loginData = response.data
                self.loadingState = .finished
            case .failure:
                self.loadingState = .failed
            }
        }
    }
}
