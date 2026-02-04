//
//  LGCard.swift
//  Imposter
//
//  Reusable card component with Liquid Glass effect.
//

import SwiftUI
#if canImport(CoreMotion)
import CoreMotion
#endif

// MARK: - LGCard

/// A card container with Liquid Glass background effect.
/// Automatically applies appropriate padding, border, and shadow.
struct LGCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let elevation: CGFloat

    /// Creates a new Liquid Glass card
    /// - Parameters:
    ///   - cornerRadius: The corner radius of the card
    ///   - elevation: Shadow elevation level (1, 2, or 3)
    ///   - content: The content to display inside the card
    init(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        elevation: CGFloat = LGMaterials.elevation2,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(.all, LGSpacing.medium)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            }
            .lgShadow(elevation)
    }
}

// MARK: - Gyro-Reactive Liquid Glass Card

/// A premium card with gyroscope-reactive liquid glass effects
/// The card subtly tilts, shifts highlights, and creates depth based on device motion
struct LGGyroCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let elevation: CGFloat
    let tintColor: Color?
    let enableParallax: Bool
    let enableHighlight: Bool
    let highlightIntensity: Double
    
    @State private var motionManager = MotionManager.shared
    
    init(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusLarge,
        elevation: CGFloat = LGMaterials.elevation3,
        tintColor: Color? = nil,
        enableParallax: Bool = true,
        enableHighlight: Bool = true,
        highlightIntensity: Double = 0.6,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.tintColor = tintColor
        self.enableParallax = enableParallax
        self.enableHighlight = enableHighlight
        self.highlightIntensity = highlightIntensity
        self.content = content()
    }
    
    private var tiltX: Double {
        motionManager.pitch * 8 // Subtle 3D tilt effect
    }
    
    private var tiltY: Double {
        motionManager.roll * 8
    }
    
    private var highlightOffset: CGPoint {
        CGPoint(
            x: motionManager.roll * 100 * highlightIntensity,
            y: motionManager.pitch * 100 * highlightIntensity
        )
    }
    
    var body: some View {
        content
            .padding(.all, LGSpacing.medium)
            .background {
                // Base glass layer
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        tintColor != nil ? .regular.tint(tintColor!) : .regular,
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
            .overlay {
                // Gyro-reactive liquid highlight
                if enableHighlight {
                    LiquidHighlightOverlay(
                        cornerRadius: cornerRadius,
                        offset: highlightOffset,
                        intensity: highlightIntensity
                    )
                }
            }
            .overlay {
                // Subtle edge highlight that moves with tilt
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4 + motionManager.pitch * 0.2),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.2 + motionManager.roll * 0.15)
                            ],
                            startPoint: UnitPoint(x: 0.5 - motionManager.roll * 0.3, y: 0),
                            endPoint: UnitPoint(x: 0.5 + motionManager.roll * 0.3, y: 1)
                        ),
                        lineWidth: 1.5
                    )
            }
            .rotation3DEffect(
                .degrees(enableParallax ? tiltX : 0),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(enableParallax ? -tiltY : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .lgShadow(elevation)
            // Dynamic shadow that shifts with tilt
            .shadow(
                color: (tintColor ?? .black).opacity(0.15),
                radius: 20,
                x: CGFloat(motionManager.roll * 10),
                y: CGFloat(motionManager.pitch * 10) + 8
            )
    }
}

// MARK: - Liquid Highlight Overlay

/// Creates a moving liquid-like highlight effect based on device tilt
struct LiquidHighlightOverlay: View {
    let cornerRadius: CGFloat
    let offset: CGPoint
    let intensity: Double
    
