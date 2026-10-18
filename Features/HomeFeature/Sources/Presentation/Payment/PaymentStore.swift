//
//  PaymentStore.swift
//  HomeFeature · Presentation
//
//  Layar Pembayaran (§5.27): halaman Snap Midtrans di WebView + polling status ke backend.
//  Status lunas hanya dipercaya dari server (webhook / GET Status), bukan dari URL finish.
//
import Foundation
import TTUI
import Utility

struct PaymentState: Equatable {
    enum Phase: Equatable {
        /// Halaman Snap tampil.
        case paying
        /// User selesai di Snap / kembali ke app → menunggu konfirmasi server.
        case checking
        /// Sudah 2 menit tanpa konfirmasi.
        case stillWaiting
        /// Gagal / kedaluwarsa / dibatalkan.
        case notPaid(String)
    }

    var session: PaymentSession
    var phase: Phase = .paying
    var isCancelDialogPresented = false
    var isCancelling = false
    /// Batas polling setelah WebView ditutup.
    var pollDeadline: Date?
    /// Naik setiap loop polling baru dimulai; tick dari loop lama diabaikan.
    var pollGeneration = 0
    var lastError: String?

    /// Mock (`USE_MOCK_DATA`): tidak ada halaman Snap, lunas otomatis.
    var isMock: Bool { session.redirectURL == nil }

    var title: String {
        switch phase {
        case .notPaid: return String(localized: "Pembayaran tidak berhasil")
        default: return String(localized: "Pembayaran")
        }
    }
}

enum PaymentAction {
    case onAppear
    case webFinished
    case appBecameActive
    case pollTick(Int)
    /// `generation` = loop polling yang meminta; respons loop lama tidak menjadwalkan tick baru.
    case statusResponse(Int, Result<PaymentSession, PaymentError>)
    case checkAgainTapped
    case closeTapped
    case cancelDialogChanged(Bool)
    case cancelConfirmed
    case cancelResponse(Result<PaymentSession, PaymentError>)
    case continueLaterTapped
    case backToCartTapped
    case outcomeReady(PaymentOutcome)
}

enum PaymentRoute {
    case finished(PaymentOutcome)
}

final class PaymentStore: Store<PaymentState, PaymentAction> {
    static let pollInterval: Duration = .seconds(3)
    static let waitAfterFinish: TimeInterval = 120

    private let checkPayment: CheckPaymentUseCase
    private let cancelPayment: CancelPaymentUseCase
    private let finishPayment: FinishPaymentUseCase
    var onRoute: ((PaymentRoute) -> Void)?

    init(session: PaymentSession, checkPayment: CheckPaymentUseCase,
         cancelPayment: CancelPaymentUseCase, finishPayment: FinishPaymentUseCase) {
        self.checkPayment = checkPayment
        self.cancelPayment = cancelPayment
        self.finishPayment = finishPayment
        var initial = PaymentState(session: session)
        if session.redirectURL == nil { initial.phase = .checking }
        super.init(initialState: initial)
    }

