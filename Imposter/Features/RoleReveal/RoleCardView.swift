//
//  RoleCardView.swift
//  Imposter
//
//  Premium card showing a player's role with gyro-reactive shiny border.
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

/// Displays a player's role during the reveal phase with premium card design
struct RoleCardView: View {
    let role: Role
    let playerName: String
    let playerEmoji: String
    let playerColor: PlayerColor
    let generatedImage: UIImage?
    var isGeneratingImage: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: LGSpacing.medium) {
                // Player info ABOVE the card
                playerHeader

                // The actual card - 4:3 aspect ratio
                cardContent
                    .frame(width: cardWidth(for: geometry.size))
                    .frame(height: cardHeight(for: geometry.size))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        // Gyro-reactive shiny border
                        GyroBorderView(
                            cornerRadius: 24,
                            baseColors: borderColors
                        )
                    }
                    .shadow(color: shadowColor.opacity(0.4), radius: 25, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cardWidth(for size: CGSize) -> CGFloat {
        min(size.width - 32, 360)
    }

    private func cardHeight(for size: CGSize) -> CGFloat {
        // 3:4 aspect ratio (width:height = 3:4, so height = width * 4/3)
        let width = cardWidth(for: size)
        return min(width * 1.333, size.height * 0.65)
    }

    // MARK: - Player Header (Above Card)

    private var playerHeader: some View {
        VStack(spacing: LGSpacing.small) {
            // Large emoji avatar
            ZStack {
                Circle()
                    .fill(LGColors.playerColor(playerColor))
                    .frame(width: 90, height: 90)

                Text(playerEmoji)
                    .font(.system(size: 50))
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 3)
            }
            .shadow(color: LGColors.playerColor(playerColor).opacity(0.5), radius: 12)

            // Player name
            Text(playerName)
                .font(LGTypography.displaySmall)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Card top banner with matching corner radius
            cardTopBanner

            // Main content area
            VStack(spacing: LGSpacing.medium) {
                switch role {
                case .informed(let word):
                    informedContent(word: word)
                case .imposter(let hint):
                    imposterContent(hint: hint)
                }
            }
            .padding(LGSpacing.large)
            .frame(maxHeight: .infinity)
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
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
        VStack(spacing: LGSpacing.small) {
            Spacer()

            // Secret word label
            Text("THE SECRET WORD")
                .font(LGTypography.caption)
                .foregroundStyle(.secondary)
                .tracking(2)

            // The word itself - scales down if needed
            Text(word)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [LGColors.accentPrimary, LGColors.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .shadow(color: LGColors.accentPrimary.opacity(0.3), radius: 8)

            // AI-generated image - BIGGER
            imageSection

            Spacer()

            // Status badge
            HStack(spacing: LGSpacing.small) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(LGColors.success)
                Text("You know the word")
                    .font(LGTypography.labelMedium)
            }
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The secret word is \(word). You are not the Imposter.")
    }

    @ViewBuilder
    private var imageSection: some View {
        if let image = generatedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                }
        } else if isGeneratingImage {
            VStack(spacing: LGSpacing.small) {
                ProgressView()
                    .scaleEffect(1.3)
                Text("Creating image...")
                    .font(LGTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 120)
        }
    }

    // MARK: - Imposter Content

    private func imposterContent(hint: String) -> some View {
        VStack(spacing: LGSpacing.medium) {
            Spacer()

            // Imposter icon
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [LGColors.imposter, LGColors.imposter.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: LGColors.imposter.opacity(0.5), radius: 12)

            // Title
            Text("IMPOSTER")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LGColors.imposter)
                .shadow(color: LGColors.imposter.opacity(0.3), radius: 6)

            Divider()
                .background(LGColors.imposter.opacity(0.3))

            // Vague hint
            VStack(spacing: LGSpacing.extraSmall) {
                Text("HINT")
                    .font(LGTypography.caption)
                    .foregroundStyle(.secondary)
                    .tracking(2)

                Text(hint)
                    .font(LGTypography.headlineLarge)
                    .foregroundStyle(LGColors.warning)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
            }
            .padding(LGSpacing.medium)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            }

            Spacer()

            // Simple instruction
            Text("Blend in. Don't get caught.")
                .font(LGTypography.labelMedium)
                .foregroundStyle(.secondary)
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
        case .informed: return .cyan
        case .imposter: return .red
        }
    }
}

// MARK: - Gyro Border View

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
