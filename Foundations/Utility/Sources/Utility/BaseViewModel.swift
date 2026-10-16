//
//  BaseViewModel.swift
//  TTUI
//
//  Created by Phincon on 19/08/24.
//
import Foundation
import Combine

public enum StateLoading: Int {
    case notLoad
    case loading
    case finished
    case failed
}

/// Base view model yang di-observe langsung oleh SwiftUI view.
open class BaseViewModel: ObservableObject {
    @Published public var loadingState: StateLoading = .notLoad

    public init() {}
}
