//
//  OrderDetailStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import TTUI
import Utility

struct OrderDetailState: Equatable {
    let orderID: String
    var detail: Loadable<OrderDetail> = .idle
    var isConfirmingCancel = false
    var isCancelling = false
    var isReceiptPresented = false
    var toast: ToastMessage?
}

enum OrderDetailAction {
    case onAppear
    case retryTapped
    case detailResponse(Result<OrderDetail, OrderError>)
    case rateTapped
    /// Rating terkirim → muat ulang supaya nilai tampil.
    case ratingSubmitted
    case cancelTapped
    case cancelConfirmChanged(Bool)
    case cancelConfirmed
    case cancelResponse(Result<OrderDetail, OrderError>)
    case receiptChanged(Bool)
    case reorderTapped
    case toastDismissed(UUID)
}

enum OrderDetailRoute {
    case rate(RatingTarget)
    /// "Pesan Lagi": item dimasukkan ke keranjang Beranda.
    case reorder([OrderDetail.Item])
    /// Pesanan dibatalkan → daftar pesanan perlu dimuat ulang.
    case cancelled
}

final class OrderDetailStore: Store<OrderDetailState, OrderDetailAction> {
    private let getDetail: GetOrderDetailUseCase
    private let cancelOrder: CancelOrderUseCase
    var onRoute: ((OrderDetailRoute) -> Void)?

    init(orderID: String, getDetail: GetOrderDetailUseCase, cancelOrder: CancelOrderUseCase) {
        self.getDetail = getDetail
        self.cancelOrder = cancelOrder
        super.init(initialState: OrderDetailState(orderID: orderID))
    }

    override func reduce(state: inout OrderDetailState, action: OrderDetailAction) -> Effect<OrderDetailAction>? {
        switch action {
        case .onAppear:
            guard state.detail.isIdle else { return nil }
            return load(&state)

        case .retryTapped, .ratingSubmitted:
            return load(&state)

        case .rateTapped:
            guard let detail = state.detail.value else { return nil }
            let target = RatingTarget(orderID: detail.id, title: detail.orderNumber, createdAt: detail.createdAt)
            return .run { [weak self] in self?.onRoute?(.rate(target)) }

        case .detailResponse(.success(let detail)):
            state.detail = .loaded(detail)
            return nil

        case .detailResponse(.failure(let error)):
            state.detail = .failed(error.errorDescription ?? "")
            return nil

        case .cancelTapped:
            guard state.detail.value?.canCancel == true, !state.isCancelling else { return nil }
            state.isConfirmingCancel = true
            return nil

        case .cancelConfirmChanged(let isPresented):
            state.isConfirmingCancel = isPresented
            return nil

        case .cancelConfirmed:
            state.isConfirmingCancel = false
            guard !state.isCancelling else { return nil }
            state.isCancelling = true
            let cancelOrder = self.cancelOrder
            let id = state.orderID
            return .task {
                do {
                    return .cancelResponse(.success(try await cancelOrder.execute(id: id)))
                } catch {
                    return .cancelResponse(.failure(error as? OrderError ?? .unknown))
                }
            }

        case .cancelResponse(.success(let detail)):
            state.isCancelling = false
            state.detail = .loaded(detail)
            state.toast = ToastMessage(String(localized: "Pesanan dibatalkan"))
            return .run { [weak self] in self?.onRoute?(.cancelled) }

        case .cancelResponse(.failure(let error)):
            // Mis. outlet sudah memproses pesanan: tampilkan alasan & muat status terbaru.
            state.isCancelling = false
            state.toast = ToastMessage(error.errorDescription ?? "", systemImage: "exclamationmark.triangle.fill", isError: true)
            return load(&state, silently: true)

        case .receiptChanged(let isPresented):
            state.isReceiptPresented = isPresented
            return nil

        case .reorderTapped:
            guard let items = state.detail.value?.items, !items.isEmpty else { return nil }
            return .run { [weak self] in self?.onRoute?(.reorder(items)) }

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    /// `silently`: detail lama tetap tampil selama memuat (tanpa layar loading).
    private func load(_ state: inout OrderDetailState, silently: Bool = false) -> Effect<OrderDetailAction> {
        if !silently || state.detail.value == nil { state.detail = .loading }
        let getDetail = self.getDetail
        let id = state.orderID
        return .task {
            do {
                return .detailResponse(.success(try await getDetail.execute(id: id)))
            } catch {
                return .detailResponse(.failure(error as? OrderError ?? .unknown))
            }
        }
    }
}
