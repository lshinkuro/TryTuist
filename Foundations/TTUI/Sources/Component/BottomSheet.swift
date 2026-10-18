//
//  BottomSheet.swift
//  TTUI
//
//  Bottom sheet inti aplikasi. Tingginya otomatis mengikuti isi.
//
//  3 cara pakai:
//  1. Konfigurasi standar (ikon + judul + pesan + tombol):
//       BottomSheetPresenter.present(.sessionExpired { ... }, from: controller)      // UIKit / Router
//       .bottomSheet($store.state.sheet)                                            // SwiftUI
//  2. Standar + konten tambahan di antara pesan & tombol:
//       BottomSheetView(config) { action in ... } accessory: { PromoCodeField() }
//  3. Konten bebas sepenuhnya:
//       BottomSheetPresenter.present(from: controller) { dismiss in MyCustomSheet(onClose: { dismiss(nil) }) }
//
import SwiftUI
import UIKit

// MARK: - Konfigurasi

public struct BottomSheetConfig: Identifiable {
    public enum Style {
        case info
        case success
        case warning
        case error

        public var tint: Color {
            switch self {
            case .info: return .brand
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }

        public var systemImage: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }
    }

    public struct Action {
        public enum Role {
            case primary
            case destructive
            case secondary
        }

        public let title: String
        public let role: Role
        public let handler: () -> Void

        public init(_ title: String, role: Role = .primary, handler: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.handler = handler
        }
    }

    public let id = UUID()
    public var style: Style
    public var systemImage: String
    public var tint: Color
    public var title: String
    public var message: String?
    public var primaryAction: Action
    public var secondaryAction: Action?
    /// `false` = tidak bisa ditutup dengan swipe; user wajib menekan tombol.
    public var isDismissable: Bool

    public init(style: Style = .info,
                systemImage: String? = nil,
                tint: Color? = nil,
                title: String,
                message: String? = nil,
                primaryAction: Action,
                secondaryAction: Action? = nil,
                isDismissable: Bool = true) {
        self.style = style
        self.systemImage = systemImage ?? style.systemImage
        self.tint = tint ?? style.tint
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.isDismissable = isDismissable
    }
}

// MARK: - Preset

public extension BottomSheetConfig {
    /// Sesi login habis (API 401). Tidak bisa di-swipe: user harus menekan "Mengerti".
    static func sessionExpired(title: String = String(localized: "Sesi kamu sudah habis"),
                               message: String = String(localized: "Demi keamanan akun, silakan masuk lagi untuk melanjutkan."),
                               buttonTitle: String = String(localized: "Mengerti"),
                               onConfirm: @escaping () -> Void) -> BottomSheetConfig {
        BottomSheetConfig(style: .warning,
                          systemImage: "clock.badge.exclamationmark.fill",
                          title: title,
                          message: message,
                          primaryAction: Action(buttonTitle, handler: onConfirm),
                          isDismissable: false)
    }
}

// MARK: - View standar

public struct BottomSheetView<Accessory: View>: View {
    private let config: BottomSheetConfig
    private let onAction: (BottomSheetConfig.Action) -> Void
    private let accessory: Accessory

    /// - Parameter onAction: dipanggil saat tombol ditekan. Presenter yang menutup sheet lalu menjalankan `handler`.
    public init(_ config: BottomSheetConfig,
                onAction: @escaping (BottomSheetConfig.Action) -> Void,
                @ViewBuilder accessory: () -> Accessory) {
        self.config = config
        self.onAction = onAction
        self.accessory = accessory()
    }

