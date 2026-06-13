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
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences

    @State private var currentRevealIndex = 0
    @State private var voiceOverRunning = UIAccessibility.isVoiceOverRunning
    @State private var roleRevealed = false
    @State private var showContinueHint = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var isTransitioning = false
    @State private var isHoldingCard = false
    @State private var holdProgress: CGFloat = 0

    var body: some View {
        LGPhaseStage(
            phase: String(localized: "Role Reveal"),
            title: roleStageTitle,
            subtitle: roleStageSubtitle,
            icon: roleStageIcon,
            style: .gameplay,
            accentColor: playerColor
        ) {
            VStack(spacing: LGSpacing.extraLarge) {
                progressIndicator

                if isTransitioning {
                    Color.clear
                        .frame(minHeight: 360)
                } else if !roleRevealed {
                    passDevicePrompt
                        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    roleCardSection
                }
            }
        }
        .accessibilityIdentifier(AccessibilityIDs.roleRevealScreen)
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

    private var progressIndicator: some View {
        VStack(spacing: LGSpacing.small) {
            RoleRevealProgressBar(
                current: currentRevealIndex,
                total: store.players.count
            )
            .padding(.horizontal, LGSpacing.extraLarge)

            Text("Player \(currentRevealIndex + 1) of \(store.players.count)")
                .font(LGTypography.labelSmall)
                .foregroundStyle(.white.opacity(0.5))

            wordGenerationStatusBanner
        }
    }

    @ViewBuilder
    private var wordGenerationStatusBanner: some View {
        if isWaitingForSecretWord {
            statusBanner(
                icon: "sparkles",
                text: String(localized: "Creating secret word...")
            )
            .accessibilityIdentifier(AccessibilityIDs.wordGenerationStatus)
        } else if case .fallback(let reason) = store.wordGenerationStatus {
            statusBanner(
                icon: "arrow.triangle.2.circlepath",
                text: fallbackStatusText(for: reason)
            )
            .accessibilityIdentifier(AccessibilityIDs.wordGenerationStatus)
        }
    }

    private func statusBanner(icon: String, text: String) -> some View {
        HStack(spacing: LGSpacing.small) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))

            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.74))
        .padding(.horizontal, LGSpacing.medium)
        .padding(.vertical, LGSpacing.small)
        .glassEffect(.regular.tint(.cyan.opacity(0.14)), in: .capsule)
        .accessibilityElement(children: .combine)
    }

    private var passDevicePrompt: some View {
        VStack(spacing: LGSpacing.extraLarge) {
            // Player emoji avatar - large display with glass effect
            ZStack {
                if reduceTransparency {
                    Circle()
                        .fill(playerColor.opacity(0.35))
                        .frame(width: 120, height: 120)
                } else {
                    Circle()
                        .fill(.clear)
                        .glassEffect(
                            .regular.tint(playerColor.opacity(0.3)),
                            in: .circle
                        )
                        .frame(width: 120, height: 120)
                }

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
                    .accessibilityIdentifier(AccessibilityIDs.roleHandoffPrompt)

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
                isDisabled: isWaitingForSecretWord,
                onReveal: {
                    HapticManager.roleRevealed()
                    animateForAccessibility(LGMaterials.springAnimation) {
                        roleRevealed = true
                    }
                    // Show continue hint after delay
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(1500))
                        animateForAccessibility(.easeInOut(duration: 0.2)) {
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
                role: roleForCurrentPlayer,
                playerName: currentPlayer.name,
                playerEmoji: currentPlayer.emoji,
                playerColor: currentPlayer.color,
                generatedImage: store.state.roundState?.generatedImage,
                isGeneratingImage: store.isGeneratingImage
            )
            .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
            .frame(height: 560)

            // Continue hint with pulsing animation
            if showContinueHint {
                Text("Tap anywhere to continue")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.5))
                    .transition(reduceMotion ? .identity : .opacity)
                    .modifier(PulsingOpacityModifier())
            }
        }
    }

    private var roleStageTitle: String {
        if isTransitioning {
            return String(localized: "Private - Hand device to next player")
        }

        if roleRevealed {
            return String(localized: "Tap anywhere to continue")
        }

        if voiceOverRunning {
            return String(localized: "Player's turn to reveal their role")
        }

        return String(localized: "Pass the device to \(currentPlayer.name)")
    }

    private var roleStageSubtitle: String? {
        if isWaitingForSecretWord {
            return String(localized: "Preparing Word...")
        }

        return String(localized: "Player \(currentRevealIndex + 1) of \(store.players.count)")
    }

    private var roleStageIcon: String {
        if roleRevealed {
            return "lock.open.fill"
        }

        return isWaitingForSecretWord ? "sparkles" : "lock.shield.fill"
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

    private var isWaitingForSecretWord: Bool {
        store.settings.wordSource == .customPrompt &&
            (store.isGeneratingWord || secretWord == "GENERATING...")
    }

    private var categoryHint: String {
        store.state.roundState?.categoryHint ?? "Unknown"
    }

    private var imposterHint: String {
        // Use AI-generated hint if available, otherwise fallback to category
        store.state.roundState?.imposterHint ?? categoryHint
    }

    private var imposterWord: String? {
        store.state.roundState?.imposterWord
    }

    private var isHiddenMode: Bool {
        store.settings.gameMode == .hidden
    }

    private var roleForCurrentPlayer: Role {
        if isCurrentPlayerImposter {
            if isHiddenMode, let word = imposterWord {
                // Hidden mode: imposter gets a different word and doesn't know they're the imposter
                return .hiddenImposter(word: word)
            } else {
                // Classic mode: imposter knows their role and gets a hint
                return .imposter(hint: imposterHint)
            }
        } else {
            return .informed(word: secretWord)
        }
    }

    private func fallbackStatusText(for reason: WordGenerationFallbackReason) -> String {
        switch reason {
        case .generationFailed:
            return String(localized: "Using a pack word for this round.")
        case .duplicateRecentWord:
            return String(localized: "Generated word repeated a recent round. Using a pack word.")
        case .nearDuplicateWord:
            return String(localized: "Generated word was too close to the prompt or a recent round. Using a pack word.")
        }
    }

    // MARK: - Actions

    private func handleTap() {
        guard roleRevealed else { return }
        guard !isTransitioning else { return }
        
        HapticManager.buttonTap()

        // Phase 1: Hide the current role card
        animateForAccessibility(.easeOut(duration: 0.2)) {
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
                animateForAccessibility(.easeIn(duration: 0.25)) {
                    isTransitioning = false
                }
            }
        }
    }

    private func animateForAccessibility(
        _ animation: Animation?,
        _ updates: @escaping () -> Void
    ) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }

    private var reduceMotion: Bool {
        systemReduceMotion || accessibilityPreferences.forceReduceMotion
    }

    private var reduceTransparency: Bool {
        systemReduceTransparency || accessibilityPreferences.forceReduceTransparency
    }
}

