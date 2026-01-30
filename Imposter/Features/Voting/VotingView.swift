//
//  VotingView.swift
//  Imposter
//
//  Pass-and-play voting for the suspected Imposter.
//

import SwiftUI

// MARK: - VotingView

/// Handles the pass-and-play voting sequence for all players
struct VotingView: View {
    @Environment(GameStore.self) private var store

    @State private var currentVoterIndex = 0
    @State private var hasVoted = false
    @State private var selectedPlayerID: UUID?

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: LGSpacing.large) {
                // Header
                headerSection

                if !hasVoted {
                    // Vote prompt
                    votePrompt

                    // Player selection grid
                    PlayerSelectionGrid(
                        players: selectablePlayers,
                        selectedID: $selectedPlayerID,
                        onSelect: { playerID in
                            castVote(for: playerID)
                        }
                    )
                } else {
                    // Vote confirmation
                    voteConfirmation
                }
            }
            .padding(LGSpacing.large)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if hasVoted {
                advanceToNextVoter()
            }
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
        VStack(spacing: LGSpacing.small) {
            Text("Voting")
                .font(LGTypography.headlineMedium)
                .foregroundStyle(.white)

            // Progress
            HStack(spacing: LGSpacing.small) {
                ForEach(0..<store.players.count, id: \.self) { index in
                    Circle()
                        .fill(index < currentVoterIndex ? LGColors.accentPrimary : (index == currentVoterIndex ? LGColors.accentPrimary.opacity(0.5) : .white.opacity(0.3)))
                        .frame(width: 10, height: 10)
                }
            }

            Text("\(currentVoterIndex + 1) of \(store.players.count)")
                .font(LGTypography.labelSmall)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var votePrompt: some View {
        LGCard {
            VStack(spacing: LGSpacing.medium) {
                HStack(spacing: LGSpacing.medium) {
                    LGPlayerColorBadge(currentVoter.color, size: 40)

                    VStack(alignment: .leading, spacing: LGSpacing.extraSmall) {
                        Text("It's your turn to vote")
                            .font(LGTypography.bodySmall)
                            .foregroundStyle(.secondary)

                        Text(currentVoter.name)
                            .font(LGTypography.headlineMedium)
                    }

                    Spacer()
                }

                Text("Who do you think is the Imposter?")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var voteConfirmation: some View {
        VStack(spacing: LGSpacing.extraLarge) {
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(LGColors.success)

            VStack(spacing: LGSpacing.medium) {
                Text("Vote Recorded!")
                    .font(LGTypography.headlineMedium)
                    .foregroundStyle(.white)

                Text("Pass the device to the next player")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text("Tap anywhere to continue")
                .font(LGTypography.bodySmall)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, LGSpacing.large)
        }
    }

    // MARK: - Helpers

    private var currentVoter: Player {
        guard currentVoterIndex < store.players.count else {
            return store.players.first ?? Player(name: "Unknown", color: .azure)
        }
        return store.players[currentVoterIndex]
    }

    private var selectablePlayers: [Player] {
        // Can't vote for yourself
        store.players.filter { $0.id != currentVoter.id }
    }

    // MARK: - Actions

    private func castVote(for playerID: UUID) {
        store.dispatch(.castVote(voterID: currentVoter.id, suspectID: playerID))

        // Haptic feedback
        HapticManager.voteSelected()

        withAnimation(LGMaterials.springAnimation) {
            hasVoted = true
        }
    }

    private func advanceToNextVoter() {
        withAnimation(LGMaterials.springAnimation) {
            hasVoted = false
            selectedPlayerID = nil
            currentVoterIndex += 1
        }

        // Check if all players have voted
        if currentVoterIndex >= store.players.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                store.dispatch(.completeVoting)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VotingView()
        .environment(GameStore.previewInGame)
}
