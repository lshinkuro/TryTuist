//
//  EditProfileView.swift
//  ProfileFeature · Presentation
//
import SwiftUI
import TTUI

struct EditProfileView: View {
    @StateObject private var store: EditProfileStore

    init(store: EditProfileStore) {
        _store = StateObject(wrappedValue: store)
    }

    private var state: EditProfileState { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                AvatarView(name: state.name.isEmpty ? state.original.name : state.name, size: 88)
                    .padding(.top, Spacing.l)

                VStack(spacing: Spacing.l) {
                    InputFieldView(title: String(localized: "Nama"),
                                   placeholder: String(localized: "Nama lengkap"),
                                   text: store.binding(\.name, send: { .nameChanged($0) }),
                                   systemImage: "person",
                                   contentType: .name,
                                   errorMessage: state.fieldErrors["name"])

                    InputFieldView(title: String(localized: "Nomor HP"),
                                   placeholder: "081234567890",
                                   text: store.binding(\.phone, send: { .phoneChanged($0) }),
                                   systemImage: "phone",
                                   keyboardType: .phonePad,
                                   contentType: .telephoneNumber,
                                   errorMessage: state.fieldErrors["phone"])

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        HStack(spacing: Spacing.m) {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            Text(state.email)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, Spacing.l)
                        .frame(height: 52)
                        .background(Color.fieldBackground.opacity(0.6),
                                    in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                        Text("Email dipakai untuk masuk dan tidak bisa diubah.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(Spacing.l)
                .formCard()
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            BottomActionBar(title: String(localized: "Simpan"), isLoading: state.isSaving, isEnabled: store.hasChanges) {
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
}
