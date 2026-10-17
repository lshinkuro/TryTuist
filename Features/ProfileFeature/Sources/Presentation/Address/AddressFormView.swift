//
//  AddressFormView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct AddressFormView: View {
    @StateObject private var store: AddressFormStore

    init(store: AddressFormStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: AddressFormState { store.state }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                labelSection

                InputFieldView(title: "Nama penerima",
                               placeholder: "Nama yang menerima pesanan",
                               text: store.binding(\.draft.recipient, send: { .textChanged(.recipient, $0) }),
                               systemImage: "person",
                               contentType: .name,
                               errorMessage: state.fieldErrors["recipient"])

                InputFieldView(title: "Nomor HP penerima",
                               placeholder: "081234567890",
                               text: store.binding(\.draft.phone, send: { .textChanged(.phone, $0) }),
                               systemImage: "phone",
                               keyboardType: .phonePad,
                               contentType: .telephoneNumber,
                               errorMessage: state.fieldErrors["phone"])

                MultilineField(title: "Alamat lengkap",
                               placeholder: "Nama jalan, nomor rumah, RT/RW, kelurahan, kota",
                               text: store.binding(\.draft.address, send: { .textChanged(.address, $0) }),
                               errorMessage: state.fieldErrors["address"])

                MultilineField(title: "Catatan untuk kurir (opsional)",
                               placeholder: "Mis. pagar hitam, titip ke satpam",
                               text: store.binding(\.draft.notes, send: { .textChanged(.notes, $0) }),
                               errorMessage: state.fieldErrors["notes"])

                Toggle(isOn: store.binding(\.draft.isDefault, send: { .defaultToggled($0) })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jadikan alamat utama")
                        Text("Dipakai otomatis saat pesan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.brand)
                .padding(Spacing.l)
                .formCard(cornerRadius: Radius.control)
            }
            .padding(Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            BottomActionBar(title: "Simpan Alamat", isLoading: state.isSaving, isEnabled: true) {
                store.send(.saveTapped)
            }
        }
        .alert("Gagal menyimpan",
               isPresented: store.binding(\.isShowingError, send: { _ in .errorDismissed })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(state.errorMessage ?? "")
        }
    }

    private var labelSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            InputFieldView(title: "Label alamat",
                           placeholder: "Rumah, Kantor, …",
                           text: store.binding(\.draft.label, send: { .textChanged(.label, $0) }),
                           systemImage: "tag",
                           errorMessage: state.fieldErrors["label"])
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(state.labelSuggestions, id: \.self) { label in
                        let isSelected = state.draft.label == label
                        Button(label) { store.send(.labelSuggestionTapped(label)) }
                            .buttonStyle(CapsuleButtonStyle(isSelected ? .filled : .outlined))
                    }
                }
            }
        }
    }
}

/// Text field beberapa baris dengan gaya yang sama seperti InputFieldView.
private struct MultilineField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let errorMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...5)
                .focused($isFocused)
                .padding(Spacing.l)
                .background(Color.fieldBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .stroke(errorMessage != nil ? Color.red : (isFocused ? Color.brand : .clear), lineWidth: 1.5)
                )
                .accessibilityLabel(title)
            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
