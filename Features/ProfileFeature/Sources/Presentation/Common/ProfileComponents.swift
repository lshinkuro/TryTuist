//
//  ProfileComponents.swift
//  ProfileFeature · Presentation
//
//  Komponen kecil yang dipakai beberapa screen Profil. Tanpa logika → tanpa Store.
//
import SwiftUI
import TTUI
import Utility

/// Menampilkan loading / error + tombol coba lagi / konten untuk `Loadable`.
struct LoadableView<Value, Content: View>: View {
    let state: Loadable<Value>
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Gagal memuat", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Coba lagi", action: retry)
                .buttonStyle(CapsuleButtonStyle(.filled))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Baris menu dengan ikon berwarna dan chevron.
struct ProfileMenuRow: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    let tint: Color
    var showsChevron = true

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemImage: systemImage, tint: tint, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Spacing.s)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Spacing.l)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

/// Tombol simpan yang menempel di bawah form.
struct BottomActionBar: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        PrimaryButton(title, isLoading: isLoading, isEnabled: isEnabled, action: action)
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.m)
            .padding(.bottom, Spacing.s)
            .background(.bar)
    }
}

extension Color {
    /// Warna dari nama yang dikirim backend ("blue", "teal", …).
    static func named(_ name: String, fallback: Color = .brand) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "gray", "grey": return .gray
        default: return fallback
        }
    }
}

/// Tunggu sebentar lalu kirim action penutup toast dengan `id` tsb (toast baru tidak ikut tertutup).
func dismissToast<Action>(id: UUID, after seconds: Double = 2, _ action: @escaping (UUID) -> Action) -> Effect<Action> {
    .task {
        try? await Task.sleep(for: .seconds(seconds))
        return action(id)
    }
}
