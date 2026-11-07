//
//  ShoppingListView.swift
//  HomeFeature · Presentation
//
import PhotosUI
import SwiftUI
import TTUI

struct ShoppingListView: View {
    @StateObject private var store: ShoppingListStore
    @State private var photo: PhotosPickerItem?
    @State private var isCameraPresented = false
    private var state: ShoppingListState { store.state }

    init(store: ShoppingListStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text(state.isSmart
                     ? "Tulis resep, rencana masak, atau daftar belanja. AI akan memilihkan produknya."
                     : "Tulis daftar belanja, satu barang per baris. Contoh: 2 beras")
                    .font(.appSubhead)
                    .foregroundStyle(.secondary)

                TextField(state.isSmart ? "Contoh: masak rendang untuk 5 orang" : "Contoh:\n2 beras\nminyak goreng\n1 gula pasir",
                          text: store.binding(\.text, send: { .textChanged($0) }), axis: .vertical)
                    .lineLimit(4...10)
                    .padding(Spacing.m)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))

                HStack(spacing: Spacing.m) {
                    PhotosPicker(selection: $photo, matching: .images) {
                        if state.isRecognizing {
                            ProgressView()
                        } else {
                            Label("Scan catatan", systemImage: "doc.text.viewfinder")
                        }
                    }
                    .buttonStyle(CapsuleButtonStyle(.outlined))
                    .disabled(state.isRecognizing || state.isPlanning)

                    // Simulator & perangkat tanpa kamera: hanya pilih dari galeri.
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { isCameraPresented = true } label: {
                            Image(systemName: "camera")
                        }
                        .buttonStyle(CapsuleButtonStyle(.outlined))
                        .disabled(state.isRecognizing || state.isPlanning)
                        .accessibilityLabel("Foto catatan")
                    }

                    Spacer()

                    Button { store.send(.planTapped) } label: {
                        if state.isPlanning { ProgressView() } else { Label("Susun", systemImage: state.isSmart ? "sparkles" : "list.bullet") }
                    }
                    .buttonStyle(CapsuleButtonStyle(.filled))
                    .disabled(!state.canPlan)
                }

                if let error = state.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.appCaption)
                        .foregroundStyle(.red)
                }

                if state.didPlan && state.items.isEmpty {
                    Text("Belum ada produk yang cocok. Coba tulis nama barangnya lebih jelas.")
                        .font(.appSubhead)
                        .foregroundStyle(.secondary)
                }

                if !state.items.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(state.items) { item in
                            row(item)
                            if item.id != state.items.last?.id { Divider() }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                }
            }
            .padding(Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if !state.items.isEmpty {
                PrimaryButton(String(localized: "Tambah \(state.selectedCount) ke keranjang"),
                              isLoading: state.isAdding, isEnabled: state.canAdd) {
                    store.send(.addTapped)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.m)
                .background(.bar)
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.9) { store.send(.photoPicked(data)) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            photo = nil
            Task { @MainActor in
                if let data = try? await item.loadTransferable(type: Data.self) { store.send(.photoPicked(data)) }
            }
        }
    }

    private func row(_ item: ShoppingListItem) -> some View {
        HStack(spacing: Spacing.m) {
            Button { store.send(.itemToggled(item.id)) } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isSelected ? Color.brand : Color.secondary)
            }
            .accessibilityLabel(item.isSelected ? String(localized: "Batal pilih \(item.product.name)") : String(localized: "Pilih \(item.product.name)"))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name).font(.appSubheadStrong)
                Text(item.product.price.rupiahFormatted).font(.appCaption).foregroundStyle(.secondary)
            }
            Spacer()
            Stepper(value: Binding(get: { item.quantity },
                                   set: { store.send(.quantityChanged(id: item.id, delta: $0 - item.quantity)) }),
                    in: AddToCartUseCase.quantityRange) {
                Text("\(item.quantity)").font(.appSubheadStrong).monospacedDigit()
            }
            .fixedSize()
        }
        .padding(.vertical, Spacing.m)
        .opacity(item.isSelected ? 1 : 0.5)
    }
}

/// Kamera bawaan (UIImagePickerController); foto tidak disimpan ke galeri.
private struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
