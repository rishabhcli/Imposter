//
//  RoleRevealView.swift
//  Imposter
//
//  Pass-and-play role reveal for each player with VoiceOver privacy.
//

import SwiftUI

// MARK: - RoleRevealView

/// Handles the pass-and-play role reveal sequence for all players
struct RoleRevealView: View {
    @Environment(GameStore.self) private var store

    @State private var currentRevealIndex = 0
    @State private var voiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var roleRevealed = false
    @State private var showContinueHint = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            // Content
            VStack(spacing: LGSpacing.extraLarge) {
                // Progress indicator
                progressIndicator

                Spacer()

                if isTransitioning {
                    // Empty state during player transition to prevent spoiling
                    Color.clear
                } else if !roleRevealed {
                    // Pass device prompt
                    passDevicePrompt
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
            voiceOverRunning = UIAccessibility.isVoiceOverRunning
            HapticManager.prepare()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            voiceOverRunning = UIAccessibility.isVoiceOverRunning
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

            // Progress bar instead of dots for better accessibility
            RoleRevealProgressBar(
                current: currentRevealIndex,
                total: store.players.count
            )
            .padding(.horizontal, LGSpacing.extraLarge)

            Text("Player \(currentRevealIndex + 1) of \(store.players.count)")
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
            // Hide emoji from VoiceOver (decorative)
            .accessibilityHidden(true)

            // Instruction - privacy-aware for VoiceOver
            VStack(spacing: LGSpacing.medium) {
                Text("Pass the device to")
                    .font(LGTypography.bodyLarge)
                    .foregroundStyle(.white.opacity(0.7))

                // Player name - hidden from VoiceOver for privacy
                Text(currentPlayer.name)
                    .font(LGTypography.displayMedium)
                    .foregroundStyle(playerColor)
                    .accessibilityHidden(voiceOverRunning)
            }
            
            // Privacy indicator for VoiceOver users
            if voiceOverRunning {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text("Private - Hand device to next player")
                        .font(LGTypography.labelSmall)
                }
                .foregroundStyle(.white.opacity(0.6))
                .accessibilityLabel("This is a private screen. Please hand the device to the next player before revealing.")
            }

            // Reveal button - white gradient with animation
            Button {
                HapticManager.roleRevealed()
                withAnimation(LGMaterials.springAnimation) {
                    roleRevealed = true
                }
                // Show continue hint after delay
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1500))
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
                .scaleEffect(buttonScale)
            }
            .buttonStyle(.plain)
            .padding(.top, LGSpacing.large)
            .accessibilityLabel("Reveal My Role")
            .accessibilityHint("Double tap to see your secret role")
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                withAnimation(.spring(response: 0.2)) {
                    buttonScale = pressing ? 0.95 : 1.0
                }
            }, perform: {})
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(voiceOverRunning ? "Player's turn to reveal their role" : "Pass the device to \(currentPlayer.name), then tap Reveal My Role")
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

            // Continue hint with pulsing animation
            if showContinueHint {
                Text("Tap anywhere to continue")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.5))
                    .transition(.opacity)
                    .modifier(PulsingOpacityModifier())
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
        guard !isTransitioning else { return }
        
        HapticManager.buttonTap()

        // Phase 1: Hide the current role card
        withAnimation(.easeOut(duration: 0.2)) {
            isTransitioning = true
            roleRevealed = false
            showContinueHint = false
        }

        // Phase 2: After card is hidden, update player index and show next prompt
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            currentRevealIndex += 1
            
            // Check if all players have seen their role
            if currentRevealIndex >= store.players.count {
                try? await Task.sleep(for: .milliseconds(100))
                HapticManager.gameStarted()
                store.dispatch(.completeRoleReveal)
            } else {
                // Show the next player's prompt
                withAnimation(.easeIn(duration: 0.25)) {
                    isTransitioning = false
                }
            }
        }
    }
}

// MARK: - Role Reveal Progress Bar

struct RoleRevealProgressBar: View {
    let current: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(LGColors.accentPrimary)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Role reveal progress")
        .accessibilityValue("\(current) of \(total) players have seen their role")
    }
}

// MARK: - Preview

#Preview {
    RoleRevealView()
        .environment(GameStore.previewInGame)
}
