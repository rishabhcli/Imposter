//
//  RoleCardView.swift
//  Imposter
//
//  Premium card showing a player's role with gyro-reactive liquid glass effects.
//

import SwiftUI
import CoreMotion

// MARK: - Role Enum

/// The player's role in the game
enum Role {
    case informed(word: String)
    case imposter(hint: String)
}

// MARK: - RoleCardView

/// Displays a player's role during the reveal phase with premium liquid glass design
struct RoleCardView: View {
    let role: Role
    let playerName: String
    let playerEmoji: String
    let playerColor: PlayerColor
    let generatedImage: UIImage?
    var isGeneratingImage: Bool = false
    
    @State private var motionManager = MotionManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: LGSpacing.medium) {
                // Player info ABOVE the card
                playerHeader

                // The actual premium liquid glass card
                premiumLiquidGlassCard(size: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Premium Liquid Glass Card
    
    private func premiumLiquidGlassCard(size: CGSize) -> some View {
        let width = cardWidth(for: size)
        let height = cardHeight(for: size)
        let hasImage = generatedImage != nil && !isImposterRole
        
        return cardContent
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .background {
                // Glass effect for cards without image
                if !hasImage {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.clear)
                        .glassEffect(
                            .regular.tint(roleTintColor.opacity(0.2)),
                            in: .rect(cornerRadius: 24, style: .continuous)
                        )
                }
            }
            .overlay {
                // Simple border
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            // Subtle shadow
            .shadow(color: shadowColor.opacity(0.4), radius: 25, y: 10)
    }
    
    private var isImposterRole: Bool {
        if case .imposter = role { return true }
        return false
    }

    private func cardWidth(for size: CGSize) -> CGFloat {
        // Account for player header (~150pt) and spacing when calculating max width from height
        let availableHeight = size.height - 180
        let maxWidthFromHeight = availableHeight * (3.0 / 4.0)
        let maxWidthFromWidth = size.width - 32
        return min(min(maxWidthFromWidth, maxWidthFromHeight), 320)
    }

    private func cardHeight(for size: CGSize) -> CGFloat {
        // 3:4 aspect ratio (width:height = 3:4, so height = width * 4/3)
        let width = cardWidth(for: size)
        return width * (4.0 / 3.0)
    }

    // MARK: - Player Header (Above Card)

    private var playerHeader: some View {
        VStack(spacing: LGSpacing.small) {
            // Large emoji avatar with glass effect
            ZStack {
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(LGColors.playerColor(playerColor).opacity(0.3)),
                        in: .circle
                    )
                    .frame(width: 90, height: 90)

                Text(playerEmoji)
                    .font(.system(size: 50))
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.4)
                            ],
                            startPoint: UnitPoint(x: 0.5 - motionManager.roll * 0.3, y: 0),
                            endPoint: UnitPoint(x: 0.5 + motionManager.roll * 0.3, y: 1)
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: LGColors.playerColor(playerColor).opacity(0.5), radius: 15)

            // Player name
            Text(playerName)
                .font(LGTypography.displaySmall)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        ZStack(alignment: .top) {
            // Main content area - fills entire card
            switch role {
            case .informed(let word):
                informedContent(word: word)
            case .imposter(let hint):
                imposterContent(hint: hint)
            }
            
            // Card top banner overlays on top
            cardTopBanner
        }
    }
    
    private var roleTintColor: Color {
        switch role {
        case .informed: return LGColors.accentPrimary
        case .imposter: return LGColors.imposter
        }
    }

    private var cardTopBanner: some View {
        HStack {
            Spacer()
            Text(roleTitle)
                .font(LGTypography.labelSmall)
                .fontWeight(.bold)
                .tracking(3)
                .foregroundStyle(roleTitleColor)
            Spacer()
        }
        .padding(.vertical, LGSpacing.small)
        .background(roleBannerColor.opacity(0.25))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
        )
    }

    // MARK: - Informed Player Content
    
    private func informedContent(word: String) -> some View {
        ZStack {
            // Layer 1: Blurred image fills entire card as seamless background
            if let image = generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 60)
                    .scaleEffect(1.6)
                    .saturation(1.1)
            } else if isGeneratingImage {
                Color.black.opacity(0.2)
                ImageLoadingPlaceholder()
            } else {
                Color.black.opacity(0.15)
            }
            
            // Layer 2: Content - image and text
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 50)
                
                // Sharp image in center (if available)
                if let image = generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Secret word at bottom
                VStack(spacing: 4) {
                    Text("THE SECRET WORD")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.7))

                    Text(word)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .background {
                    // Gradient fade to darker at bottom
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The secret word is \(word). You are not the Imposter.")
    }

    // MARK: - Imposter Content

    private func imposterContent(hint: String) -> some View {
        ZStack {
            // Dark red gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.02, blue: 0.03),
                    Color(red: 0.25, green: 0.04, blue: 0.06),
                    Color(red: 0.15, green: 0.02, blue: 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle vignette effect
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.4)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 250
            )
            
            // Content
            VStack(spacing: LGSpacing.large) {
                Spacer()

                // Imposter icon
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: LGColors.imposter.opacity(0.8), radius: 20)

                // Title
                Text("IMPOSTER")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white)
                    .shadow(color: LGColors.imposter, radius: 10)

                Spacer()

                // Hint section at bottom
                VStack(spacing: LGSpacing.small) {
                    Text("HINT")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.5))

                    Text(hint)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                }
                .padding(.horizontal, LGSpacing.large)
                .padding(.vertical, LGSpacing.medium)
                .frame(maxWidth: .infinity)
                .background {
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .padding(.top, 40) // Account for banner
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You are the Imposter! Your hint is: \(hint).")
    }

    // MARK: - Styling

    private var roleTitle: String {
        switch role {
        case .informed: return "INFORMED"
        case .imposter: return "IMPOSTER"
        }
    }

    private var roleTitleColor: Color {
        switch role {
        case .informed: return LGColors.success
        case .imposter: return LGColors.imposter
        }
    }

    private var roleBannerColor: Color {
        switch role {
        case .informed: return LGColors.success
        case .imposter: return LGColors.imposter
        }
    }

    private var borderColors: [Color] {
        // White/gray border for both roles
        return [.white, .gray, .white, .gray, .white]
    }

    private var shadowColor: Color {
        switch role {
        case .informed: return LGColors.accentPrimary
        case .imposter: return LGColors.imposter
        }
    }
}

