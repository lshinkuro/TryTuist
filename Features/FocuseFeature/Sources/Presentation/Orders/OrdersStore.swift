//
//  OrdersStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import TTUI
import Utility

struct OrdersState: Equatable {
    /// nil = "Semua"
    var filter: OrderStatus?
    var dateRange: OrderDateRange = .all
    var newestFirst = true
    var orders: Loadable<[Order]> = .idle
    var page = 1
    var hasMore = false
    var isLoadingMore = false
    /// Naik setiap filter berubah; response dari filter lama diabaikan.
    var requestID = 0
    /// Pesanan yang sedang disiapkan untuk "Pesan Lagi" (tombolnya loading).
    var reorderingID: String?
    var toast: ToastMessage?

    var displayedOrders: [Order] { orders.value ?? [] }

    func query(page: Int, now: Date = Date(), calendar: Calendar = .current) -> OrderListQuery {
        OrderListQuery(status: filter, from: dateRange.start(now: now, calendar: calendar),
                       to: nil, newestFirst: newestFirst, page: page)
    }
}

/// Rentang tanggal pesanan, dihitung dari awal hari (jam 00.00) di zona waktu perangkat.
enum OrderDateRange: CaseIterable, Equatable {
    case all, today, last7Days, last30Days

    var title: String {
        switch self {
        case .all: return String(localized: "Semua waktu")
        case .today: return String(localized: "Hari ini")
        case .last7Days: return String(localized: "7 hari terakhir")
        case .last30Days: return String(localized: "30 hari terakhir")
        }
    }

    /// nil = tanpa batas bawah.
    func start(now: Date, calendar: Calendar) -> Date? {
        let days: Int
        switch self {
        case .all: return nil
        case .today: days = 0
        case .last7Days: days = 6
        case .last30Days: days = 29
        }
        return calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now))
    }
}

enum OrdersRoute {
    case detail(id: String)
    case rate(RatingTarget)
    case reorder([OrderDetail.Item])
}

enum OrdersAction {
    case onAppear
    case retryTapped
    case filterChanged(OrderStatus?)
    case dateRangeChanged(OrderDateRange)
    case sortToggled
    /// Baris terakhir tampil → muat halaman berikutnya.
    case lastRowAppeared
    case ordersResponse(requestID: Int, page: Int, Result<[Order], OrderError>)
    case orderTapped(Order)
    case rateTapped(Order)
    /// Rating terkirim dari layar Beri Nilai.
    case ratingSubmitted(orderID: String, rating: Int)
    case reorderTapped(Order)
    case reorderResponse(Result<OrderDetail, OrderError>)
    case toastDismissed(UUID)
}

final class OrdersStore: Store<OrdersState, OrdersAction> {
    private let getOrders: GetOrdersUseCase
    private let getDetail: GetOrderDetailUseCase
    var onRoute: ((OrdersRoute) -> Void)?

    init(getOrders: GetOrdersUseCase, getDetail: GetOrderDetailUseCase) {
        self.getOrders = getOrders
        self.getDetail = getDetail
        super.init(initialState: OrdersState())
    }

    override func reduce(state: inout OrdersState, action: OrdersAction) -> Effect<OrdersAction>? {
        switch action {
        case .onAppear:
            // Pertama kali: tampilkan loading. Setelahnya: refresh diam-diam supaya
            // pesanan baru dari checkout langsung muncul tanpa layar berkedip.
            guard state.orders.isIdle else { return refresh(&state) }
            return reload(&state)

        case .retryTapped:
            return reload(&state)

        case .filterChanged(let filter):
            state.filter = filter
            return reload(&state)

        case .dateRangeChanged(let range):
            state.dateRange = range
            return reload(&state)

        case .sortToggled:
            state.newestFirst.toggle()
            return reload(&state)

        case .lastRowAppeared:
            guard state.hasMore, !state.isLoadingMore, state.orders.value != nil else { return nil }
            state.isLoadingMore = true
            return fetch(state, page: state.page + 1)

        case .ordersResponse(let requestID, let page, let result):
            guard requestID == state.requestID else { return nil }
            state.isLoadingMore = false
            switch result {
            case .success(let orders):
                let current = page == 1 ? [] : (state.orders.value ?? [])
                state.orders = .loaded(current + orders.filter { new in !current.contains { $0.id == new.id } })
                state.page = page
                state.hasMore = orders.count == OrderListQuery.pageSize
            case .failure(let error):
                // Refresh / halaman berikutnya yang gagal tidak menghapus data yang sudah tampil.
                guard state.orders.value == nil else { return showToast(&state, .error(error.errorDescription ?? "")) }
                state.orders = .failed(error.errorDescription ?? "")
            }
            return nil

        case .orderTapped(let order):
            return .run { [weak self] in self?.onRoute?(.detail(id: order.id)) }

        case .rateTapped(let order):
            let target = RatingTarget(orderID: order.id, title: order.productName, createdAt: order.createdAt)
            return .run { [weak self] in self?.onRoute?(.rate(target)) }

        case .ratingSubmitted(let orderID, let rating):
            // Cukup ubah lokal: server sudah menyimpan, can_rate pesanan ini pasti false.
            if var orders = state.orders.value, let index = orders.firstIndex(where: { $0.id == orderID }) {
                orders[index].canRate = false
                orders[index].rating = rating
                state.orders = .loaded(orders)
            }
            return showToast(&state, ToastMessage(String(localized: "Terima kasih atas penilaianmu!"), systemImage: "star.fill"))

        case .reorderTapped(let order):
            guard state.reorderingID == nil else { return nil }
            state.reorderingID = order.id
            let getDetail = self.getDetail
            return .task {
                do {
                    return .reorderResponse(.success(try await getDetail.execute(id: order.id)))
                } catch {
                    return .reorderResponse(.failure(error as? OrderError ?? .unknown))
                }
            }

        case .reorderResponse(.success(let detail)):
            state.reorderingID = nil
            return .run { [weak self] in self?.onRoute?(.reorder(detail.items)) }

        case .reorderResponse(.failure(let error)):
            state.reorderingID = nil
            return showToast(&state, .error(error.errorDescription ?? ""))

        case .toastDismissed(let id):
            if state.toast?.id == id { state.toast = nil }
            return nil
        }
    }

    /// Filter berubah: mulai lagi dari halaman 1 dengan loading.
    private func reload(_ state: inout OrdersState) -> Effect<OrdersAction> {
        state.orders = .loading
        return refresh(&state)
    }

    /// Halaman 1 tanpa loading; response dari request sebelumnya diabaikan.
    private func refresh(_ state: inout OrdersState) -> Effect<OrdersAction> {
        state.requestID += 1
        state.isLoadingMore = false
        return fetch(state, page: 1)
    }

    private func fetch(_ state: OrdersState, page: Int) -> Effect<OrdersAction> {
        let getOrders = self.getOrders
        let query = state.query(page: page)
        let requestID = state.requestID
        return .task {
            do {
                return .ordersResponse(requestID: requestID, page: page, .success(try await getOrders.execute(query)))
            } catch {
                return .ordersResponse(requestID: requestID, page: page, .failure(error as? OrderError ?? .unknown))
            }
        }
    }

    private func showToast(_ state: inout OrdersState, _ toast: ToastMessage) -> Effect<OrdersAction> {
        state.toast = toast
        let id = toast.id
        return .task {
            try? await Task.sleep(for: .seconds(2))
            return .toastDismissed(id)
        }
    }
}
