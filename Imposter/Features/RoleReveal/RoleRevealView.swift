//
//  RoleRevealView.swift
//  Imposter
//
//  Pass-and-play role reveal for each player.
//

import SwiftUI

// MARK: - RoleRevealView

/// Handles the pass-and-play role reveal sequence for all players
struct RoleRevealView: View {
    @Environment(GameStore.self) private var store

    @State private var currentRevealIndex = 0
    @State private var roleRevealed = false
    @State private var showContinueHint = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            VStack(spacing: LGSpacing.extraLarge) {
                // Progress indicator
                progressIndicator

                Spacer()

                if !roleRevealed {
                    // Pass device prompt
                    passDevicePrompt
                } else {
                    // Role card
                    roleCardSection
                }

                Spacer()
            }
            .padding(LGSpacing.large)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        .onAppear {
            // Reset state when view appears
            currentRevealIndex = 0
            roleRevealed = false
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        AnimatedBackground(style: .gameplay)
    }

    private var progressIndicator: some View {
        VStack(spacing: LGSpacing.small) {
            Text("Role Reveal")
                .font(LGTypography.headlineSmall)
                .foregroundStyle(.white.opacity(0.7))

            // Progress dots
            HStack(spacing: LGSpacing.small) {
                ForEach(0..<store.players.count, id: \.self) { index in
                    Circle()
                        .fill(index < currentRevealIndex ? LGColors.accentPrimary : (index == currentRevealIndex ? LGColors.accentPrimary.opacity(0.5) : .white.opacity(0.3)))
                        .frame(width: 10, height: 10)
                }
            }

            Text("\(currentRevealIndex + 1) of \(store.players.count)")
                .font(LGTypography.labelSmall)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var passDevicePrompt: some View {
        VStack(spacing: LGSpacing.extraLarge) {
            // Player emoji avatar - large display
            ZStack {
                Circle()
                    .fill(playerColor)
                    .frame(width: 120, height: 120)

                Text(currentPlayer.emoji)
                    .font(.system(size: 70))
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 3)
            }
            .lgShadow(LGMaterials.elevation2)

            // Instruction
            VStack(spacing: LGSpacing.medium) {
                Text("Pass the device to")
                    .font(LGTypography.bodyLarge)
                    .foregroundStyle(.white.opacity(0.7))

                Text(currentPlayer.name)
                    .font(LGTypography.displayMedium)
                    .foregroundStyle(playerColor)
            }

            // Reveal button - white gradient
            Button {
                withAnimation(LGMaterials.springAnimation) {
                    roleRevealed = true
                }
                // Show continue hint after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showContinueHint = true
                    }
                }
            } label: {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Reveal My Role")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: LGSpacing.buttonHeightLarge)
                .background {
                    RoundedRectangle(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
                        .fill(.white)
                }
                .shadow(color: .white.opacity(0.3), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.top, LGSpacing.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pass the device to \(currentPlayer.name), then tap Reveal My Role")
    }

    private var roleCardSection: some View {
        VStack(spacing: LGSpacing.large) {
            // Role card
            RoleCardView(
                role: isCurrentPlayerImposter ? .imposter(hint: imposterHint) : .informed(word: secretWord),
                playerName: currentPlayer.name,
                playerEmoji: currentPlayer.emoji,
                playerColor: currentPlayer.color,
                generatedImage: store.state.roundState?.generatedImage,
                isGeneratingImage: store.isGeneratingImage
            )
            .transition(.scale.combined(with: .opacity))

            // Continue hint
            if showContinueHint {
                Text("Tap anywhere to continue")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.5))
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Helpers

    private var currentPlayer: Player {
        guard currentRevealIndex < store.players.count else {
            return store.players.first ?? Player(name: "Unknown", color: .azure)
        }
        return store.players[currentRevealIndex]
    }

    private var playerColor: Color {
        LGColors.playerColor(currentPlayer.color)
    }

    private var isCurrentPlayerImposter: Bool {
        store.isImposter(currentPlayer.id)
    }

    private var secretWord: String {
        store.secretWord ?? "UNKNOWN"
    }

    private var categoryHint: String {
        store.state.roundState?.categoryHint ?? "Unknown"
    }

    private var imposterHint: String {
        // Use AI-generated hint if available, otherwise fallback to category
        store.state.roundState?.imposterHint ?? categoryHint
    }

    // MARK: - Actions

    private func handleTap() {
        guard roleRevealed else { return }

        withAnimation(LGMaterials.springAnimation) {
            roleRevealed = false
            showContinueHint = false
            currentRevealIndex += 1
        }

        // Check if all players have seen their role
        if currentRevealIndex >= store.players.count {
            // Small delay before transitioning
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                store.dispatch(.completeRoleReveal)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RoleRevealView()
        .environment(GameStore.previewInGame)
}
