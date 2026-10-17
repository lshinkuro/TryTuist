//
//  OrderParam.swift
//  NetworkManager
//
//  Body untuk `POST /v1/orders` (lihat API_PLAN.md §5.11). Field opsional yang nil tidak dikirim.
//
import Foundation

public struct CreateOrderParam {
    public struct Item {
        public let productID: String
        public let optionID: String?
        public let quantity: Int
        public let note: String

        public init(productID: String, optionID: String?, quantity: Int, note: String) {
            self.productID = productID
            self.optionID = optionID
            self.quantity = quantity
            self.note = note
        }
    }

    /// nil = outlet default dari server.
    public let storeID: String?
    /// Tipe (COD/QRIS/EWALLET). Boleh nil bila `paymentMethodID` diisi.
    public let paymentMethod: String?
    /// "COD" | "QRIS" | uuid e-wallet tersimpan. nil + `paymentMethod` nil = metode utama user.
    public let paymentMethodID: String?
    /// nil = alamat utama user.
    public let addressID: String?
    public let items: [Item]
    public let note: String?

    public init(storeID: String? = nil,
                paymentMethod: String? = nil,
                paymentMethodID: String? = nil,
                addressID: String? = nil,
                items: [Item],
                note: String? = nil) {
        self.storeID = storeID
        self.paymentMethod = paymentMethod
        self.paymentMethodID = paymentMethodID
        self.addressID = addressID
        self.items = items
        self.note = note
    }

    var body: [String: Any] {
        var body: [String: Any] = [
            "items": items.map { item -> [String: Any] in
                var dict: [String: Any] = [
                    "product_id": item.productID,
                    "quantity": item.quantity,
                    "note": item.note
                ]
                dict["option_id"] = item.optionID.map { $0 as Any } ?? NSNull()
                return dict
            }
        ]
        if let storeID { body["store_id"] = storeID }
        if let paymentMethod { body["payment_method"] = paymentMethod }
        if let paymentMethodID { body["payment_method_id"] = paymentMethodID }
        if let addressID { body["address_id"] = addressID }
        if let note, !note.isEmpty { body["note"] = note }
        return body
    }
}
