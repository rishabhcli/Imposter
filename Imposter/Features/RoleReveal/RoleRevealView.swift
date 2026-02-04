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
    @State private var isHoldingCard = false
    @State private var holdProgress: CGFloat = 0

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
            // Player emoji avatar - large display with glass effect
            ZStack {
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(playerColor.opacity(0.3)),
                        in: .circle
                    )
                    .frame(width: 120, height: 120)

                Text(currentPlayer.emoji)
                    .font(.system(size: 70))
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .shadow(color: playerColor.opacity(0.5), radius: 20)
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

            // Reveal button with liquid glass and hold-to-reveal
            HoldToRevealButton(
                playerColor: playerColor,
                onReveal: {
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
                }
            )
            .padding(.top, LGSpacing.large)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(voiceOverRunning ? "Player's turn to reveal their role" : "Pass the device to \(currentPlayer.name), then hold Reveal My Role")
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

// MARK: - Hold to Reveal Button

/// Liquid glass button that requires hold gesture to reveal role - uses proper iOS 26 glass APIs
struct HoldToRevealButton: View {
    let playerColor: Color
    let onReveal: () -> Void
    
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var hasRevealed = false
    
    private let holdDuration: Double = 0.6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Progress fill underneath
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LGColors.accentPrimary.opacity(0.4))
                    .frame(width: geometry.size.width * holdProgress)
                    .animation(.linear(duration: 0.05), value: holdProgress)
                
                // Content with glass effect and interactive
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 20, weight: .bold))
                        .symbolEffect(.pulse, options: .repeating, isActive: !isHolding && !hasRevealed)
                    
                    Text(isHolding ? "Keep Holding..." : "Hold to Reveal")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .frame(height: 56)
            .glassEffect(
                .regular.tint(LGColors.accentPrimary.opacity(0.3)).interactive(),
                in: .rect(cornerRadius: 22)
            )
        }
        .frame(height: 56)
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.spring(response: 0.2), value: isHolding)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !hasRevealed else { return }
                    if !isHolding {
                        isHolding = true
                        HapticManager.buttonTap()
                        startHoldTimer()
                    }
                }
                .onEnded { _ in
                    if !hasRevealed {
                        cancelHold()
                    }
                }
        )
        .accessibilityLabel("Hold to Reveal My Role")
        .accessibilityHint("Press and hold to see your secret role")
    }
    
    private func startHoldTimer() {
        Task { @MainActor in
            let steps = 30
            let stepDuration = holdDuration / Double(steps)
            
            for i in 1...steps {
                guard isHolding && !hasRevealed else { return }
                try? await Task.sleep(for: .milliseconds(Int(stepDuration * 1000)))
                
                holdProgress = CGFloat(i) / CGFloat(steps)
                
                if i % 10 == 0 {
                    HapticManager.selectionChanged()
                }
            }
            
            if isHolding && !hasRevealed {
                hasRevealed = true
                HapticManager.imposterCaught()
                onReveal()
            }
        }
    }
    
    private func cancelHold() {
        isHolding = false
        withAnimation(.spring(response: 0.3)) {
            holdProgress = 0
        }
    }
}

// MARK: - Preview

#Preview {
    RoleRevealView()
        .environment(GameStore.previewInGame)
}
