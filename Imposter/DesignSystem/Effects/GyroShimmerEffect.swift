//
//  GyroShimmerEffect.swift
//  Imposter
//
//  Holographic shimmer effect that responds to device motion.
//

import SwiftUI
#if canImport(CoreMotion)
import CoreMotion
#endif

// MARK: - Motion Manager

/// Manages device motion updates for shimmer effects
@MainActor
@Observable
final class MotionManager {
    static let shared = MotionManager()

    #if canImport(CoreMotion)
    private let motionManager = CMMotionManager()
    #endif
    private(set) var pitch: Double = 0
    private(set) var roll: Double = 0

    private init() {
        startMotionUpdates()
    }

    private func startMotionUpdates() {
        #if canImport(CoreMotion)
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion = motion else { return }

            Task { @MainActor in
                withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.8)) {
                    self?.pitch = motion.attitude.pitch
                    self?.roll = motion.attitude.roll
                }
            }
        }
        #endif
    }

    func stop() {
        #if canImport(CoreMotion)
        motionManager.stopDeviceMotionUpdates()
        #endif
    }
}

// MARK: - Shimmer Gradient View

/// A holographic shimmer overlay that responds to device tilt
struct GyroShimmerOverlay: View {
    @State private var motionManager = MotionManager.shared
    let intensity: Double
    let colors: [Color]

    init(
        intensity: Double = 0.4,
        colors: [Color] = [
            .clear,
            .white.opacity(0.1),
            .white.opacity(0.3),
            .cyan.opacity(0.2),
            .purple.opacity(0.2),
            .white.opacity(0.3),
            .white.opacity(0.1),
            .clear
        ]
    ) {
        self.intensity = intensity
        self.colors = colors
    }

    var body: some View {
        GeometryReader { geometry in
            let offsetX = motionManager.roll * geometry.size.width * intensity
            let offsetY = motionManager.pitch * geometry.size.height * intensity

            LinearGradient(
                colors: colors,
                startPoint: UnitPoint(
                    x: 0.5 + (offsetX / geometry.size.width),
                    y: 0 + (offsetY / geometry.size.height)
                ),
                endPoint: UnitPoint(
                    x: 0.5 - (offsetX / geometry.size.width),
                    y: 1 - (offsetY / geometry.size.height)
                )
            )
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Rainbow Shimmer (for special reveals)

/// A more dramatic rainbow holographic effect
struct RainbowShimmerOverlay: View {
    @State private var motionManager = MotionManager.shared
    let intensity: Double

    init(intensity: Double = 0.5) {
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            let offsetX = motionManager.roll * intensity
            let offsetY = motionManager.pitch * intensity

            AngularGradient(
                colors: [
                    .red.opacity(0.3),
                    .orange.opacity(0.3),
                    .yellow.opacity(0.3),
                    .green.opacity(0.3),
                    .cyan.opacity(0.3),
                    .blue.opacity(0.3),
                    .purple.opacity(0.3),
                    .red.opacity(0.3)
                ],
                center: UnitPoint(
                    x: 0.5 + offsetX,
                    y: 0.5 + offsetY
                )
            )
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Spotlight Shimmer

/// A moving spotlight effect based on device tilt
struct SpotlightShimmerOverlay: View {
    @State private var motionManager = MotionManager.shared
    let color: Color
    let intensity: Double

    init(color: Color = .white, intensity: Double = 0.6) {
        self.color = color
        self.intensity = intensity
    }

    var body: some View {
        GeometryReader { geometry in
            let centerX = 0.5 + (motionManager.roll * intensity)
            let centerY = 0.5 + (motionManager.pitch * intensity)

            RadialGradient(
                colors: [
                    color.opacity(0.4),
                    color.opacity(0.1),
                    .clear
                ],
                center: UnitPoint(x: centerX, y: centerY),
                startRadius: 0,
                endRadius: max(geometry.size.width, geometry.size.height) * 0.8
            )
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - View Modifier

/// Adds a gyroscope-reactive shimmer effect to any view
struct GyroShimmerModifier: ViewModifier {
    enum ShimmerStyle {
        case subtle
        case holographic
        case rainbow
        case spotlight(Color)
        case imposter
    }

    let style: ShimmerStyle
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                shimmerOverlay
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        switch style {
        case .subtle:
            GyroShimmerOverlay(intensity: 0.3)
        case .holographic:
            GyroShimmerOverlay(intensity: 0.5, colors: [
                .clear,
                .white.opacity(0.15),
                .cyan.opacity(0.2),
                .white.opacity(0.3),
                .purple.opacity(0.2),
                .white.opacity(0.15),
                .clear
            ])
        case .rainbow:
            RainbowShimmerOverlay(intensity: 0.4)
        case .spotlight(let color):
            SpotlightShimmerOverlay(color: color, intensity: 0.5)
        case .imposter:
            // Red-tinted dramatic shimmer for imposter card
            GyroShimmerOverlay(intensity: 0.6, colors: [
                .clear,
                .red.opacity(0.1),
                .orange.opacity(0.15),
                .red.opacity(0.2),
                .purple.opacity(0.15),
                .red.opacity(0.1),
                .clear
            ])
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds a gyroscope-reactive shimmer effect
    /// - Parameters:
    ///   - style: The shimmer style to apply
    ///   - cornerRadius: Corner radius to clip the shimmer
    func gyroShimmer(
        _ style: GyroShimmerModifier.ShimmerStyle = .holographic,
        cornerRadius: CGFloat = LGSpacing.cornerRadiusLarge
    ) -> some View {
        modifier(GyroShimmerModifier(style: style, cornerRadius: cornerRadius))
    }
}

// MARK: - Preview

#Preview("Shimmer Effects") {
    ZStack {
        LinearGradient(
            colors: [.black, .gray.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            // Subtle shimmer
            RoundedRectangle(cornerRadius: 20)
                .fill(.blue.gradient)
                .frame(height: 100)
                .gyroShimmer(.subtle)
                .overlay {
                    Text("Subtle")
                        .foregroundStyle(.white)
                }

            // Holographic
            RoundedRectangle(cornerRadius: 20)
                .fill(.purple.gradient)
                .frame(height: 100)
                .gyroShimmer(.holographic)
                .overlay {
                    Text("Holographic")
                        .foregroundStyle(.white)
                }

            // Rainbow
            RoundedRectangle(cornerRadius: 20)
                .fill(.indigo.gradient)
                .frame(height: 100)
                .gyroShimmer(.rainbow)
                .overlay {
                    Text("Rainbow")
                        .foregroundStyle(.white)
                }

            // Imposter
            RoundedRectangle(cornerRadius: 20)
                .fill(.red.opacity(0.8).gradient)
                .frame(height: 100)
                .gyroShimmer(.imposter)
                .overlay {
                    Text("Imposter")
                        .foregroundStyle(.white)
                }
        }
        .padding()
    }
}
