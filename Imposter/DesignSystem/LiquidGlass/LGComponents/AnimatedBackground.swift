//
//  AnimatedBackground.swift
//  Imposter
//
//  Animated background with floating particles and mesh gradients.
//  Adds visual life and depth to the app.
//

import SwiftUI

// MARK: - Floating Particle

/// A single floating particle with position and animation state
struct FloatingParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var color: Color
    var speed: CGFloat
    var phase: CGFloat  // For wave motion
}

// MARK: - Animated Background View

/// Animated background with floating particles and gradient
struct AnimatedBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var particles: [FloatingParticle] = []
    @State private var animationPhase: CGFloat = 0

    let style: BackgroundStyle

    enum BackgroundStyle {
        case home           // Dark dramatic with red accents
        case gameplay       // Cool blues and cyans
        case imposter       // Ominous red/purple
        case celebration    // Vibrant multi-color
        case subtle         // Minimal particles, adaptive
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                baseGradient

                // Mesh gradient layer (iOS 18+)
                meshGradientLayer

                // Floating particles
                particleLayer(in: geometry.size)

                // Ambient glow orbs
                glowOrbsLayer(in: geometry.size)

                // Noise texture overlay for depth
                noiseOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }

    // MARK: - Base Gradient

    private var baseGradient: some View {
        LinearGradient(
            colors: baseGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var baseGradientColors: [Color] {
        let isDark = colorScheme == .dark

        // Pitch black background for dark mode
        let pureBlack = Color.black

        switch style {
        case .home:
            return isDark
                ? [pureBlack, pureBlack, pureBlack]
                : [Color(red: 0.98, green: 0.98, blue: 0.98),
                   Color(red: 0.96, green: 0.96, blue: 0.96),
                   Color(red: 0.98, green: 0.98, blue: 0.98)]

        case .gameplay:
            return isDark
                ? [pureBlack, pureBlack, pureBlack]
                : [Color(red: 0.98, green: 0.98, blue: 0.98),
                   Color(red: 0.96, green: 0.96, blue: 0.96),
                   Color(red: 0.98, green: 0.98, blue: 0.98)]

        case .imposter:
            return isDark
                ? [pureBlack, pureBlack, pureBlack]
                : [Color(red: 0.98, green: 0.96, blue: 0.96),
                   Color(red: 0.97, green: 0.95, blue: 0.95),
                   Color(red: 0.98, green: 0.96, blue: 0.96)]

        case .celebration:
            return isDark
                ? [pureBlack, pureBlack, pureBlack]
                : [Color(red: 0.98, green: 0.98, blue: 0.98),
                   Color(red: 0.96, green: 0.96, blue: 0.96),
                   Color(red: 0.98, green: 0.98, blue: 0.98)]

        case .subtle:
            return isDark
                ? [pureBlack, pureBlack]
                : [Color(red: 0.98, green: 0.98, blue: 0.98),
                   Color(red: 0.96, green: 0.96, blue: 0.96)]
        }
    }

    // MARK: - Mesh Gradient

    @ViewBuilder
    private var meshGradientLayer: some View {
        let isDark = colorScheme == .dark
        let centerX: Float = 0.5 + Float(sin(animationPhase) * 0.1)
        let centerY: Float = 0.5 + Float(cos(animationPhase) * 0.1)
        let colors = meshGradientColors(isDark: isDark)

        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                SIMD2<Float>(0.0, 0.5), SIMD2<Float>(centerX, centerY), SIMD2<Float>(1.0, 0.5),
                SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
            ],
            colors: colors
        )
        .opacity(0.4)
        .blur(radius: 60)
    }

    private func meshGradientColors(isDark: Bool) -> [Color] {
        // No colored gradients - keep it clean black
        return [Color].init(repeating: .clear, count: 9)
    }

    // MARK: - Particle Layer

    @ViewBuilder
    private func particleLayer(in size: CGSize) -> some View {
        ForEach(particles) { particle in
            Circle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size)
                .blur(radius: particle.size * 0.3)
                .opacity(particle.opacity)
                .position(
                    x: particle.x * size.width,
                    y: (particle.y + sin(animationPhase * particle.speed + particle.phase) * 0.02) * size.height
                )
        }
    }

    // MARK: - Glow Orbs

    @ViewBuilder
    private func glowOrbsLayer(in size: CGSize) -> some View {
        let isDark = colorScheme == .dark
        let orbColors = glowOrbColors(isDark: isDark)

        ForEach(0..<orbColors.count, id: \.self) { index in
            let progress = CGFloat(index) / CGFloat(orbColors.count)
            let xOffset = sin(animationPhase * 0.3 + progress * .pi * 2) * 0.1
            let yOffset = cos(animationPhase * 0.2 + progress * .pi * 2) * 0.05

            Circle()
                .fill(
                    RadialGradient(
                        colors: [orbColors[index], .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size.width * 0.3
                    )
                )
                .frame(width: size.width * 0.6, height: size.width * 0.6)
                .position(
                    x: size.width * (0.2 + progress * 0.6 + xOffset),
                    y: size.height * (0.3 + progress * 0.4 + yOffset)
                )
                .blur(radius: 80)
        }
    }

    private func glowOrbColors(isDark: Bool) -> [Color] {
        // No colored glow orbs - keep background clean
        return []
    }

    // MARK: - Noise Overlay

    private var noiseOverlay: some View {
        Rectangle()
            .fill(.ultraThinMaterial.opacity(0.02))
    }

    // MARK: - Animation

    private func generateParticles() {
        let count: Int
        switch style {
        case .home, .imposter: count = 25
        case .gameplay: count = 20
        case .celebration: count = 35
        case .subtle: count = 10
        }

        particles = (0..<count).map { _ in
            FloatingParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2...8),
                opacity: CGFloat.random(in: 0.1...0.4),
                color: particleColor(),
                speed: CGFloat.random(in: 0.5...2.0),
                phase: CGFloat.random(in: 0...(.pi * 2))
            )
        }
    }

    private func particleColor() -> Color {
        let isDark = colorScheme == .dark
        // Simple white/gray particles only
        return (isDark ? Color.white : Color.gray).opacity(0.15)
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

// MARK: - Preview

#Preview("Home Background") {
    AnimatedBackground(style: .home)
}

#Preview("Gameplay Background") {
    AnimatedBackground(style: .gameplay)
}

#Preview("Imposter Background") {
    AnimatedBackground(style: .imposter)
}

#Preview("Celebration Background") {
    AnimatedBackground(style: .celebration)
}

#Preview("Light Mode") {
    AnimatedBackground(style: .home)
        .preferredColorScheme(.light)
}
