//
//  ShakeWindow.swift
//  Debugger
//
//  UIWindow yang membuka Debugger saat device di-shake, atau lewat tombol 🐞 mengambang
//  (device hub / remote device tidak bisa shake). Tombol bisa digeser dan menempel ke tepi.
//  Pakai di SceneDelegate: `let window = ShakeWindow(windowScene: windowScene)`.
//  Di build Prod tidak melakukan apa pun.
//
import UIKit
import Utility

public final class ShakeWindow: UIWindow {
    private static let buttonSize: CGFloat = 44
    private static let edgeInset: CGFloat = 8

    private lazy var debugButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "ladybug.fill")
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.6)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }
            DebugMenu.shared.toggle(in: self)
        })
        button.frame.size = CGSize(width: Self.buttonSize, height: Self.buttonSize)
        button.alpha = 0.8
        button.accessibilityLabel = "Buka Debugger"
        button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragButton(_:))))
        return button
    }()
    private var hasPlacedButton = false

    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        if AppEnvironment.isDebugToolsEnabled { addSubview(debugButton) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) tidak dipakai") }

    public override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake, AppEnvironment.isDebugToolsEnabled {
            DebugMenu.shared.toggle(in: self)
        }
        super.motionEnded(motion, with: event)
    }

    // Root view & sheet yang tampil ditambahkan sebagai subview window → tombol selalu dinaikkan ke atas.
    public override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if subview !== debugButton, debugButton.superview === self { bringSubviewToFront(debugButton) }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard debugButton.superview === self else { return }
        if !hasPlacedButton, bounds.width > 0 {
            hasPlacedButton = true
            debugButton.center = CGPoint(x: bounds.maxX, y: bounds.midY + 120)
        }
        debugButton.center = snapped(debugButton.center)   // rotasi / ukuran window berubah
    }

    @objc private func dragButton(_ pan: UIPanGestureRecognizer) {
        let move = pan.translation(in: self)
        debugButton.center = CGPoint(x: debugButton.center.x + move.x, y: debugButton.center.y + move.y)
        pan.setTranslation(.zero, in: self)
        if pan.state == .ended || pan.state == .cancelled {
            UIView.animate(withDuration: 0.25) { self.debugButton.center = self.snapped(self.debugButton.center) }
        }
    }

    /// Menempel ke tepi kiri/kanan terdekat, tetap di dalam safe area.
    private func snapped(_ point: CGPoint) -> CGPoint {
        let area = bounds.inset(by: safeAreaInsets).insetBy(dx: Self.edgeInset, dy: Self.edgeInset)
        let half = Self.buttonSize / 2
        let x = point.x < bounds.midX ? area.minX + half : area.maxX - half
        let y = min(max(point.y, area.minY + half), area.maxY - half)
        return CGPoint(x: x, y: y)
    }
}
