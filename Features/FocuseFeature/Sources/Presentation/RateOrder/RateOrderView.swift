//
//  RateOrderView.swift
//  FocuseFeature · Presentation
//
import SwiftUI
import TTUI

struct RateOrderView: View {
    @StateObject private var store: RateOrderStore

    init(store: RateOrderStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(store.state.order.productName).font(.headline)
                    Text(store.state.order.createdAt.shortDateTimeFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: Spacing.m) {
                    ForEach(RateOrderUseCase.ratingRange, id: \.self) { star in
                        Button { store.send(.starTapped(star)) } label: {
                            Image(systemName: star <= store.state.rating ? "star.fill" : "star")
                                .font(.largeTitle)
                                .foregroundStyle(star <= store.state.rating ? Color.orange : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(star) bintang")
                        .accessibilityAddTraits(star == store.state.rating ? .isSelected : [])
                    }
                }
                .frame(maxWidth: .infinity)

                InputFieldView(title: "Komentar (opsional)",
                               placeholder: "Ceritakan pesananmu",
                               text: store.binding(\.comment, send: RateOrderAction.commentChanged),
                               errorMessage: store.state.errorMessage)

                PrimaryButton("Kirim Penilaian",
                              isLoading: store.state.isSubmitting,
                              isEnabled: store.state.rating > 0) {
                    store.send(.submitTapped)
                }
            }
            .padding(Spacing.xl)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}
