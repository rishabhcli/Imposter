//
//  SummaryView.swift
//  Imposter
//
//  Round summary with leaderboard and scoring breakdown.
//

import SwiftUI

// MARK: - SummaryView

/// Shows round results, leaderboard, and navigation to next round or home
struct SummaryView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            // Background
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

            ScrollView {
                VStack(spacing: LGSpacing.extraLarge) {
                    // Round result header
                    roundResultHeader

                    // Leaderboard
                    leaderboardSection

                    // Last round details
                    if let lastRound = store.gameHistory.last {
                        lastRoundDetails(lastRound)
                    }

                    // Action buttons
                    actionButtons
                }
                .padding(LGSpacing.large)
            }
        }
    }

    // MARK: - Round Result Header

    private var roundResultHeader: some View {
        VStack(spacing: LGSpacing.medium) {
            // Round counter
            Text(roundCounterText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)

            if isGameOver {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LGColors.warning)

                Text("Game Over!")
                    .font(LGTypography.displaySmall)
                    .foregroundStyle(.white)
            } else if let lastRound = store.gameHistory.last {
                Image(systemName: lastRound.wasImposterCaught ? "checkmark.shield.fill" : "eye.slash.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(lastRound.wasImposterCaught ? LGColors.success : LGColors.imposter)

                Text(lastRound.wasImposterCaught ? "Imposter Caught!" : "Imposter Escaped!")
                    .font(LGTypography.displaySmall)
                    .foregroundStyle(.white)

                Text("The word was \"\(lastRound.secretWord)\"")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.top, LGSpacing.large)
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(spacing: LGSpacing.medium) {
            Text("LEADERBOARD")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: LGSpacing.small) {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                    LeaderboardRow(player: player, rank: index + 1)
                }
            }
            .padding(LGSpacing.medium)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }

    private var rankedPlayers: [Player] {
        store.players.sorted { $0.score > $1.score }
    }

    // MARK: - Last Round Details

    private func lastRoundDetails(_ round: CompletedRound) -> some View {
        VStack(spacing: LGSpacing.medium) {
            Text("ROUND DETAILS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: LGSpacing.small) {
                detailRow(icon: "person.fill.questionmark", label: "Imposter", value: round.imposterName)
                detailRow(icon: "textformat.abc", label: "Secret Word", value: round.secretWord)
                detailRow(
                    icon: round.wasImposterCaught ? "checkmark.circle.fill" : "xmark.circle.fill",
                    label: "Result",
                    value: round.wasImposterCaught ? "Caught" : "Escaped"
                )
                if round.imposterGuessedWord {
                    detailRow(icon: "lightbulb.fill", label: "Word Guess", value: "Correct!")
                }
            }
            .padding(LGSpacing.medium)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(LGColors.accentPrimary)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.vertical, LGSpacing.extraSmall)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LGSpacing.medium) {
            if !isGameOver {
                Button {
                    store.dispatch(.startNewRound)
                    HapticManager.buttonTap()
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Next Round")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.glassProminent)
                .tint(LGColors.accentPrimary)
            }

            Button {
                store.dispatch(.returnToHome)
                HapticManager.buttonTap()
            } label: {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16))
                    Text("New Game")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.glass)
        }
        .padding(.bottom, LGSpacing.extraLarge)
    }

    // MARK: - Helpers

    private var isGameOver: Bool {
        guard store.settings.numberOfRounds > 0 else { return false }
        return store.roundNumber >= store.settings.numberOfRounds
    }

    private var roundCounterText: String {
        if store.settings.numberOfRounds > 0 {
            return "Round \(store.roundNumber) of \(store.settings.numberOfRounds)"
        }
        return "Round \(store.roundNumber)"
    }
}

// MARK: - LeaderboardRow

struct LeaderboardRow: View {
    let player: Player
    let rank: Int

    var body: some View {
        HStack(spacing: LGSpacing.medium) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(rankColor)
                .frame(width: 28)

            // Player avatar
            ZStack {
                Circle()
                    .fill(LGColors.playerColor(player.color))
                    .frame(width: 36, height: 36)

                Text(player.emoji)
                    .font(.system(size: 20))
            }

            // Name
            Text(player.name)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            // Score
            Text("\(player.score) pts")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(LGColors.accentPrimary)
        }
        .padding(.vertical, LGSpacing.small)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return LGColors.warning  // Gold
        case 2: return .gray             // Silver
        case 3: return .orange           // Bronze
        default: return .white.opacity(0.5)
        }
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
        .environment(GameStore.previewInGame)
}
