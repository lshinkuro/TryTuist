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
    var isSpeaking = false
    /// Mic aktif: pertanyaan diucapkan, lalu terkirim otomatis.
    var isListening = false
    /// Balasan dibacakan dengan suara.
    var isVoiceEnabled = true

    var orbMood: AssistantOrb.Mood {
        isListening ? .listening : isReplying ? .thinking : isSpeaking ? .speaking : .idle
    }

    var canSend: Bool { !isReplying && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var showsSuggestions: Bool { messages.count == 1 }
}

enum SupportChatAction {
    case inputChanged(String)
    case sendTapped
    case suggestionTapped(String)
    case replyResponse(String?)
    case speakingChanged(Bool)
    case voiceToggled
    case micTapped
    case voiceEvent(VoiceSearchEvent)
    case closed
}

final class SupportChatStore: Store<SupportChatState, SupportChatAction> {
    private let chat: SupportChat
    private let speaker: SpeechSpeaker
    private let voiceInput: VoiceSearch

    init(chat: SupportChat, speaker: SpeechSpeaker, voiceInput: VoiceSearch) {
        self.chat = chat
        self.speaker = speaker
        self.voiceInput = voiceInput
        super.init(initialState: SupportChatState())
        bind(speaker.isSpeakingPublisher) { .speakingChanged($0) }
        bind(voiceInput.events) { .voiceEvent($0) }
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
            let text = reply ?? String(localized: "Maaf, aku belum bisa menjawab. Coba lagi ya.")
            state.messages.append(ChatMessage(role: .assistant, text: text))
            guard state.isVoiceEnabled else { return nil }
            let speaker = self.speaker
            return .run { speaker.speak(text) }

        case .speakingChanged(let isSpeaking):
            state.isSpeaking = isSpeaking
            return nil

        case .voiceToggled:
            state.isVoiceEnabled.toggle()
            guard !state.isVoiceEnabled else { return nil }
            let speaker = self.speaker
            return .run { speaker.stop() }

        case .micTapped:
            let voiceInput = self.voiceInput
            if state.isListening {
                return .run { voiceInput.finish() }
            }
            guard !state.isReplying else { return nil }
            state.isListening = true
            state.input = ""
            speaker.stop()
            return .task {
                await voiceInput.start()
                return nil
            }

        case .voiceEvent(.transcript(let text, let isFinal)):
            guard state.isListening else { return nil }
            state.input = String(text.prefix(SupportChatState.messageLimit))
            guard isFinal else { return nil }
            state.isListening = false
            return send(&state)

        case .voiceEvent(.failed(let message)):
            state.isListening = false
            state.messages.append(ChatMessage(role: .assistant, text: message))
            return nil

        case .closed:
            let (speaker, voiceInput, isListening) = (self.speaker, self.voiceInput, state.isListening)
            state.isListening = false
            return .run {
                speaker.stop()
                if isListening { voiceInput.finish() }
            }
        }
    }

    private func send(_ state: inout SupportChatState) -> Effect<SupportChatAction>? {
        guard state.canSend else { return nil }
        let text = state.input.trimmingCharacters(in: .whitespacesAndNewlines)
        state.messages.append(ChatMessage(role: .user, text: text))
        state.input = ""
        state.isReplying = true
        speaker.stop()   // pertanyaan baru memotong balasan yang sedang dibacakan
        let chat = self.chat
        return .task { .replyResponse(await chat.reply(to: text)) }
    }
}
