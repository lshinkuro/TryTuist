//
//  CategoryResponse.swift
//  AuthenticationFeature
//
//  Created by Phincon on 19/08/24.
//

import Foundation

public struct CategoryResponse: Codable {
    public let meta: Meta
    public let data: CategoryData
    
    enum CodingKeys: String, CodingKey {
        case meta
        case data
    }
}

public struct Meta: Codable {
    public let code: Int
    public let status, message: String
    
    enum CodingKeys: String, CodingKey {
        case code
        case status, message
    }
}

// MARK: - DataClass
public struct CategoryData: Codable {
    public let data: [CategoryModel]
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

public struct CategoryModel: Codable, Hashable {
    public let id: Int
    public let name: String
    
    // Custom implementation of the equality operator
    public static func == (lhs: CategoryModel, rhs: CategoryModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Implementation of the hash(into:) method
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
