//
//  ScreenTracker.swift
//  Navigation
//
//  Mencatat screen yang tampil (dipanggil HostingController.viewDidAppear) dan
//  membaca hierarki layar saat ini. Dipakai Debugger untuk tab "Layar".
//
import SwiftUI
import UIKit

/// Controller yang bisa menyebut nama screen-nya sendiri (mis. "HomeView").
public protocol ScreenNameProviding {
    var screenName: String { get }
}

public struct ScreenVisit: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let date: Date
}

/// Satu baris hierarki, mis. "Tab Beranda" › "HomeView" › "Modal: CartView".
public struct ScreenNode: Identifiable, Equatable {
    public enum Kind: Equatable {
        case window
        case tab(index: Int, count: Int)
        case stack(depth: Int)
        case modal
    }

    public let id = UUID()
    public let kind: Kind
    public let name: String
    public let isVisible: Bool
}

@MainActor
public final class ScreenTracker: ObservableObject {
    public static let shared = ScreenTracker()

    /// Terbaru di atas.
    @Published public private(set) var history: [ScreenVisit] = []
    public var maxHistory = 60

    private init() {}

    public var currentScreen: String? { history.first?.name }

    func didAppear(_ name: String) {
        guard history.first?.name != name else { return }
        history.insert(ScreenVisit(name: name, date: Date()), at: 0)
        if history.count > maxHistory {
            history.removeLast(history.count - maxHistory)
        }
    }

    public func clear() {
        history.removeAll()
    }

    // MARK: - Hierarki

    /// Membaca hierarki dari root window: tab aktif → stack navigasi → modal.
    public static func hierarchy(of window: UIWindow?) -> [ScreenNode] {
        guard let root = window?.rootViewController else { return [] }
        var nodes: [ScreenNode] = []
        walk(root, into: &nodes)
        // Rantai modal dibaca dari root saja (child ikut melaporkan modal yang sama).
        var presenter = root
        while let presented = presenter.presentedViewController, !(presented is DebugOverlayMarker) {
            walk(presented, into: &nodes, isModal: true)
            presenter = presented
        }
        guard let last = nodes.lastIndex(where: { node in
            if case .tab = node.kind { return false }
            return true
        }) else { return nodes }
        // Tandai screen paling atas sebagai yang sedang terlihat.
        nodes[last] = ScreenNode(kind: nodes[last].kind, name: nodes[last].name, isVisible: true)
        return nodes
    }

    public static func name(of controller: UIViewController) -> String {
        if let named = controller as? ScreenNameProviding { return named.screenName }
        return String(describing: type(of: controller))
    }

    private static func walk(_ controller: UIViewController, into nodes: inout [ScreenNode], isModal: Bool = false) {
        switch controller {
        case let tab as UITabBarController:
            let items = tab.viewControllers ?? []
            let index = tab.selectedIndex
            let title = tab.selectedViewController?.tabBarItem.title ?? "#\(index + 1)"
            nodes.append(ScreenNode(kind: .tab(index: index, count: items.count),
                                    name: "\(isModal ? "Modal · " : "")Tab \(title)", isVisible: false))
            if let selected = tab.selectedViewController {
                walk(selected, into: &nodes)
            }
        case let nav as UINavigationController:
            for (depth, child) in nav.viewControllers.enumerated() {
                let prefix = isModal && depth == 0 ? "Modal · " : ""
                nodes.append(ScreenNode(kind: isModal && depth == 0 ? .modal : .stack(depth: depth),
                                        name: prefix + name(of: child), isVisible: false))
            }
        default:
            nodes.append(ScreenNode(kind: isModal ? .modal : .window,
                                    name: (isModal ? "Modal · " : "") + name(of: controller), isVisible: false))
        }

    }

    /// Nama tipe SwiftUI yang ringkas: `ModifiedContent<HomeView, …>` → "HomeView".
    nonisolated static func readableName<Content>(of type: Content.Type) -> String {
        var text = String(describing: type)
        while text.hasPrefix("ModifiedContent<") {
            text.removeFirst("ModifiedContent<".count)
        }
        if let end = text.firstIndex(where: { $0 == "<" || $0 == "," || $0 == ">" }) {
            text = String(text[..<end])
        }
        return text
    }
}

/// Ditempel pada controller Debugger supaya tidak ikut terbaca sebagai screen app.
public protocol DebugOverlayMarker {}