// MARK: - Image Loading Placeholder

/// Animated skeleton placeholder shown while AI generates the image
struct ImageLoadingPlaceholder: View {
    @State private var isAnimating = false
    @State private var loadingPhase = 0
    
    private let loadingMessages = [
        "Creating image...",
        "AI is drawing...",
        "Almost there...",
        "Rendering details..."
    ]
    
    var body: some View {
        VStack(spacing: LGSpacing.medium) {
            // Skeleton image placeholder with shimmer
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay {
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: isAnimating ? 200 : -200)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    // Loading indicator in center
                    VStack(spacing: LGSpacing.small) {
                        // Animated sparkle icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [LGColors.accentPrimary, LGColors.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse.wholeSymbol, options: .repeating)
                        
                        // Rotating loading message
                        Text(loadingMessages[loadingPhase % loadingMessages.count])
                            .font(LGTypography.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                }
        }
        .onAppear {
            // Start shimmer animation
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
            // Cycle through loading messages
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(2.5))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        loadingPhase += 1
                    }
                }
            }
        }
        .accessibilityLabel("Generating AI image, please wait")
    }
}

// MARK: - Liquid Glass Highlight

/// Creates a premium holographic reflection effect that mimics real card reflections
struct LiquidGlassHighlight: View {
    let cornerRadius: CGFloat
    let tintColor: Color
    let pitch: Double
    let roll: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Normalize motion values for smoother movement
            let normalizedRoll = roll * 0.8
            let normalizedPitch = pitch * 0.8
            
