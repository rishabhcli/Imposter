//
//  LGBadge.swift
//  Imposter
//
//  Badge component for winner indicator and status labels.
//

import SwiftUI

// MARK: - LGBadge

/// A small badge for status indicators, ranks, and labels.
struct LGBadge: View {
    let text: String
    let color: Color
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium
        case large
    }

    init(_ text: String, color: Color = LGColors.accentPrimary, size: BadgeSize = .medium) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(color), in: .capsule)
            }
            .clipShape(Capsule())
    }

    private var font: Font {
        switch size {
        case .small: return LGTypography.labelSmall
        case .medium: return LGTypography.labelMedium
        case .large: return LGTypography.labelLarge
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return LGSpacing.small
        case .medium: return LGSpacing.medium
        case .large: return LGSpacing.large
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return LGSpacing.extraSmall
        case .medium: return LGSpacing.small
        case .large: return LGSpacing.medium
        }
    }
}

// MARK: - Icon Badge

/// A badge with an icon and optional text
struct LGIconBadge: View {
    let icon: String
    let text: String?
    let color: Color

    init(icon: String, text: String? = nil, color: Color = LGColors.accentPrimary) {
        self.icon = icon
        self.text = text
        self.color = color
    }

    var body: some View {
        HStack(spacing: LGSpacing.extraSmall) {
            Image(systemName: icon)

            if let text = text {
                Text(text)
            }
        }
        .font(LGTypography.labelMedium)
        .foregroundStyle(.white)
        .padding(.horizontal, LGSpacing.medium)
        .padding(.vertical, LGSpacing.small)
        .background {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.tint(color), in: .capsule)
        }
        .clipShape(Capsule())
    }
}

// MARK: - Rank Badge

/// A circular badge showing rank number
struct LGRankBadge: View {
    let rank: Int
    let isWinner: Bool

    init(rank: Int, isWinner: Bool = false) {
        self.rank = rank
        self.isWinner = isWinner
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(.clear)
                .glassEffect(
                    isWinner ? .regular.tint(LGColors.warning) : .regular,
                    in: .circle
                )

            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(rank)")
                    .font(LGTypography.labelLarge)
                    .foregroundStyle(LGColors.textPrimary)
            }
        }
        .frame(width: 36, height: 36)
    }
}

// MARK: - Player Color Badge

/// A small colored circle representing a player's color with optional emoji
struct LGPlayerColorBadge: View {
    let playerColor: PlayerColor
    let emoji: String?
    let size: CGFloat

    init(_ playerColor: PlayerColor, emoji: String? = nil, size: CGFloat = 24) {
        self.playerColor = playerColor
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(LGColors.playerColor(playerColor))
                .frame(width: size, height: size)

            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: size * 0.6))
            }
        }
        .overlay {
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
        }
        .lgShadow(LGMaterials.elevation1)
    }
}

// MARK: - Preview

#Preview("LGBadge Variants") {
    ZStack {
        LinearGradient(
            colors: [.purple, .blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: LGSpacing.large) {
            HStack(spacing: LGSpacing.medium) {
                LGBadge("Small", size: .small)
                LGBadge("Medium", size: .medium)
                LGBadge("Large", size: .large)
            }

            HStack(spacing: LGSpacing.medium) {
                LGBadge("Success", color: LGColors.success)
                LGBadge("Warning", color: LGColors.warning)
                LGBadge("Error", color: LGColors.error)
            }

            HStack(spacing: LGSpacing.medium) {
                LGIconBadge(icon: "star.fill", text: "Winner", color: LGColors.warning)
                LGIconBadge(icon: "checkmark", color: LGColors.success)
            }

            HStack(spacing: LGSpacing.medium) {
                LGRankBadge(rank: 1, isWinner: true)
                LGRankBadge(rank: 2)
                LGRankBadge(rank: 3)
            }

            HStack(spacing: LGSpacing.small) {
                ForEach(PlayerColor.allCases, id: \.self) { color in
                    LGPlayerColorBadge(color)
                }
            }
        }
        .padding()
    }
}
