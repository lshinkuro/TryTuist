//
//  Banner.swift
//  HomeFeature · Domain
//
import Foundation

struct Banner: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
}
