//
//  EndpointAPI.swift
//  AuthenticationFeature
//
//  Created by Phincon on 19/08/24.
//

import Foundation
import Utility

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

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
        case .categories, .products: return .get
        case .login, .register, .profile: return .post
        }
    }

    var headers: [String: String] {
        switch self {
        case .login, .register:
            return [
                "API_KEY": BaseConstant.apikey,
                "Content-Type": "application/json"
            ]
        default:
            return [:]
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .register(let param):
            var params: [String: Any] = [:]
            if let email = param.email { params["email"] = email }
            if let password = param.password { params["password"] = password }
            if let firebaseToken = param.firebaseToken { params["firebaseToken"] = firebaseToken }
            return params
        case .login(let param):
            return [
                "email": param.email,
                "password": param.password,
                "firebaseToken": param.firebaseToken
            ]
        default:
            return nil
        }
    }

    var urlString: String {
        BaseConstant.baseUrl + path
    }

    /// GET -> parameter jadi query string, selain itu -> JSON body.
    func makeRequest() throws -> URLRequest {
        guard var components = URLComponents(string: urlString) else {
            throw APIManager.APIError.failedToCreateRequest
        }
        if method == .get, let parameters {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        guard let url = components.url else {
            throw APIManager.APIError.failedToCreateRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if method != .get, let parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
