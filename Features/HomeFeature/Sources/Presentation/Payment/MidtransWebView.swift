//
//  MidtransWebView.swift
//  HomeFeature · Presentation
//
//  Halaman Snap Midtrans (redirect_url) di WKWebView.
//  - URL berawalan `finishURLPrefix` → dicegat, `onFinish` dipanggil (status dicek ke server).
//  - Scheme selain http/https (gojek://, shopeeid://, aplikasi bank) → dibuka di aplikasinya.
//  - Tidak menyuntikkan JavaScript ke halaman Snap (larangan Midtrans), cookie tidak disimpan.
//
import SwiftUI
import UIKit
import WebKit

struct MidtransWebView: UIViewRepresentable {
    let url: URL
    let finishURLPrefix: String?
    let onFinish: () -> Void
    var onLoadingChange: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(finishURLPrefix: finishURLPrefix, onFinish: onFinish, onLoadingChange: onLoadingChange)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onFinish = onFinish
        context.coordinator.onLoadingChange = onLoadingChange
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let finishURLPrefix: String?
        var onFinish: () -> Void
        var onLoadingChange: (Bool) -> Void
        private var didFinish = false

        init(finishURLPrefix: String?, onFinish: @escaping () -> Void, onLoadingChange: @escaping (Bool) -> Void) {
            self.finishURLPrefix = finishURLPrefix
            self.onFinish = onFinish
            self.onLoadingChange = onLoadingChange
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else { return .allow }
            if let prefix = finishURLPrefix, !prefix.isEmpty, url.absoluteString.hasPrefix(prefix) {
                if !didFinish {
                    didFinish = true
                    onFinish()
                }
                return .cancel
            }
            let scheme = url.scheme?.lowercased() ?? ""
            if !["http", "https", "about", "data", "blob"].contains(scheme) {
                // Deeplink e-wallet / m-banking. Gagal dibuka → Snap tetap menampilkan QR / instruksi.
                Task { @MainActor in _ = await UIApplication.shared.open(url) }
                return .cancel
            }
            return .allow
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadingChange(true)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadingChange(false)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadingChange(false)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            onLoadingChange(false)
        }

        /// Link `target="_blank"` dibuka di WebView yang sama.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
