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
                    if state.isReplying {
                        ProgressView()
                            .padding(Spacing.m)
                            .accessibilityLabel("Asisten sedang mengetik")
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
        .safeAreaInset(edge: .bottom) { inputBar }
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
            TextField("Tulis pertanyaan…", text: store.binding(\.input, send: { .inputChanged($0) }), axis: .vertical)
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
