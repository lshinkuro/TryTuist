//
//  SupportChatView.swift
//  FocuseFeature · Presentation
//
import SwiftUI
import TTUI

struct SupportChatView: View {
    @StateObject private var store: SupportChatStore
    private var state: SupportChatState { store.state }

    init(store: SupportChatStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Dijawab Apple Intelligence di perangkatmu. Bisa keliru, cek lagi info penting.")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    ForEach(state.messages) { message in
                        bubble(message).id(message.id)
                    }
                    if state.showsSuggestions {
                        ForEach(SupportChatState.suggestions, id: \.self) { suggestion in
                            Button(suggestion) { store.send(.suggestionTapped(suggestion)) }
                                .font(.appSubhead)
                                .buttonStyle(CapsuleButtonStyle(.outlined))
                        }
                    }
                }
                .padding(Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: state.messages) { _, messages in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { orbHeader }
        .safeAreaInset(edge: .bottom) { inputBar }
        .onDisappear { store.send(.closed) }
    }

    private var orbHeader: some View {
        VStack(spacing: Spacing.xs) {
            AssistantOrb(mood: state.orbMood, size: 72)
            Text(moodText)
                .font(.appCaption)
                .foregroundStyle(.secondary)
                .contentTransition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s)
        .overlay(alignment: .topTrailing) {
            Button { store.send(.voiceToggled) } label: {
                Image(systemName: state.isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.title3)
                    .padding(Spacing.m)
            }
            .accessibilityLabel(state.isVoiceEnabled ? String(localized: "Matikan suara balasan") : String(localized: "Nyalakan suara balasan"))
        }
        .background(.bar)
    }

    private var moodText: String {
        switch state.orbMood {
        case .idle: return String(localized: "Siap membantu")
        case .listening: return String(localized: "Mendengarkan…")
        case .thinking: return String(localized: "Sedang berpikir…")
        case .speaking: return String(localized: "Berbicara…")
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user
        return Text(message.text)
            .font(.appSubhead)
            .textSelection(.enabled)
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .padding(Spacing.m)
            .background(isUser ? Color.brand : Color.cardBackground,
                        in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .padding(isUser ? .leading : .trailing, 48)
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.s) {
            Button { store.send(.micTapped) } label: {
                Image(systemName: state.isListening ? "waveform" : "mic.fill")
                    .font(.title3)
                    .foregroundStyle(state.isListening ? Color.brand : Color.secondary)
                    .symbolEffect(.variableColor.iterative, isActive: state.isListening)
                    .frame(width: 36, height: 36)
            }
            .disabled(state.isReplying)
            .accessibilityLabel(state.isListening ? String(localized: "Berhenti mendengarkan") : String(localized: "Tanya dengan suara"))

            TextField(state.isListening ? String(localized: "Mendengarkan…") : String(localized: "Tulis pertanyaan…"),
                      text: store.binding(\.input, send: { .inputChanged($0) }), axis: .vertical)
                .lineLimit(1...4)
                .padding(Spacing.m)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            Button { store.send(.sendTapped) } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title)
            }
            .disabled(!state.canSend)
            .accessibilityLabel("Kirim pertanyaan")
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.m)
        .background(.bar)
    }
}
