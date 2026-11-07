//
//  OrderActivityAttributes.swift
//  Utility
//
//  Live Activity status pesanan (Lock Screen & Dynamic Island).
//  File ini juga dikompilasi ke target Widget (lihat Project.swift), jadi hanya boleh import ActivityKit.
//
import ActivityKit
import Foundation

public struct OrderActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 0 Diterima, 1 Diproses, 2 Diantar, 3 Selesai.
        public var step: Int
        /// Sudah diterjemahkan app, mis. "Sedang diantar".
        public var title: String
        /// Batas akhir estimasi tiba; `nil` = belum ada estimasi.
        public var arrivalEnd: Date?

        public init(step: Int, title: String, arrivalEnd: Date? = nil) {
            self.step = step
            self.title = title
            self.arrivalEnd = arrivalEnd
        }
    }

    public let orderID: String
    public let orderNumber: String
    public let storeName: String?

    public init(orderID: String, orderNumber: String, storeName: String?) {
        self.orderID = orderID
        self.orderNumber = orderNumber
        self.storeName = storeName
    }
}
