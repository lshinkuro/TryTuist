//
//  PaymentView.swift
//  HomeFeature · Presentation
//
import SwiftUI
import TTUI

struct PaymentView: View {
    @StateObject private var store: PaymentStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPageLoading = true

    init(store: PaymentStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: PaymentState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .confirmationDialog("Tutup pembayaran?",
                            isPresented: store.binding(\.isCancelDialogPresented, send: { .cancelDialogChanged($0) }),
                            titleVisibility: .visible) {
            Button("Batalkan pembayaran", role: .destructive) { store.send(.cancelConfirmed) }
            Button("Bayar nanti") { store.send(.continueLaterTapped) }
            Button("Lanjut bayar", role: .cancel) {}
        } message: {
            Text("Kalau sudah membayar, jangan dibatalkan. Pesanan otomatis dibuat setelah pembayaran diterima.")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.appBecameActive) }
        }
        .task { @MainActor in store.send(.onAppear) }
        .interactiveDismissDisabled()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Spacing.m) {
            Button { store.send(.closeTapped) } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(state.isCancelling)
            .accessibilityLabel("Tutup")

            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.headline)
                HStack(spacing: Spacing.s) {
                    Text(state.session.amount.rupiahFormatted)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.brand)
                    if !state.session.storeName.isEmpty {
                        Text("· \(state.session.storeName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            if !state.session.status.isFinal, !isNotPaid {
                countdown
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }

    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int(state.session.remaining(at: context.date))
            VStack(alignment: .trailing, spacing: 0) {
                Text("Sisa waktu").font(.caption2).foregroundStyle(.secondary)
                Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(remaining < 60 ? Color.red : Color.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sisa waktu \(remaining / 60) menit \(remaining % 60) detik")
        }
    }

    private var isNotPaid: Bool {
        if case .notPaid = state.phase { return true }
        return false
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch state.phase {
        case .paying:
            if let url = state.session.redirectURL {
                ZStack {
                    MidtransWebView(url: url, finishURLPrefix: state.session.finishURLPrefix,
                                    onFinish: { store.send(.webFinished) },
                                    onLoadingChange: { isPageLoading = $0 })
                    if isPageLoading {
                        ProgressView("Membuka halaman pembayaran…")
                            .padding(Spacing.l)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.control))
                    }
                }
            } else {
                checking
            }
        case .checking:
            checking
        case .stillWaiting:
            stillWaiting
        case .notPaid(let message):
            notPaid(message)
        }
    }

    private var checking: some View {
        VStack(spacing: Spacing.l) {
            ProgressView()
                .controlSize(.large)
            Text(state.isMock ? String(localized: "Simulasi pembayaran…") : String(localized: "Mengecek pembayaran…"))
                .font(.headline)
            Text(state.isMock
                 ? String(localized: "Mode mock: pembayaran otomatis berhasil dalam beberapa detik.")
                 : String(localized: "Biasanya hanya beberapa detik setelah kamu membayar."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let error = state.lastError {
                Label(error, systemImage: "wifi.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .padding(Spacing.xl)
    }

    private var stillWaiting: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "hourglass")
                .font(.system(size: 56))
                .foregroundStyle(Color.brand)
            Text("Kami masih menunggu konfirmasi pembayaran")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Kalau sudah membayar, pesanan otomatis dibuat begitu pembayaran diterima. Kamu bisa menutup layar ini dan melanjutkan dari Beranda.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(String(localized: "Cek lagi")) { store.send(.checkAgainTapped) }
            Button("Tutup, cek nanti") { store.send(.continueLaterTapped) }
                .font(.subheadline.weight(.semibold))
        }
        .padding(Spacing.xl)
    }

    private func notPaid(_ message: String) -> some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: state.session.status == .expired ? "clock.badge.xmark" : "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Isi keranjang masih tersimpan. Kamu bisa mencoba bayar lagi.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(String(localized: "Kembali ke keranjang")) { store.send(.backToCartTapped) }
        }
        .padding(Spacing.xl)
    }
}
