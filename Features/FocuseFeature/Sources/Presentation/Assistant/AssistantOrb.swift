//
//  AssistantOrb.swift
//  FocuseFeature · Presentation
//
//  Orb asisten ala Siri: gumpalan warna berputar & berdenyut sesuai keadaan.
//  Reduce Motion aktif → orb diam.
//
import SwiftUI

struct AssistantOrb: View {
    enum Mood { case idle, listening, thinking, speaking }

    let mood: Mood
    var size: CGFloat = 96
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let blobColors: [Color] = [.pink, .purple, .cyan]

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let speed: Double = switch mood {
            case .idle: 0.5
            case .listening: 1.0
            case .thinking: 2.2
            case .speaking: 1.2
            }
            let pulse = switch mood {
            case .speaking: 1 + 0.07 * sin(time * 9)
            case .listening: 1.06 + 0.03 * sin(time * 4)
            default: 1 + 0.025 * sin(time * 2)
            }

            ZStack {
                Circle()
                    .fill(AngularGradient(colors: [.pink, .orange, .purple, .blue, .cyan, .pink],
                                          center: .center, angle: .degrees(time * speed * 50)))
                    .blur(radius: size * 0.12)
                ForEach(Self.blobColors.indices, id: \.self) { index in
                    let phase = time * speed + Double(index) * 2.1
                    Circle()
                        .fill(Self.blobColors[index].gradient)
                        .frame(width: size * 0.6, height: size * 0.6)
                        .offset(x: cos(phase) * size * 0.2, y: sin(phase * 1.3) * size * 0.2)
                        .blur(radius: size * 0.14)
                        .blendMode(.plusLighter)
                }
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.55), .clear], center: UnitPoint(x: 0.35, y: 0.3),
                                         startRadius: 0, endRadius: size * 0.45))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .scaleEffect(pulse)
            .shadow(color: .purple.opacity(0.45), radius: mood == .idle ? size * 0.1 : size * 0.25)
        }
        .frame(width: size * 1.15, height: size * 1.15)
        .animation(.easeInOut(duration: 0.4), value: mood)
        .accessibilityHidden(true)
    }
}
