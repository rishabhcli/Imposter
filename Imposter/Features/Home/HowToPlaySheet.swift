//
//  HowToPlaySheet.swift
//  Imposter
//
//  Game rules and instructions sheet.
//

import SwiftUI

// MARK: - HowToPlaySheet

/// Sheet presenting game rules and how to play instructions
struct HowToPlaySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LGSpacing.large) {
                    // Overview
                    ruleSection(
                        title: "Overview",
                        icon: "info.circle",
                        content: "Imposter is a social deduction game for 3-10 players. One player is secretly the Imposter who doesn't know the secret word. Everyone else knows the word and must identify the Imposter through clever questioning."
                    )

                    // Setup
                    ruleSection(
                        title: "Setup",
                        icon: "person.3",
                        content: "Add 3-10 players, choose a word category, and start the game. Each player will privately view their role by passing the device around."
                    )

                    // Roles
                    ruleSection(
                        title: "Roles",
                        icon: "theatermasks",
                        content: """
                        • Informed Players: Know the secret word
                        • The Imposter: Does NOT know the word and must fake it
                        """
                    )

                    // Gameplay
                    ruleSection(
                        title: "Gameplay",
                        icon: "bubble.left.and.bubble.right",
                        content: """
                        1. Each player gives a clue related to the secret word
                        2. Clues should hint at the word without being too obvious
                        3. The Imposter must give clues without knowing the word
                        4. After clue rounds, players discuss who they think is the Imposter
                        """
                    )

                    // Voting
                    ruleSection(
                        title: "Voting",
                        icon: "hand.raised",
                        content: "Each player secretly votes for who they think is the Imposter. The player with the most votes is revealed. If it's the Imposter, the informed players win! If not, the Imposter wins."
                    )

                    // Imposter Guess
                    ruleSection(
                        title: "Imposter's Last Chance",
                        icon: "lightbulb",
                        content: "If caught, the Imposter can try to guess the secret word. A correct guess earns bonus points and partial victory!"
                    )

                    // Scoring
                    ruleSection(
                        title: "Scoring",
                        icon: "star",
                        content: """
                        • Correct vote: +1 point per informed player
                        • Imposter survives: +2 points
                        • Imposter guesses word: +3 points

                        Play multiple rounds to determine the ultimate winner!
                        """
                    )

                    // Tips
                    ruleSection(
                        title: "Tips",
                        icon: "lightbulb.max",
                        content: """
                        • Give clues that are specific enough to prove you know the word, but vague enough not to help the Imposter
                        • Pay attention to who gives vague or confused clues
                        • As Imposter, listen carefully to others' clues for hints
                        • Don't be too quick to accuse - wrong votes help the Imposter!
                        """
                    )
                }
                .padding(LGSpacing.large)
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helper

    private func ruleSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: LGSpacing.small) {
            HStack(spacing: LGSpacing.small) {
                Image(systemName: icon)
                    .foregroundStyle(LGColors.accentPrimary)
                Text(title)
                    .font(LGTypography.headlineSmall)
            }

            Text(content)
                .font(LGTypography.bodyMedium)
                .foregroundStyle(LGColors.textSecondary)
        }
        .padding(LGSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassBackground(cornerRadius: LGSpacing.cornerRadiusMedium)
    }
}

// MARK: - Preview

#Preview {
    HowToPlaySheet()
}
