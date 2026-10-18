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
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum EndpointAPI {
    // Auth
    case login(param: LoginParam)
    case register(param: RegisterParam)
    /// Daftar & masuk dengan Google (satu endpoint).
    case googleSignIn(param: GoogleSignInParam)
    /// Perbarui access token (dipanggil otomatis oleh TokenRefresher, bukan oleh feature).
    case refreshToken(refreshToken: String)
    // User / Profil
    case profile
    case updateProfile(param: UpdateProfileParam)
    case addresses
    case createAddress(param: AddressParam)
    case updateAddress(id: String, param: AddressParam)
    case deleteAddress(id: String)
    case paymentMethods
    case addEWallet(param: AddEWalletParam)
    case setDefaultPaymentMethod(id: String)
    case deletePaymentMethod(id: String)
    // Konten (publik)
    case helpCenter(query: String?)
    case legalDocument(slug: String)
    // Katalog
    case banners
    case categories
    case products
    /// Popup promo harga produk di Beranda (`data: null` bila tidak ada).
    case popupPromotion
    // Pesanan
    case orders
    case createOrder(param: CreateOrderParam, idempotencyKey: String)

    var path: String {
        switch self {
        case .login: return "/v1/auth/login"
        case .register: return "/v1/auth/register"
        case .googleSignIn: return "/v1/auth/google"
        case .refreshToken: return "/v1/auth/refresh"
        case .profile, .updateProfile: return "/v1/me"
        case .addresses, .createAddress: return "/v1/me/addresses"
        case .updateAddress(let id, _), .deleteAddress(let id): return "/v1/me/addresses/\(Self.escape(id))"
        case .paymentMethods, .addEWallet: return "/v1/me/payment-methods"
        case .setDefaultPaymentMethod: return "/v1/me/payment-methods/default"
        case .deletePaymentMethod(let id): return "/v1/me/payment-methods/\(Self.escape(id))"
        case .helpCenter: return "/v1/help"
        case .legalDocument(let slug): return "/v1/legal/\(Self.escape(slug))"
        case .banners: return "/v1/banners"
        case .categories: return "/v1/categories"
        case .products: return "/v1/products"
        case .popupPromotion: return "/v1/promotions/popup"
        case .orders, .createOrder: return "/v1/orders"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .googleSignIn, .refreshToken, .createOrder, .createAddress, .addEWallet: return .post
        case .setDefaultPaymentMethod: return .put
        case .updateProfile, .updateAddress: return .patch
        case .deleteAddress, .deletePaymentMethod: return .delete
        case .profile, .banners, .categories, .products, .popupPromotion, .orders,
             .addresses, .paymentMethods, .helpCenter, .legalDocument: return .get
        }
    }

    /// Endpoint yang butuh login → kirim `Authorization: Bearer <access_token>`.
    var requiresAuth: Bool {
        switch self {
        case .profile, .orders, .createOrder,
             .updateProfile, .addresses, .createAddress, .updateAddress, .deleteAddress,
             .paymentMethods, .addEWallet, .setDefaultPaymentMethod, .deletePaymentMethod: return true
        case .login, .register, .googleSignIn, .refreshToken, .banners, .categories, .products, .popupPromotion,
             .helpCenter, .legalDocument: return false
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
        if case .createOrder(_, let idempotencyKey) = self {
            // Retry dengan key yang sama tidak membuat pesanan ganda.
            headers["Idempotency-Key"] = idempotencyKey
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
        case .googleSignIn(let param):
            var params: [String: Any] = ["id_token": param.idToken]
            if !param.firebaseToken.isEmpty { params["fcm_token"] = param.firebaseToken }
            return params
        case .refreshToken(let refreshToken):
            return ["refresh_token": refreshToken]
        case .createOrder(let param, _):
            return param.body
        case .updateProfile(let param):
            return param.body
        case .createAddress(let param), .updateAddress(_, let param):
            return param.body
        case .addEWallet(let param):
            return param.body
        case .setDefaultPaymentMethod(let id):
            return ["id": id]
        case .helpCenter(let query):
            guard let query, !query.isEmpty else { return nil }
            return ["q": query]
        default:
            return nil
        }
    }

    /// Id dari server dipakai di path; pastikan tidak bisa menyisipkan "/" atau query.
    private static func escape(_ component: String) -> String {
        component.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-_"))) ?? component
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
