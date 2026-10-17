//
//  ToastEffect.swift
//  HomeFeature · Presentation
//
import Foundation
import Utility

/// Effect standar: tunggu sebentar lalu kirim action untuk menutup toast dengan `id` tsb.
/// Menggunakan id supaya toast baru tidak ikut tertutup oleh timer toast lama.
func dismissToastEffect<Action>(id: UUID, after seconds: Double = 2, _ action: @escaping (UUID) -> Action) -> Effect<Action> {
    .task {
        try? await Task.sleep(for: .seconds(seconds))
        return action(id)
    }
}
