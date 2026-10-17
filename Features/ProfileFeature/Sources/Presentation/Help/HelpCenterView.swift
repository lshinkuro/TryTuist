//
//  HelpCenterView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct HelpCenterView: View {
    @StateObject private var store: HelpCenterStore

    init(store: HelpCenterStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: HelpCenterState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.m)

            LoadableView(state: state.content, retry: { store.send(.retryTapped) }) { content in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        if content.topics.isEmpty {
                            ContentUnavailableView.search(text: state.searchedQuery)
                        }
                        ForEach(content.topics) { topic in
                            topicSection(topic)
                        }
                        contactSection(content)
                    }
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xl)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { store.send(.onAppear) }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Cari pertanyaan, mis. batalkan pesanan",
                      text: store.binding(\.query, send: { .queryChanged($0) }))
                .submitLabel(.search)
                .autocorrectionDisabled()
            if state.isSearching {
                ProgressView().controlSize(.small)
            } else if !state.query.isEmpty {
                Button { store.send(.queryChanged("")) } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .accessibilityLabel("Hapus pencarian")
            }
        }
        .padding(.horizontal, Spacing.l)
        .frame(height: 48)
        .background(Color.fieldBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }

    private func topicSection(_ topic: HelpTopic) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Label(topic.title, systemImage: topic.systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
            VStack(spacing: 0) {
                ForEach(Array(topic.articles.enumerated()), id: \.element.id) { index, article in
                    if index > 0 { Divider().padding(.leading, Spacing.l) }
                    articleRow(article)
                }
            }
            .formCard()
        }
    }

    private func articleRow(_ article: HelpArticle) -> some View {
        let isExpanded = state.expandedArticleIDs.contains(article.id)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Button {
                withAnimation(.snappy) { store.send(.articleToggled(article.id)) }
            } label: {
                HStack(alignment: .top, spacing: Spacing.m) {
                    Text(article.question)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: Spacing.s)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Sembunyikan jawaban" : "Tampilkan jawaban")

            if isExpanded {
                Text(article.answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .padding(Spacing.l)
    }

    private func contactSection(_ content: HelpCenter) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Masih butuh bantuan?").font(.headline)
            if let hours = content.operatingHours {
                Text("Customer service: \(hours)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 0) {
                ForEach(Array(content.contacts.enumerated()), id: \.element.id) { index, contact in
                    if index > 0 { Divider().padding(.leading, 64) }
                    Button { store.send(.contactTapped(contact)) } label: {
                        ProfileMenuRow(title: contact.label, subtitle: contact.value,
                                       systemImage: contact.systemImage, tint: tint(for: contact.kind))
                    }
                    .buttonStyle(.plain)
                }
            }
            .formCard()
        }
    }

    private func tint(for kind: HelpContact.Kind) -> Color {
        switch kind {
        case .whatsapp: return .green
        case .email: return .blue
        case .phone: return .orange
        case .other: return .brand
        }
    }
}
