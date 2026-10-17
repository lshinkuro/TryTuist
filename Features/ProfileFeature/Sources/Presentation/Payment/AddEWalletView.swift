//
//  AddEWalletView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct AddEWalletView: View {
    @StateObject private var store: AddEWalletStore

    init(store: AddEWalletStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: AddEWalletState { store.state }

    private let columns = [GridItem(.flexible(), spacing: Spacing.m), GridItem(.flexible(), spacing: Spacing.m)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Pilih e-wallet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: Spacing.m) {
                        ForEach(state.providers) { provider in
                            providerTile(provider)
                        }
                    }
                    if let error = state.fieldErrors["provider"] {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                InputFieldView(title: "Nomor HP terdaftar di \(state.selectedProvider?.name ?? "e-wallet")",
                               placeholder: "081234567890",
                               text: store.binding(\.wallet.accountNumber, send: { .accountNumberChanged($0) }),
                               systemImage: "phone",
                               keyboardType: .phonePad,
                               contentType: .telephoneNumber,
                               errorMessage: state.fieldErrors["account_number"])

                InputFieldView(title: "Nama pemilik akun (opsional)",
                               placeholder: "Sesuai nama di e-wallet",
                               text: store.binding(\.wallet.accountName, send: { .accountNameChanged($0) }),
                               systemImage: "person",
                               contentType: .name,
                               errorMessage: state.fieldErrors["account_name"])

                Toggle("Jadikan metode utama",
                       isOn: store.binding(\.wallet.setAsDefault, send: { .setAsDefaultToggled($0) }))
                    .tint(.brand)
                    .padding(Spacing.l)
                    .formCard(cornerRadius: Radius.control)

                Label("Nomor hanya dipakai untuk menagih pembayaran dan ditampilkan tersamar.",
                      systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            BottomActionBar(title: "Tautkan", isLoading: state.isSaving, isEnabled: true) {
                store.send(.saveTapped)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Batal") { store.send(.cancelTapped) }
                    .disabled(state.isSaving)
            }
        }
        .interactiveDismissDisabled(state.isSaving)
        .alert("Gagal menautkan",
               isPresented: store.binding(\.isShowingError, send: { _ in .errorDismissed })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.errorMessage ?? "")
        }
    }

    private func providerTile(_ provider: EWalletProvider) -> some View {
        let isSelected = state.wallet.providerID == provider.id
        let tint = Color.named(provider.tint)
        return Button {
            store.send(.providerSelected(provider.id))
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: provider.systemImage)
                    .foregroundStyle(tint)
                Text(provider.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.brand)
                }
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                    .stroke(isSelected ? Color.brand : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
