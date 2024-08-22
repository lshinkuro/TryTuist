//
//  EndpointAPI.swift
//  AuthenticationFeature
//
//  Created by Phincon on 19/08/24.
//

import Foundation
import Alamofire
import TTUI

public enum EndpointAPI {
    case login(param: LoginParam)
    case register(param: RegisterParam)
    case profile
    case categories
    case products
    
    var path: String {
        switch self {
        case .login: return "/login"
        case .register: return "/register"
        case .categories: return "/categories"
        case .products: return "/products"
        case .profile: return "/profile"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register: return .post
        case .categories, .products: return .get
        default:
            return .post
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        case .login, 
             .register:
             return [
                "API_KEY": BaseConstant.apikey,
                "Content-Type": "application/json"
            ]
        case .categories, .products: return .default
        default:
            return .default
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .categories, .products:
            return URLEncoding.queryString
        default:
            return JSONEncoding.default
        }
    }
    
    var queryParams: [String: Any]? {
        switch self {
        case .register(let param):
            var params: [String: Any] = [
                :]
            
            if let email = param.email { params["email"] = email }
            if let password = param.password { params["password"] = password }
            if let firebaseToken = param.firebaseToken { params["firebaseToken"] = firebaseToken }
            
            return params
        case .login(let param):
            let params: [String: Any] = [
                "email": param.email,
                "password": param.password,
                "firebaseToken": param.firebaseToken
            ]
            return params
        default:
            return nil
        }
    }
    
    var urlString: String {
        return BaseConstant.baseUrl + path
    }

}
