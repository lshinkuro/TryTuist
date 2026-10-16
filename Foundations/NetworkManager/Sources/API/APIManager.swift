//
//  APIManager.swift
//  AuthenticationFeature
//
//  Created by Phincon on 19/08/24.
//

import Foundation

public final class APIManager {
    public static let shared = APIManager()
    private let session: URLSession
    private let decoder = JSONDecoder()

    private init(session: URLSession = .shared) {
        self.session = session
    }

    public enum APIError: Error {
        case failedToCreateRequest
        case failedToGetData
        case invalidStatusCode(Int)
    }
}

public extension APIManager {
    /// Request generik berbasis URLSession. Completion selalu dipanggil di main thread.
    func fetchRequest<T: Decodable>(endpoint: EndpointAPI,
                                    expecting type: T.Type,
                                    completion: @escaping (Result<T, Error>) -> Void) {
        let finish: (Result<T, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }

        let request: URLRequest
        do {
            request = try endpoint.makeRequest()
        } catch {
            finish(.failure(error))
            return
        }

        session.dataTask(with: request) { [decoder] data, response, error in
            if let error {
                finish(.failure(error))
                return
            }
            // Setara dengan `.validate()` Alamofire: hanya status 2xx yang sukses.
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                finish(.failure(APIError.invalidStatusCode(http.statusCode)))
                return
            }
            guard let data else {
                finish(.failure(APIError.failedToGetData))
                return
            }
            do {
                finish(.success(try decoder.decode(T.self, from: data)))
            } catch {
                finish(.failure(error))
            }
        }.resume()
    }
}
