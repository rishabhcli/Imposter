//
//  ClueRoundView.swift
//  Imposter
//
//  Shows who goes first and provides End Game button.
//

import SwiftUI

// MARK: - ClueRoundView

/// Simple view showing who starts and an End Game button
struct ClueRoundView: View {
    @Environment(GameStore.self) private var store
    @State private var showEndGameConfirm = false

    var body: some View {
        ZStack {
            // Background
            AnimatedBackground(style: .gameplay)

            VStack(spacing: LGSpacing.extraLarge) {
                Spacer()

                // First player display
                if let firstPlayer = store.firstClueGiver {
                    VStack(spacing: LGSpacing.large) {
                        // Player avatar
                        ZStack {
                            Circle()
                                .fill(LGColors.playerColor(firstPlayer.color))
                                .frame(width: 120, height: 120)

                            Text(firstPlayer.emoji)
                                .font(.system(size: 70))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 3)
                        }
                        .shadow(color: LGColors.playerColor(firstPlayer.color).opacity(0.5), radius: 20)

                        // Player name
                        VStack(spacing: LGSpacing.small) {
                            Text(firstPlayer.name)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text("goes first!")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundStyle(LGColors.accentPrimary)
                        }

                        // Category display
                        HStack(spacing: LGSpacing.small) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 14))
                            Text(displayCategory)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, LGSpacing.medium)
                        .padding(.vertical, LGSpacing.small)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.top, LGSpacing.medium)
                    }
                }

                Spacer()

                // End Game button
                Button {
                    showEndGameConfirm = true
                } label: {
                    HStack(spacing: LGSpacing.medium) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 24))
                        Text("End Game")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LGSpacing.large)
                }
                .buttonStyle(.glass)
                .padding(.horizontal, LGSpacing.extraLarge)

                Spacer()
            }
            .padding(LGSpacing.large)
        }
        .confirmationDialog("End Game?", isPresented: $showEndGameConfirm, titleVisibility: .visible) {
            Button("Reveal Imposter", role: .destructive) {
                store.dispatch(.completeVoting)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Ready to reveal the imposter?")
        }
    }

    // MARK: - Computed Properties

    /// Returns the category to display - uses imposter hint for AI words, category for word bank
    private var displayCategory: String {
        if store.settings.wordSource == .customPrompt {
            // For AI-generated words, use the imposter hint as category
            return store.state.roundState?.imposterHint ?? store.state.roundState?.categoryHint ?? "Custom"
        } else {
            // For word bank, use the actual category
            return store.state.roundState?.categoryHint ?? "Mixed"
        }
    }
}

// MARK: - Preview

#Preview {
    ClueRoundView()
        .environment(GameStore.previewInGame)
}