    public var body: some View {
        BottomSheetContainer {
            VStack(spacing: Spacing.l) {
                Image(systemName: config.systemImage)
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(config.tint)
                    .frame(width: 72, height: 72)
                    .background(config.tint.opacity(0.14), in: Circle())
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.s) {
                    Text(config.title)
                        .font(.title3.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let message = config.message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                accessory

                VStack(spacing: Spacing.xs) {
                    button(config.primaryAction)
                    if let secondary = config.secondaryAction {
                        button(secondary)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
    }

    @ViewBuilder
    private func button(_ action: BottomSheetConfig.Action) -> some View {
        switch action.role {
        case .primary:
            PrimaryButton(action.title, tint: config.tint) { onAction(action) }
        case .destructive:
            PrimaryButton(action.title, tint: .red) { onAction(action) }
        case .secondary:
            Button(action.title) { onAction(action) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

public extension BottomSheetView where Accessory == EmptyView {
    init(_ config: BottomSheetConfig, onAction: @escaping (BottomSheetConfig.Action) -> Void) {
        self.init(config, onAction: onAction) { EmptyView() }
    }
}

/// Padding & background standar. Pakai untuk bottom sheet dengan isi bebas.
public struct BottomSheetContainer<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xxl)
            .padding(.bottom, Spacing.l)
    }
}

// MARK: - UIKit presenter (dipakai Router / AppRouter)

@MainActor
public enum BottomSheetPresenter {
    /// Tampilkan bottom sheet standar. Tombol menutup sheet dulu, lalu menjalankan `handler`.
    @discardableResult
    public static func present(_ config: BottomSheetConfig, from presenter: UIViewController) -> UIViewController {
        let handle = DismissHandle()
        let controller = BottomSheetHostingController(rootView: BottomSheetView(config) { action in
            handle.dismiss { action.handler() }
        })
        handle.controller = controller
        show(controller, isDismissable: config.isDismissable, from: presenter)
        return controller
    }

    /// Tampilkan bottom sheet dengan isi bebas. Panggil `dismiss(completion)` dari dalam konten untuk menutup.
    @discardableResult
    public static func present<Content: View>(
        from presenter: UIViewController,
        isDismissable: Bool = true,
        @ViewBuilder content: (_ dismiss: @escaping (_ completion: (() -> Void)?) -> Void) -> Content
    ) -> UIViewController {
        let handle = DismissHandle()
        let controller = BottomSheetHostingController(rootView: content { completion in
            handle.dismiss(completion)
        })
        handle.controller = controller
        show(controller, isDismissable: isDismissable, from: presenter)
        return controller
    }

    /// Controller paling atas di window (melewati modal yang sedang tampil).
    public static func topController(in window: UIWindow?) -> UIViewController? {
        var top = window?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }

    private static func show<Content: View>(
        _ controller: BottomSheetHostingController<Content>,
        isDismissable: Bool,
        from presenter: UIViewController
    ) {
        controller.view.backgroundColor = .systemBackground
        controller.modalPresentationStyle = .pageSheet
        controller.isModalInPresentation = !isDismissable
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.custom(identifier: .init("fitContent")) { [weak controller] context in
                guard let controller else { return context.maximumDetentValue * 0.4 }
                let width = controller.view.bounds.width > 0 ? controller.view.bounds.width : presenter.view.bounds.width
                let fitting = controller.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height
                return min(fitting, context.maximumDetentValue)
            }]
            sheet.prefersGrabberVisible = isDismissable
            sheet.preferredCornerRadius = 28
        }
        presenter.present(controller, animated: true)
    }

    private final class DismissHandle {
        weak var controller: UIViewController?

        func dismiss(_ completion: (() -> Void)?) {
            guard let controller else {
                completion?()
                return
            }
            controller.dismiss(animated: true, completion: completion)
        }
    }
}

final class BottomSheetHostingController<Content: View>: UIHostingController<Content> {}

// MARK: - SwiftUI

public extension View {
    /// Bottom sheet standar dari State, mis. `.bottomSheet(store.binding(\.sheet, send: { .sheetChanged($0) }))`.
    /// Tombol menutup sheet (binding → nil) lalu menjalankan `handler`.
    func bottomSheet(_ config: Binding<BottomSheetConfig?>) -> some View {
        modifier(BottomSheetModifier(config: config))
    }
}

private struct BottomSheetModifier: ViewModifier {
    @Binding var config: BottomSheetConfig?
    @State private var height: CGFloat = 320

    func body(content: Content) -> some View {
        content.sheet(item: $config) { item in
            BottomSheetView(item) { action in
                config = nil
                action.handler()
            }
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(key: SheetHeightKey.self, value: proxy.size.height)
                }
            }
            .onPreferenceChange(SheetHeightKey.self) { height = $0 }
            .presentationDetents([.height(height)])
            .presentationDragIndicator(item.isDismissable ? .visible : .hidden)
            .presentationCornerRadius(28)
            .interactiveDismissDisabled(!item.isDismissable)
        }
    }
}

private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 320

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
