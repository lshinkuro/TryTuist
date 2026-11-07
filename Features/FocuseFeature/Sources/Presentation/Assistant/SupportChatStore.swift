//
//  SupportChatStore.swift
//  FocuseFeature · Presentation
//
import Foundation
import Utility

struct SupportChatState: Equatable {
    static let messageLimit = 500
    static let suggestions = [
        String(localized: "Pesanan terakhirku sampai mana?"),
        String(localized: "Gimana cara pakai kupon ongkir?"),
        String(localized: "Bisa batalin pesanan?"),
    ]

    var messages = [ChatMessage(role: .assistant,
                                text: String(localized: "Halo! Aku bisa bantu cek status pesanan, kupon ongkir, pembayaran, atau pembatalan. Mau tanya apa?"))]
    var input = ""
    var isReplying = false

    var canSend: Bool { !isReplying && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var showsSuggestions: Bool { messages.count == 1 }
}

enum SupportChatAction {
    case inputChanged(String)
    case sendTapped
    case suggestionTapped(String)
    case replyResponse(String?)
}

final class SupportChatStore: Store<SupportChatState, SupportChatAction> {
    private let chat: SupportChat

    init(chat: SupportChat) {
        self.chat = chat
        super.init(initialState: SupportChatState())
    }

    override func reduce(state: inout SupportChatState, action: SupportChatAction) -> Effect<SupportChatAction>? {
        switch action {
        case .inputChanged(let text):
            state.input = String(text.prefix(SupportChatState.messageLimit))
            return nil

        case .suggestionTapped(let text):
            state.input = text
            return send(&state)

        case .sendTapped:
            return send(&state)

        case .replyResponse(let reply):
            state.isReplying = false
            state.messages.append(ChatMessage(role: .assistant,
                                              text: reply ?? String(localized: "Maaf, aku belum bisa menjawab. Coba lagi ya.")))
            return nil
        }
    }

    private func send(_ state: inout SupportChatState) -> Effect<SupportChatAction>? {
        guard state.canSend else { return nil }
        let text = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
        state.messages.append(ChatMessage(role: .user, text: text))
        state.input = ""
        state.isReplying = true
        let chat = self.chat
        return .task { .replyResponse(await chat.reply(to: text)) }
    }
}
