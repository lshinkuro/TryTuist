//
//  DebugMenu.swift
//  Debugger
//
//  Pintu masuk Debugger. Muncul saat device di-shake (lihat ShakeWindow).
//  Simulator: menu Device ▸ Shake (⌃⌘Z).
//
//  App (AppRouter) mengisi:
//  - `shortcutsProvider` → daftar shortcut navigasi ke fitur.
//  - `onServerChanged`   → apa yang dilakukan setelah server API diganti (mis. restart ke Splash).
//
import SwiftUI
import UIKit
import Navigation
import Utility

@MainActor
public final class DebugMenu {
    public static let shared = DebugMenu()

    /// Dipanggil setiap Debugger dibuka, supaya shortcut mengikuti state app saat itu.
    public var shortcutsProvider: () -> [DebugShortcutSection] = { [] }
    /// Dipanggil setelah konfigurasi server disimpan & Debugger tertutup.
    public var onServerChanged: () -> Void = {}

    private weak var presentedController: UIViewController?

    private init() {}

    public var isPresented: Bool { presentedController != nil }

    public func toggle(in window: UIWindow) {
        isPresented ? dismiss() : show(in: window)
    }

    public func show(in window: UIWindow) {
        guard AppEnvironment.isDebugToolsEnabled, !isPresented, let root = window.rootViewController else { return }

        // Snapshot hierarki diambil SEBELUM Debugger tampil, supaya yang terbaca adalah layar app.
        let store = DebuggerStore(hierarchy: ScreenTracker.hierarchy(of: window),
                                  shortcuts: shortcutsProvider())
        store.onRoute = { [weak self] route in
            switch route {
            case .close:
                self?.dismiss()
            case .run(let shortcut):
                self?.dismiss { shortcut.action() }
            case .serverChanged:
                self?.dismiss { self?.onServerChanged() }
            }
        }

        let controller = DebugHostingController(rootView: DebuggerView(store: store))
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large(), .medium()]
            sheet.prefersGrabberVisible = true
        }
        topController(from: root).present(controller, animated: true)
        presentedController = controller

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    public func dismiss(then action: (() -> Void)? = nil) {
        guard let controller = presentedController else {
            action?()
            return
        }
        presentedController = nil
        controller.dismiss(animated: true) { action?() }
    }

    private func topController(from root: UIViewController) -> UIViewController {
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

/// Controller Debugger. `DebugOverlayMarker` = tidak ikut terbaca sebagai screen app.
final class DebugHostingController<Content: View>: UIHostingController<Content>, DebugOverlayMarker {}
