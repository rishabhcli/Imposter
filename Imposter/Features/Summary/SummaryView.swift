//
//  SummaryView.swift
//  Imposter
//
//  Game summary with scoreboard and options to play again.
//

import SwiftUI

// MARK: - SummaryView

/// Displays the game summary with scoreboard and navigation options
struct SummaryView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: LGSpacing.large) {
                // Header
                headerSection

                // Scoreboard
                scoreboardSection

                Spacer()

                // Action buttons
                actionButtons
            }
            .padding(LGSpacing.large)
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        ZStack {
            LGColors.darkBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    LGColors.darkBackgroundSecondary,
                    LGColors.darkBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var headerSection: some View {
        VStack(spacing: LGSpacing.medium) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 50))
                .foregroundStyle(LGColors.warning)

            Text("Game Summary")
                .font(LGTypography.displaySmall)
                .foregroundStyle(.white)

            Text("Round \(store.roundNumber)")
                .font(LGTypography.bodyMedium)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var scoreboardSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(spacing: LGSpacing.medium) {
                Text("Scoreboard")
                    .font(LGTypography.headlineSmall)

                ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    ScoreboardRow(
                        rank: index + 1,
                        player: player,
                        isWinner: index == 0 && player.score > 0,
                        isImposter: store.state.roundState?.imposterID == player.id
                    )

                    if index < sortedPlayers.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        LGLargeButton("New Game", icon: "arrow.counterclockwise") {
            store.dispatch(.returnToHome)
        }
    }

    // MARK: - Helpers

    private var sortedPlayers: [Player] {
        store.leaderboard
    }
}

// MARK: - Scoreboard Row

struct ScoreboardRow: View {
    let rank: Int
    let player: Player
    let isWinner: Bool
    let isImposter: Bool

    var body: some View {
        HStack(spacing: LGSpacing.medium) {
            // Rank badge
            LGRankBadge(rank: rank, isWinner: isWinner)

            // Player color
            LGPlayerColorBadge(player.color, size: 32)

            // Player name
            VStack(alignment: .leading, spacing: LGSpacing.extraSmall) {
                HStack(spacing: LGSpacing.small) {
                    Text(player.name)
                        .font(LGTypography.labelLarge)

                    if isImposter {
                        LGBadge("Imposter", color: LGColors.imposter, size: .small)
                    }
                }

                if isWinner {
                    Text("Winner!")
                        .font(LGTypography.labelSmall)
                        .foregroundStyle(LGColors.warning)
                }
            }

            Spacer()

            // Score
            Text("\(player.score)")
                .font(LGTypography.score)
                .foregroundStyle(isWinner ? LGColors.warning : .primary)
        }
        .padding(.vertical, LGSpacing.small)
        .if(isWinner) { view in
            view.background {
                RoundedRectangle(cornerRadius: LGSpacing.cornerRadiusSmall)
                    .fill(LGColors.warning.opacity(0.1))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
        .environment(GameStore.previewInGame)
}
