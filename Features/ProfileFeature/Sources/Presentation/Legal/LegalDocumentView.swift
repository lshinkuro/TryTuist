//
//  LegalDocumentView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct LegalDocumentView: View {
    @StateObject private var store: LegalDocumentStore

    init(store: LegalDocumentStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        LoadableView(state: store.state.document, retry: { store.send(.retryTapped) }) { document in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header(document)
                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            if !section.heading.isEmpty {
                                Text(section.heading)
                                    .font(.headline)
                                    .accessibilityAddTraits(.isHeader)
                            }
                            Text(section.body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Spacing.xl)
                .textSelection(.enabled)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { store.send(.onAppear) }
    }

    private func header(_ document: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                if !document.version.isEmpty {
                    Text("Versi \(document.version)")
                }
                if let date = document.effectiveDate {
                    Text("· Berlaku \(date.formatted(.dateTime.day().month(.wide).year().locale(appLocale)))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let summary = document.summary {
                Label {
                    Text(summary).fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "hand.raised.fill").foregroundStyle(Color.brand)
                }
                .font(.subheadline)
                .padding(Spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.brandSoft, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            }
        }
    }
}
