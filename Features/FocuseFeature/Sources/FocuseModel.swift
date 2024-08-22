//
//  FocuseModel.swift
//  AuthenticationFeature
//
//  Created by Phincon on 21/08/24.
//

import Foundation
// MARK: - Order Model

enum TypeSegment: String, CaseIterable {
    case store = "Store"
    case voucher = "Voucher Pack"
}

struct Order {
    let store: String
    let date: String
    let productName: String
    let price: String
    let itemCount: String
}

var orders: [Order] = [
    Order(store: "Gandaria City", date: "20/08/2024 12:46", productName: "TOMORO Oat Latte", price: "Rp 15.000", itemCount: "1 Item"),
    Order(store: "Gandaria City", date: "20/08/2024 12:44", productName: "Choco Oat Latte", price: "Rp 15.000", itemCount: "1 Item"),
    Order(store: "Gandaria City", date: "07/08/2024 12:21", productName: "Breve Latte", price: "Rp 9.000", itemCount: "1 Item")
]

var vouchers: [Order] = [
    Order(store: "Kemang Utara", date: "20/08/2024 12:46", productName: "TOMORO Oat Latte", price: "Rp 15.000", itemCount: "1 Item"),
    Order(store: "Gandaria City", date: "20/08/2024 12:44", productName: "Choco Oat Latte", price: "Rp 15.000", itemCount: "1 Item")
]


