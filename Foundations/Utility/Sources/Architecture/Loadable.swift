//
//  Loadable.swift
//  Utility
//
//  Status data async yang dipakai di State: belum dimuat, memuat, berhasil, gagal.
//
import Foundation

public enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    public var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

extension Loadable: Equatable where Value: Equatable {}