// MARK: - Role Reveal Progress Bar

struct RoleRevealProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences

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
                    .animation(reduceMotion ? nil : .spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Role reveal progress")
        .accessibilityValue("\(current) of \(total) players have seen their role")
    }

    private var reduceMotion: Bool {
        systemReduceMotion || accessibilityPreferences.forceReduceMotion
    }
}

// MARK: - Hold to Reveal Button

/// Liquid glass button that requires hold gesture to reveal role - uses proper iOS 26 glass APIs
struct HoldToRevealButton: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences

    let playerColor: Color
    let isDisabled: Bool
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
                    .animation(reduceMotion ? nil : .linear(duration: 0.05), value: holdProgress)
                
                // Content with glass effect and interactive
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 20, weight: .bold))
                        .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion && !isHolding && !hasRevealed)
                    
                    Text(buttonTitle)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .contentTransition(.numericText())
                }
                .foregroundStyle(isDisabled ? .white.opacity(0.58) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(reduceTransparency ? LGColors.accentPrimary.opacity(0.85) : .clear)
                    .if(!reduceTransparency) { view in
                        view.glassEffect(
                            .regular.tint(LGColors.accentPrimary.opacity(0.3)).interactive(),
                            in: .rect(cornerRadius: 22)
                        )
                    }
            }
        }
        .frame(height: 56)
        .opacity(isDisabled ? 0.72 : 1)
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.2), value: isHolding)
        .onLongPressGesture(
            minimumDuration: holdDuration,
            maximumDistance: 44,
            perform: completeReveal,
            onPressingChanged: { pressing in
                if pressing {
                    beginHold()
                } else if !hasRevealed {
                    cancelHold()
                }
            }
        )
        .accessibilityLabel(isDisabled ? "Preparing Word..." : "Hold to Reveal My Role")
        .accessibilityHint(isDisabled ? "Please wait until the secret word is ready." : "Press and hold to see your secret role")
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            completeReveal()
        }
        .accessibilityIdentifier(AccessibilityIDs.revealRoleButton)
    }

    private func beginHold() {
        guard !isDisabled else { return }
        guard !hasRevealed, !isHolding else { return }
        isHolding = true
        HapticManager.buttonTap()
        startHoldTimer()
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
                completeReveal()
            }
        }
    }

    private func completeReveal() {
        guard !isDisabled else { return }
        guard !hasRevealed else { return }
        isHolding = false
        holdProgress = 1
        hasRevealed = true
        HapticManager.imposterCaught()
        onReveal()
    }
    
    private func cancelHold() {
        isHolding = false
        if reduceMotion {
            holdProgress = 0
        } else {
            withAnimation(.spring(response: 0.3)) {
                holdProgress = 0
            }
        }
    }

    private var reduceMotion: Bool {
        systemReduceMotion || accessibilityPreferences.forceReduceMotion
    }

    private var reduceTransparency: Bool {
        systemReduceTransparency || accessibilityPreferences.forceReduceTransparency
    }

    private var buttonTitle: String {
        if isDisabled {
            return String(localized: "Preparing Word...")
        }

        return isHolding ? String(localized: "Keep Holding...") : String(localized: "Hold to Reveal")
    }
}

// MARK: - Preview

#Preview {
    RoleRevealView()
        .environment(GameStore.previewInGame)
}
