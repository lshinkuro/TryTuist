//
//  BaseViewModel.swift
//  TTUI
//
//  Created by Phincon on 19/08/24.
//

import Foundation
import RxSwift
import RxCocoa

public enum StateLoading: Int {
    case notLoad
    case loading
    case finished
    case failed
}

open class BaseViewModel {
    
    public let bag: DisposeBag = DisposeBag()
    public var loadingState = BehaviorRelay<StateLoading>(value: .notLoad)
    
    public init() {}
}