    override func reduce(state: inout PaymentState, action: PaymentAction) -> Effect<PaymentAction>? {
        switch action {
        case .onAppear:
            let session = state.session
            if session.status.isFinal { return handleFinal(&state, session) }
            return startPolling(&state, immediately: false)

        case .webFinished:
            // URL finish Snap tercegat: tutup WebView, minta konfirmasi ke server.
            guard state.phase == .paying else { return nil }
            state.phase = .checking
            state.pollDeadline = Date().addingTimeInterval(Self.waitAfterFinish)
            return startPolling(&state, immediately: true)

        case .appBecameActive:
            // Kembali dari aplikasi GoPay / ShopeePay / m-banking.
            guard !state.session.status.isFinal, !isNotPaid(state.phase) else { return nil }
            return startPolling(&state, immediately: true)

        case .pollTick(let generation):
            guard generation == state.pollGeneration, !state.session.status.isFinal, !isNotPaid(state.phase) else { return nil }
            return fetchStatus(state.session.id, generation)

        case .statusResponse(let generation, .success(let session)):
            guard !state.session.status.isFinal else { return nil }
            state.session = session
            state.lastError = nil
            if session.status.isFinal { return handleFinal(&state, session) }
            guard generation == state.pollGeneration else { return nil }
            if state.phase == .checking, let deadline = state.pollDeadline, Date() > deadline {
                state.phase = .stillWaiting
                return nil
            }
            return scheduleTick(generation)

        case .statusResponse(let generation, .failure(let error)):
            guard generation == state.pollGeneration else { return nil }
            if error == .sessionExpired || error == .notFound {
                state.lastError = error.errorDescription
                return nil
            }
            // Gangguan sesaat: coba lagi di tick berikutnya.
            state.lastError = error.errorDescription
            return state.phase == .stillWaiting ? nil : scheduleTick(generation)

        case .checkAgainTapped:
            state.phase = .checking
            state.pollDeadline = Date().addingTimeInterval(Self.waitAfterFinish)
            return startPolling(&state, immediately: true)

        case .closeTapped:
            if state.session.status.isFinal || isNotPaid(state.phase) {
                return backToCart(state)
            }
            state.isCancelDialogPresented = true
            return nil

        case .cancelDialogChanged(let presented):
            state.isCancelDialogPresented = presented
            return nil

        case .cancelConfirmed:
            state.isCancelDialogPresented = false
            guard !state.isCancelling else { return nil }
            state.isCancelling = true
            state.pollGeneration += 1   // hentikan polling
            let cancelPayment = self.cancelPayment
            let id = state.session.id
            return .task {
                do {
                    return .cancelResponse(.success(try await cancelPayment.execute(id: id)))
                } catch {
                    return .cancelResponse(.failure(error as? PaymentError ?? .network))
                }
            }

        case .cancelResponse(.success(let session)):
            state.isCancelling = false
            state.session = session
            if session.status == .paid { return handleFinal(&state, session) }
            return finish(.notPaid(message: String(localized: "Pembayaran dibatalkan. Isi keranjang masih tersimpan.")))

        case .cancelResponse(.failure(let error)):
            state.isCancelling = false
            state.lastError = error.errorDescription
            return startPolling(&state, immediately: true)

        case .continueLaterTapped:
            state.isCancelDialogPresented = false
            state.pollGeneration += 1
            return finish(.later)

        case .backToCartTapped:
            return backToCart(state)

        case .outcomeReady(let outcome):
            return .run { [weak self] in self?.onRoute?(.finished(outcome)) }
        }
    }

    // MARK: - Helpers

    private func isNotPaid(_ phase: PaymentState.Phase) -> Bool {
        if case .notPaid = phase { return true }
        return false
    }

    private func handleFinal(_ state: inout PaymentState, _ session: PaymentSession) -> Effect<PaymentAction>? {
        state.pollGeneration += 1
        if session.status == .paid {
            let order = session.order ?? PlacedOrder(orderNumber: "-", total: session.amount)
            return finish(.paid(order))
        }
        let message: String
        switch session.status {
        case .expired: message = session.statusMessage ?? String(localized: "Batas waktu pembayaran habis.")
        case .cancelled: message = session.statusMessage ?? String(localized: "Pembayaran dibatalkan.")
        default: message = session.statusMessage ?? String(localized: "Pembayaran ditolak. Coba metode lain.")
        }
        state.phase = .notPaid(message)
        return nil
    }

    private func backToCart(_ state: PaymentState) -> Effect<PaymentAction> {
        if case .notPaid(let message) = state.phase {
            return finish(.notPaid(message: message))
        }
        return finish(.later)
    }

    /// Bereskan keranjang (lunas → kosong) lalu kirim route.
    private func finish(_ outcome: PaymentOutcome) -> Effect<PaymentAction> {
        let finishPayment = self.finishPayment
        return .task {
            await finishPayment.execute(outcome)
            return .outcomeReady(outcome)
        }
    }

    private func startPolling(_ state: inout PaymentState, immediately: Bool) -> Effect<PaymentAction> {
        state.pollGeneration += 1
        if immediately { return fetchStatus(state.session.id, state.pollGeneration) }
        return scheduleTick(state.pollGeneration)
    }

    private func scheduleTick(_ generation: Int) -> Effect<PaymentAction> {
        .task {
            try? await Task.sleep(for: Self.pollInterval)
            return .pollTick(generation)
        }
    }

    private func fetchStatus(_ id: String, _ generation: Int) -> Effect<PaymentAction> {
        let checkPayment = self.checkPayment
        return .task {
            do {
                return .statusResponse(generation, .success(try await checkPayment.execute(id: id)))
            } catch {
                return .statusResponse(generation, .failure(error as? PaymentError ?? .network))
            }
        }
    }
}
