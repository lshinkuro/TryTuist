//
//  Order.swift
//  FocuseFeature · Domain
//
import Foundation

enum OrderStatus: CaseIterable, Equatable {
    case pending
    case completed
    case failed
}

struct Order: Identifiable, Equatable {
    let id: String
    let storeName: String
    let productName: String
    let createdAt: Date
    let totalPrice: Decimal
    let quantity: Int
    let status: OrderStatus
}
