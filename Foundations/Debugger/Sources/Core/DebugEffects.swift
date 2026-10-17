//
//  DebugEffects.swift
//  Debugger
//
//  Effect kecil yang dipakai beberapa Store Debugger.
//
import UIKit
import Utility

/// Salin teks ke clipboard, tunggu sebentar, lalu kirim action penutup toast dengan `id` tsb.
func copyEffect<Action>(_ text: String, toastID: UUID, dismiss: @escaping (UUID) -> Action) -> Effect<Action> {
    .task {
        await MainActor.run { UIPasteboard.general.string = text }
        try? await Task.sleep(for: .seconds(1.6))
        return dismiss(toastID)
    }
}

func dismissToastEffect<Action>(id: UUID, after seconds: Double = 1.6, _ action: @escaping (UUID) -> Action) -> Effect<Action> {
    .task {
        try? await Task.sleep(for: .seconds(seconds))
        return action(id)
    }
}
