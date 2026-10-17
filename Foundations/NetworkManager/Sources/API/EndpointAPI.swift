//
//  EndpointAPI.swift
//  NetworkManager
//
//  Daftar endpoint backend (Go + PostgreSQL). Kontrak lengkap ada di API_PLAN.md.
//  Base URL & API key berasal dari environment aktif (Configs/<Env>.xcconfig).
//
import Foundation
import Utility

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum EndpointAPI {
    // Auth
    case login(param: LoginParam)
    case register(param: RegisterParam)
    // User
    case profile
    // Katalog
    case banners
    case categories
    case products
    // Pesanan
    case orders

    var path: String {
        switch self {
        case .login: return "/v1/auth/login"
        case .register: return "/v1/auth/register"
        case .profile: return "/v1/me"
        case .banners: return "/v1/banners"
        case .categories: return "/v1/categories"
        case .products: return "/v1/products"
        case .orders: return "/v1/orders"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register: return .post
        case .profile, .banners, .categories, .products, .orders: return .get
        }
    }

    /// Endpoint yang butuh login → kirim `Authorization: Bearer <access_token>`.
    var requiresAuth: Bool {
        switch self {
        case .profile, .orders: return true
        case .login, .register, .banners, .categories, .products: return false
        }
    }

    var headers: [String: String] {
        var headers = [
            "X-API-Key": BaseConstant.apikey,
            "Accept": "application/json"
        ]
        if requiresAuth, let token = TokenStorage.token {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }

    var parameters: [String: Any]? {
        switch self {
        case .register(let param):
            var params: [String: Any] = [:]
            if let email = param.email { params["email"] = email }
            if let password = param.password { params["password"] = password }
            if let fcmToken = param.firebaseToken, !fcmToken.isEmpty { params["fcm_token"] = fcmToken }
            return params
        case .login(let param):
            var params: [String: Any] = ["email": param.email, "password": param.password]
            if !param.firebaseToken.isEmpty { params["fcm_token"] = param.firebaseToken }
            return params
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
        request.timeoutInterval = 30
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if method != .get, let parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
