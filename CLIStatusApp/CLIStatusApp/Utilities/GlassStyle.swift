//
//  GlassStyle.swift
//  CLIStatusApp
//
//  Liquid Glass inspired styling helpers
//  Provides reusable glass panels, strokes, and background accents
//

import SwiftUI

struct GlassPanelStyle: ViewModifier {
    let cornerRadius: CGFloat
    let material: Material
    let strokeOpacity: Double
    let highlightOpacity: Double
    let shadow: Shadow

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(highlightOpacity),
                                        Color.white.opacity(highlightOpacity * 0.25),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 0.6)
            }
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

extension View {
    func glassPanel(
        cornerRadius: CGFloat = AppCornerRadius.lg,
        material: Material = .ultraThinMaterial,
        strokeOpacity: Double = 0.18,
        highlightOpacity: Double = 0.25,
        shadow: Shadow = AppShadow.md
    ) -> some View {
        modifier(
            GlassPanelStyle(
                cornerRadius: cornerRadius,
                material: material,
                strokeOpacity: strokeOpacity,
                highlightOpacity: highlightOpacity,
                shadow: shadow
            )
        )
    }
}

struct GlassBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.18),
                    Color.brandSecondary.opacity(0.12),
                    Color.surfaceGrouped.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.brandPrimary.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: -80, y: -120)

            Circle()
                .fill(Color.brandSecondary.opacity(0.2))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: 120, y: 80)
        }
        .ignoresSafeArea()
    }
}
