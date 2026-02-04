//
//  PlayerSelectionGrid.swift
//  Imposter
//
//  Grid of players for vote selection with gyro-reactive liquid glass effects.
//

import SwiftUI

// MARK: - PlayerSelectionGrid

/// Grid layout for selecting a player to vote for
struct PlayerSelectionGrid: View {
    let players: [Player]
    @Binding var selectedID: UUID?
    let onSelect: (UUID) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: LGSpacing.medium) {
            ForEach(players) { player in
                PlayerVoteCard(
                    player: player,
                    isSelected: selectedID == player.id,
                    action: {
                        selectedID = player.id
                        onSelect(player.id)
                    }
                )
            }
        }
    }
}

// MARK: - PlayerVoteCard

/// A premium gyro-reactive card representing a player that can be voted for
struct PlayerVoteCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    @State private var motionManager = MotionManager.shared
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: LGSpacing.medium) {
                // Player avatar with gyro-reactive highlight
                playerAvatar
                
                // Player emoji
                Text(player.emoji)
                    .font(.system(size: 28))

                // Player name
                Text(player.name)
                    .font(LGTypography.labelLarge)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(LGSpacing.medium)
            .background {
                // Glass background
                RoundedRectangle(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        isSelected
                            ? .regular.tint(LGColors.playerColor(player.color))
                            : .regular,
                        in: .rect(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
                    )
            }
            .overlay {
                // Gyro-reactive liquid highlight
                if isSelected {
                    GyroCardHighlight(
                        cornerRadius: LGSpacing.cornerRadiusMedium,
                        color: LGColors.playerColor(player.color),
                        pitch: motionManager.pitch,
                        roll: motionManager.roll
                    )
                }
            }
            .overlay {
                // Border with gyro-reactive gradient
                RoundedRectangle(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(
                        isSelected ? selectedBorderGradient : unselectedBorderGradient,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        // Subtle 3D tilt effect
        .rotation3DEffect(
            .degrees(isSelected ? motionManager.pitch * 4 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(isSelected ? -motionManager.roll * 4 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.03 : 1.0))
        // Dynamic shadow
        .shadow(
            color: isSelected ? LGColors.playerColor(player.color).opacity(0.4) : .clear,
            radius: 15,
            x: CGFloat(motionManager.roll * 5),
            y: CGFloat(motionManager.pitch * 5) + 5
        )
        .animation(LGMaterials.springAnimation, value: isSelected)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityLabel("Vote for \(player.name)")
        .accessibilityHint("Double tap to cast your vote")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var playerAvatar: some View {
        ZStack {
            // Glow behind when selected
            if isSelected {
                Circle()
                    .fill(LGColors.playerColor(player.color).opacity(0.4))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
            }
            
            // Main circle with glass effect
            Circle()
                .fill(.clear)
                .glassEffect(
                    .regular.tint(LGColors.playerColor(player.color).opacity(0.5)),
                    in: .circle
                )
                .frame(width: 50, height: 50)
            
            // Checkmark when selected
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay {
            // Gyro-reactive border highlight
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6 + motionManager.pitch * 0.2),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.4 + motionManager.roll * 0.2)
                        ],
                        startPoint: UnitPoint(x: 0.5 - motionManager.roll * 0.3, y: 0),
                        endPoint: UnitPoint(x: 0.5 + motionManager.roll * 0.3, y: 1)
                    ),
                    lineWidth: isSelected ? 2.5 : 1.5
                )
        }
    }
    
    private var selectedBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.6),
                LGColors.playerColor(player.color).opacity(0.4),
                Color.white.opacity(0.3)
            ],
            startPoint: UnitPoint(x: 0.5 - motionManager.roll * 0.3, y: 0),
            endPoint: UnitPoint(x: 0.5 + motionManager.roll * 0.3, y: 1)
        )
    }
    
    private var unselectedBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.3),
                Color.white.opacity(0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Gyro Card Highlight

/// A subtle highlight effect that moves based on device tilt
struct GyroCardHighlight: View {
    let cornerRadius: CGFloat
    let color: Color
    let pitch: Double
    let roll: Double
    
    var body: some View {
        GeometryReader { geometry in
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geometry.size.width * 0.6
                    )
                )
                .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.5)
                .offset(
                    x: roll * geometry.size.width * 0.3,
                    y: pitch * geometry.size.height * 0.3 - geometry.size.height * 0.15
                )
                .blur(radius: 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()

        PlayerSelectionGrid(
            players: [
                Player(name: "Alice", color: .crimson),
                Player(name: "Bob", color: .azure),
                Player(name: "Charlie", color: .emerald),
                Player(name: "Diana", color: .amber)
            ],
            selectedID: .constant(nil),
            onSelect: { _ in }
        )
        .padding()
    }
}
