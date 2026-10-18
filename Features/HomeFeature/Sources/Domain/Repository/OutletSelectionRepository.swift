//
//  OutletSelectionRepository.swift
//  HomeFeature · Domain
//
//  Outlet yang dipilih user. Bersama untuk Beranda, Menu, dan Keranjang; diingat antar-launch.
//
import Combine
import Foundation

@MainActor
protocol OutletSelectionRepository: AnyObject {
    var selected: Outlet? { get }
    /// Id outlet terakhir yang dipilih (tetap ada walau data outlet belum dimuat).
    var savedOutletID: String? { get }
    var selectedPublisher: AnyPublisher<Outlet?, Never> { get }

    func select(_ outlet: Outlet)
}
