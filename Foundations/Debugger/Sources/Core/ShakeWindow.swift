//
//  ShakeWindow.swift
//  Debugger
//
//  UIWindow yang membuka Debugger saat device di-shake.
//  Pakai di SceneDelegate: `let window = ShakeWindow(windowScene: windowScene)`.
//  Di build Prod tidak melakukan apa pun.
//
import UIKit
import Utility

public final class ShakeWindow: UIWindow {
    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake, AppEnvironment.isDebugToolsEnabled {
            DebugMenu.shared.toggle(in: self)
        }
        super.motionEnded(motion, with: event)
    }
}
