//
//  PlayerSelectionGrid.swift
//  Imposter
//
//  Grid of players for vote selection.
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

/// A card representing a player that can be voted for
struct PlayerVoteCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: LGSpacing.medium) {
                // Player color circle
                Circle()
                    .fill(LGColors.playerColor(player.color))
                    .frame(width: 50, height: 50)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSelected ? Color.white : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 3 : 2
                            )
                    }

                // Player name
                Text(player.name)
                    .font(LGTypography.labelLarge)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(LGSpacing.medium)
            .glassEffect(
                isSelected
                    ? .regular.tint(LGColors.playerColor(player.color)).interactive()
                    : .regular.interactive(),
                in: .rect(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(LGMaterials.springAnimation, value: isSelected)
        .accessibilityLabel("Vote for \(player.name)")
        .accessibilityHint("Double tap to cast your vote")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