    var body: some View {
        GeometryReader { geometry in
            // Primary highlight blob
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.35 * intensity),
                            Color.white.opacity(0.15 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.6
                    )
                )
                .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.5)
                .offset(x: offset.x, y: offset.y - geometry.size.height * 0.15)
                .blur(radius: 30)
            
            // Secondary smaller highlight for depth
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.25 * intensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.3
                    )
                )
                .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.25)
                .offset(x: offset.x * 1.5, y: offset.y * 1.5 - geometry.size.height * 0.25)
                .blur(radius: 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Liquid Glass Refraction Effect

/// Creates a subtle color refraction effect like light through glass
struct LiquidRefractionOverlay: View {
    let cornerRadius: CGFloat
    @State private var motionManager = MotionManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            let offsetX = motionManager.roll * 0.5
            let offsetY = motionManager.pitch * 0.5
            
            ZStack {
                // Cyan refraction edge (left/top)
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: UnitPoint(x: 0 + offsetX, y: 0 + offsetY),
                    endPoint: UnitPoint(x: 0.3 + offsetX, y: 0.3 + offsetY)
                )
                
                // Magenta refraction edge (right/bottom)
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.purple.opacity(0.1)
                    ],
                    startPoint: UnitPoint(x: 0.7 - offsetX, y: 0.7 - offsetY),
                    endPoint: UnitPoint(x: 1 - offsetX, y: 1 - offsetY)
                )
            }
            .blendMode(.overlay)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Tinted Card Variant

/// A card with a colored tint on the glass effect
struct LGTintedCard<Content: View>: View {
    let content: Content
    let tintColor: Color
    let cornerRadius: CGFloat
    let elevation: CGFloat

    init(
        tintColor: Color,
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        elevation: CGFloat = LGMaterials.elevation2,
        @ViewBuilder content: () -> Content
    ) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(.all, LGSpacing.medium)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(tintColor),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(tintColor.opacity(0.3), lineWidth: 1)
            }
            .lgShadow(elevation)
    }
}

// MARK: - Interactive Card

/// A card that responds to touch with interactive glass effects
struct LGInteractiveCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let action: () -> Void

    init(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(.all, LGSpacing.medium)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.clear)
                        .glassEffect(
                            .regular.interactive(),
                            in: .rect(cornerRadius: cornerRadius, style: .continuous)
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .lgShadow(LGMaterials.elevation2)
    }
}

// MARK: - View Extension for Gyro Glass

extension View {
    /// Adds a gyroscope-reactive liquid glass card wrapper
    func liquidGlassCard(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusLarge,
        tintColor: Color? = nil,
        enableParallax: Bool = true
    ) -> some View {
        LGGyroCard(
            cornerRadius: cornerRadius,
            tintColor: tintColor,
            enableParallax: enableParallax
        ) {
            self
        }
    }
}

// MARK: - Preview

#Preview("LGCard Variants") {
    ZStack {
        LinearGradient(
            colors: [.purple, .blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: LGSpacing.large) {
            LGCard {
                VStack(alignment: .leading, spacing: LGSpacing.small) {
                    Text("Standard Card")
                        .font(LGTypography.headlineSmall)
                    Text("This is a Liquid Glass card with default settings.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }

            LGTintedCard(tintColor: .blue) {
                VStack(alignment: .leading, spacing: LGSpacing.small) {
                    Text("Tinted Card")
                        .font(LGTypography.headlineSmall)
                    Text("This card has a blue tint applied.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }

            LGInteractiveCard(action: { print("Tapped!") }) {
                HStack {
                    Text("Interactive Card")
                        .font(LGTypography.headlineSmall)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding()
    }
}

#Preview("Gyro-Reactive Card") {
    ZStack {
        AnimatedBackground(style: .gameplay)

        VStack(spacing: LGSpacing.extraLarge) {
            Text("Tilt your device")
                .font(LGTypography.headlineSmall)
                .foregroundStyle(.white.opacity(0.7))
            
            LGGyroCard(tintColor: .cyan) {
                VStack(spacing: LGSpacing.medium) {
                    Image(systemName: "gyroscope")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Gyro-Reactive Card")
                        .font(LGTypography.headlineMedium)
                    
                    Text("This card responds to device motion with parallax, shifting highlights, and dynamic shadows.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .frame(maxWidth: 320)
        }
        .padding()
    }
}