            ZStack {
                // Main specular highlight - moves opposite to tilt like real reflections
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: width * 0.4
                        )
                    )
                    .frame(width: width * 0.5, height: height * 0.25)
                    .offset(
                        x: -normalizedRoll * width * 0.5,
                        y: -normalizedPitch * height * 0.4 - height * 0.15
                    )
                    .blur(radius: 20)
                
                // Rainbow iridescent streak - like a holographic card
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.pink.opacity(0.15),
                                Color.purple.opacity(0.2),
                                Color.blue.opacity(0.2),
                                Color.cyan.opacity(0.2),
                                Color.green.opacity(0.15),
                                Color.yellow.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: 0.3 + normalizedRoll * 0.3, y: 0),
                            endPoint: UnitPoint(x: 0.7 + normalizedRoll * 0.3, y: 1)
                        )
                    )
                    .frame(width: width * 0.6, height: height * 1.5)
                    .rotationEffect(.degrees(-15 + normalizedRoll * 20))
                    .offset(x: -normalizedRoll * width * 0.3, y: 0)
                    .blur(radius: 30)
                    .opacity(0.6)
                
                // Secondary smaller highlight for depth
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: width * 0.2
                        )
                    )
                    .frame(width: width * 0.25, height: height * 0.15)
                    .offset(
                        x: -normalizedRoll * width * 0.6 + width * 0.15,
                        y: -normalizedPitch * height * 0.5 - height * 0.25
                    )
                    .blur(radius: 10)
                
                // Edge highlight that follows the card edge
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.1),
                                Color.clear,
                                Color.clear,
                                Color.white.opacity(0.2)
                            ],
                            startPoint: UnitPoint(
                                x: 0.5 - normalizedRoll * 0.5,
                                y: 0.0 - normalizedPitch * 0.3
                            ),
                            endPoint: UnitPoint(
                                x: 0.5 + normalizedRoll * 0.5,
                                y: 1.0 + normalizedPitch * 0.3
                            )
                        ),
                        lineWidth: 1.5
                    )
                
                // Bottom edge glow - simulates light hitting bottom edge
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                tintColor.opacity(0.3),
                                tintColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: width * 0.4
                        )
                    )
                    .frame(width: width * 0.8, height: height * 0.2)
                    .offset(
                        x: normalizedRoll * width * 0.2,
                        y: height * 0.35 + normalizedPitch * height * 0.15
                    )
                    .blur(radius: 25)
                    .opacity(0.7)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Prismatic Border View

/// A premium holographic border that creates rainbow prismatic effects based on tilt
struct PrismaticBorderView: View {
    let cornerRadius: CGFloat
    let baseColor: Color
    let pitch: Double
    let roll: Double
    
    var body: some View {
        ZStack {
            // Base gradient border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            baseColor.opacity(0.4),
                            Color.white.opacity(0.3),
                            baseColor.opacity(0.2),
                            Color.white.opacity(0.5),
                            baseColor.opacity(0.3),
                            Color.white.opacity(0.6)
                        ],
                        center: .center,
                        angle: .degrees(roll * 40)
                    ),
                    lineWidth: 2
                )
            
            // Moving highlight line
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.8),
                            Color.clear
                        ],
                        startPoint: UnitPoint(
                            x: 0.3 + roll * 0.4,
                            y: 0 + pitch * 0.3
                        ),
                        endPoint: UnitPoint(
                            x: 0.7 + roll * 0.4,
                            y: 0.3 + pitch * 0.3
                        )
                    ),
                    lineWidth: 1.5
                )
            
            // Inner glow
            RoundedRectangle(cornerRadius: cornerRadius - 2, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            baseColor.opacity(0.1),
                            Color.clear,
                            baseColor.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .blur(radius: 2)
                .padding(2)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Legacy Gyro Border View (kept for compatibility)

/// A shiny border that reacts to device motion
struct GyroBorderView: View {
    let cornerRadius: CGFloat
    let baseColors: [Color]

    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    private let motionManager = CMMotionManager()

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    colors: baseColors,
                    center: .center,
                    angle: .degrees(rotationY * 30)
                ),
                lineWidth: 3
            )
            .blur(radius: 1)
            .overlay {
                // Highlight that moves with gyro
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.8), .clear, .clear, .white.opacity(0.3)],
                            startPoint: highlightStart,
                            endPoint: highlightEnd
                        ),
                        lineWidth: 2
                    )
            }
            .onAppear {
                startMotionUpdates()
            }
            .onDisappear {
                motionManager.stopDeviceMotionUpdates()
            }
    }

    private var highlightStart: UnitPoint {
        UnitPoint(
            x: 0.5 + rotationY * 0.3,
            y: 0.0 + rotationX * 0.2
        )
    }

    private var highlightEnd: UnitPoint {
        UnitPoint(
            x: 0.5 - rotationY * 0.3,
            y: 1.0 - rotationX * 0.2
        )
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion = motion else { return }

            withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                rotationX = motion.attitude.pitch
                rotationY = motion.attitude.roll
            }
        }
    }
}

// MARK: - Preview

#Preview("Informed Player") {
    ZStack {
        AnimatedBackground(style: .gameplay)

        RoleCardView(
            role: .informed(word: "Elephant"),
            playerName: "Alice",
            playerEmoji: "😎",
            playerColor: .crimson,
            generatedImage: nil
        )
    }
}

#Preview("Imposter") {
    ZStack {
        AnimatedBackground(style: .imposter)

        RoleCardView(
            role: .imposter(hint: "Living thing"),
            playerName: "Bob",
            playerEmoji: "🤠",
            playerColor: .azure,
            generatedImage: nil
        )
    }
}
