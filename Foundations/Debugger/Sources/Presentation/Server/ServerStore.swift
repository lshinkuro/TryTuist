//
//  ServerStore.swift
//  Debugger · Presentation
//
//  Tab "Server": ganti environment / base URL / API key / mock tanpa build ulang.
//  Disimpan sebagai `APIOverride` (UserDefaults) → dibaca AppEnvironment di request berikutnya.
//  Setelah diterapkan, app di-restart ke Splash (token dihapus) lewat `DebugMenu.onServerChanged`.
//
import Foundation
import Utility

enum ServerSelection: Hashable {
    /// Nilai dari scheme/xcconfig, tanpa override.
    case build
    case preset(String)
    case custom
}

struct ServerState: Equatable {
    let presets: [ServerPreset]
    /// Override yang sedang aktif saat Debugger dibuka.
    let initial: APIOverride?

    var selection: ServerSelection
    var environment: AppEnvironment
    var baseURL: String
    var apiKey: String
    var useMockData: Bool

    var isPinging = false
    var pingResult: PingResult?
    var validationMessage: String?
    var isConfirmingApply = false

    struct PingResult: Equatable {
        let isSuccess: Bool
        let message: String
    }

    var isEditable: Bool { selection == .custom }

    /// `nil` = kembali ke nilai build.
    var draft: APIOverride? {
        guard selection != .build else { return nil }
        return APIOverride(environment: environment,
                           baseURL: Self.normalized(baseURL),
                           apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                           useMockData: useMockData)
    }

    var hasChanges: Bool { draft != initial }

    static func normalized(_ url: String) -> String {
        var text = url.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix("/") { text.removeLast() }
        return text
    }

    /// Pesan error, atau `nil` bila URL valid.
    static func validate(_ url: String) -> String? {
        let text = normalized(url)
        guard let components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty else {
            return "Base URL harus diawali http:// atau https://, mis. http://172.20.10.3:8080"
        }
        return nil
    }
}

enum ServerAction {
    case selectionChanged(ServerSelection)
    case environmentChanged(AppEnvironment)
    case baseURLChanged(String)
    case apiKeyChanged(String)
    case mockToggled(Bool)
    case pingTapped
    case pingFinished(ServerState.PingResult)
    case applyTapped
    case applyDialogChanged(Bool)
    case applyConfirmed
}

enum ServerRoute {
    case applied
}

final class ServerStore: Store<ServerState, ServerAction> {
    var onRoute: ((ServerRoute) -> Void)?

    private let save: (APIOverride?) -> Void
    private let ping: (URL) async -> ServerState.PingResult

    init(presets: [ServerPreset] = ServerPreset.all,
         current: APIOverride? = APIOverride.current,
         save: @escaping (APIOverride?) -> Void = { APIOverride.save($0) },
         ping: @escaping (URL) async -> ServerState.PingResult = ServerStore.healthCheck) {
        self.save = save
        self.ping = ping
        super.init(initialState: Self.makeState(presets: presets, current: current))
    }

    override func reduce(state: inout ServerState, action: ServerAction) -> Effect<ServerAction>? {
        switch action {
        case .selectionChanged(let selection):
            state.selection = selection
            state.pingResult = nil
            state.validationMessage = nil
            Self.fill(&state, for: selection)
            return nil

        case .environmentChanged(let environment):
            state.environment = environment
            return nil

        case .baseURLChanged(let url):
            state.baseURL = url
            state.pingResult = nil
            state.validationMessage = nil
            return nil

        case .apiKeyChanged(let key):
            state.apiKey = key
            return nil

        case .mockToggled(let isOn):
            state.useMockData = isOn
            // Mock di-override → tidak lagi sama dengan nilai build.
            if state.selection == .build, isOn != AppEnvironment.buildUseMockData {
                state.selection = .custom
            }
            return nil

        case .pingTapped:
            if let message = ServerState.validate(state.baseURL) {
                state.validationMessage = message
                return nil
            }
            guard let url = URL(string: ServerState.normalized(state.baseURL) + "/healthz") else { return nil }
            state.isPinging = true
            state.pingResult = nil
            let ping = self.ping
            return .task { .pingFinished(await ping(url)) }

        case .pingFinished(let result):
            state.isPinging = false
            state.pingResult = result
            return nil

        case .applyTapped:
            if state.selection != .build, !state.useMockData, let message = ServerState.validate(state.baseURL) {
                state.validationMessage = message
                return nil
            }
            state.validationMessage = nil
            state.isConfirmingApply = true
            return nil

        case .applyDialogChanged(let isPresented):
            state.isConfirmingApply = isPresented
            return nil

        case .applyConfirmed:
            state.isConfirmingApply = false
            let draft = state.draft
            let save = self.save
            return .run { [weak self] in
                save(draft)
                self?.onRoute?(.applied)
            }
        }
    }

    // MARK: - Helpers

    private static func makeState(presets: [ServerPreset], current: APIOverride?) -> ServerState {
        var state = ServerState(presets: presets,
                                initial: current,
                                selection: .build,
                                environment: AppEnvironment.build,
                                baseURL: AppEnvironment.buildBaseURL,
                                apiKey: AppEnvironment.buildAPIKey,
                                useMockData: AppEnvironment.buildUseMockData)
        guard let current else { return state }

        state.environment = current.environment
        state.baseURL = current.baseURL
        state.apiKey = current.apiKey
        state.useMockData = current.useMockData
        let matched = presets.first {
            $0.environment == current.environment && ServerState.normalized($0.baseURL) == current.baseURL
                && $0.apiKey == current.apiKey
        }
        state.selection = matched.map { ServerSelection.preset($0.id) } ?? ServerSelection.custom
        return state
    }

    private static func fill(_ state: inout ServerState, for selection: ServerSelection) {
        switch selection {
        case .build:
            state.environment = AppEnvironment.build
            state.baseURL = AppEnvironment.buildBaseURL
            state.apiKey = AppEnvironment.buildAPIKey
            state.useMockData = AppEnvironment.buildUseMockData
        case .preset(let id):
            guard let preset = state.presets.first(where: { $0.id == id }) else { return }
            state.environment = preset.environment
            state.baseURL = preset.baseURL
            state.apiKey = preset.apiKey
            state.useMockData = false
        case .custom:
            break // Lanjutkan dari nilai yang sedang tampil.
        }
    }

    /// `GET <baseURL>/healthz` tanpa lewat APIManager (tidak butuh API key).
    nonisolated static func healthCheck(_ url: URL) async -> ServerState.PingResult {
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return .init(isSuccess: (200..<300).contains(status), message: "HTTP \(status) · \(ms) ms")
        } catch {
            return .init(isSuccess: false, message: error.localizedDescription)
        }
    }
}
