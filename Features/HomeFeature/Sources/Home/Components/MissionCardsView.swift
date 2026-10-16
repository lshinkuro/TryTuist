//
//  MissionCardsView.swift
//  HomeFeature
//
import SwiftUI

/// Kartu misi yang bisa di-swipe kiri/kanan (pengganti `MissionCell`).
/// Catatan: seperti sebelumnya, section ini belum ditampilkan di `HomeView`.
struct MissionCardsView: View {
    private let colors: [Color] = [.red, .green, .blue, .yellow]
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 10)
                .fill(colors[currentIndex])
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation.width }
                        .onEnded { value in
                            let width = proxy.size.width
                            let shouldSwipe = abs(value.predictedEndTranslation.width) > width
                                || abs(value.translation.width) > width / 2
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if shouldSwipe {
                                    let step = value.translation.width < 0 ? 1 : -1
                                    currentIndex = (currentIndex + step + colors.count) % colors.count
                                }
                                dragOffset = 0
                            }
                        }
                )
        }
        .frame(height: 120)
        .padding(20)
    }
}
