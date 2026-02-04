//
//  RevealView.swift
//  Imposter
//
//  Enhanced reveal view with vote bars, word hints, and better animations.
//

import SwiftUI

// MARK: - RevealView

/// Reveals voting results and the Imposter's identity with visual vote bars
struct RevealView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showImposter = false
    @State private var showOutcome = false
    @State private var imposterGuess = ""
    @State private var hasGuessed = false
    @State private var guessResult: Bool?
    @State private var titleScale: CGFloat = 0.8
    @State private var buttonOffset: CGFloat = 40
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            ScrollView {
                VStack(spacing: LGSpacing.extraLarge) {
                    // Title with scale animation
                    Text("The Votes Are In...")
                        .font(LGTypography.displaySmall)
                        .foregroundStyle(.white)
                        .scaleEffect(titleScale)
                        .opacity(showImposter ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showImposter)

                    // Imposter reveal
                    if showImposter {
                        imposterRevealSection
                    }

                    // Outcome
                    if showOutcome {
                        outcomeSection
                    }

                    // Continue button
                    if showOutcome {
                        continueButton
                    }
                }
                .padding(LGSpacing.large)
            }
        }
        .onAppear {
            startRevealSequence()
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

    private var imposterRevealSection: some View {
        VStack(spacing: LGSpacing.large) {
            RevealAnimationView(
                imposter: imposter,
                wasCorrect: wasImposterCaught,
                reduceMotion: reduceMotion
            )
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var outcomeSection: some View {
        VStack(spacing: LGSpacing.large) {
            // Secret word reveal with AI-generated image
            secretWordRevealCard

            // Imposter word guess (if allowed and imposter was caught)
            if store.settings.allowImposterWordGuess && wasImposterCaught && !hasGuessed {
                imposterGuessSection
            }
            
            // Guess result (if guessed)
            if hasGuessed, let result = guessResult {
                guessResultSection(correct: result)
            }

            // Outcome message
            outcomeMessage
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var imposterGuessSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(spacing: LGSpacing.medium) {
                Text("Imposter's Last Chance!")
                    .font(LGTypography.headlineSmall)
                    .foregroundStyle(LGColors.imposter)

                Text("\(imposter?.name ?? "Imposter"), can you guess the secret word?")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Word length hint
                if let word = store.secretWord {
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(LGColors.warning)
                        Text("Hint: The word has \(word.count) letters")
                            .font(LGTypography.labelMedium)
                            .foregroundStyle(LGColors.warning)
                    }
                    .padding(.vertical, LGSpacing.small)
                }

                // Guess input with character counter
                VStack(alignment: .trailing, spacing: LGSpacing.extraSmall) {
                    TextField("Your guess...", text: $imposterGuess)
                        .textFieldStyle(.liquidGlass)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    
                    Text("\(imposterGuess.count)/30")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                // Submit button with validation
                LGButton(
                    "Submit Guess",
                    style: .primary,
                    icon: "lightbulb",
                    isDisabled: imposterGuess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    submitGuess()
                }
            }
        }
    }
    
    @ViewBuilder
    private func guessResultSection(correct: Bool) -> some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(spacing: LGSpacing.medium) {
                if correct {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LGColors.warning)
                    
                    Text("Correct Guess!")
                        .font(LGTypography.headlineMedium)
                        .foregroundStyle(LGColors.warning)
                    
                    Text("\(imposter?.name ?? "The Imposter") guessed the word and earns bonus points!")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LGColors.imposter)
                    
                    Text("Wrong Guess")
                        .font(LGTypography.headlineMedium)
                        .foregroundStyle(LGColors.imposter)
                    
                    VStack(spacing: LGSpacing.small) {
                        Text("You guessed: \"\(imposterGuess)\"")
                            .font(LGTypography.bodyMedium)
                            .foregroundStyle(.secondary)
                        
                        Text("The word was: \"\(store.secretWord ?? "Unknown")\"")
                            .font(LGTypography.bodyMedium)
                            .foregroundStyle(LGColors.accentPrimary)
                    }
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var outcomeMessage: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(spacing: LGSpacing.medium) {
                if wasImposterCaught {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LGColors.success)

                    Text("The Imposter Was Caught!")
                        .font(LGTypography.headlineMedium)
                        .foregroundStyle(LGColors.success)

                    Text("The informed players successfully identified the Imposter.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(LGColors.imposter)

                    Text("The Imposter Escaped!")
                        .font(LGTypography.headlineMedium)
                        .foregroundStyle(LGColors.imposter)

                    Text("The Imposter successfully blended in and wasn't caught.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var continueButton: some View {
        LGLargeButton("New Game", icon: "arrow.counterclockwise") {
            HapticManager.roundCompleted()
            store.dispatch(.completeRound(imposterGuessedCorrectly: guessResult ?? false))
        }
        .padding(.top, LGSpacing.medium)
        .offset(y: buttonOffset)
        .opacity(buttonOpacity)
    }

    private var secretWordRevealCard: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge, elevation: LGMaterials.elevation3) {
            VStack(spacing: LGSpacing.medium) {
                Text("The Secret Word Was")
                    .font(LGTypography.labelMedium)
                    .foregroundStyle(.secondary)

                Text(store.secretWord ?? "Unknown")
                    .font(LGTypography.displaySmall)
                    .foregroundStyle(LGColors.accentPrimary)
                
                // AI-generated image (if available)
                if let generatedImage = store.state.roundState?.generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: LGColors.accentPrimary.opacity(0.3), radius: 15, y: 5)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Word length indicator
                if let word = store.secretWord {
                    Text("\(word.count) letters")
                        .font(LGTypography.labelSmall)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helpers

    private var imposter: Player? {
        store.imposter
    }

    private var wasImposterCaught: Bool {
        guard let imposterID = store.state.roundState?.imposterID else { return false }
        // Calculate vote counts inline
        var counts: [UUID: Int] = [:]
        for suspectID in store.votes.values {
            counts[suspectID, default: 0] += 1
        }
        let maxVoteCount = counts.values.max() ?? 0
        let mostVoted = counts.filter { $0.value == maxVoteCount }.map { $0.key }
        return mostVoted.contains(imposterID)
    }

    // MARK: - Actions

    private func startRevealSequence() {
        let baseDelay = reduceMotion ? 0.3 : 0.8

        // Show imposter reveal with title animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showImposter = true
            titleScale = 1.0
        }

        // Show outcome after a delay
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(baseDelay * 2.5 * 1000)))
            withAnimation(LGMaterials.springAnimation) {
                showOutcome = true
            }
            
            // Animate the button in
            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                buttonOffset = 0
                buttonOpacity = 1.0
            }
        }
    }

    private func submitGuess() {
        let trimmedGuess = imposterGuess.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = trimmedGuess.lowercased() == store.secretWord?.lowercased()
        
        hasGuessed = true
        
        withAnimation(LGMaterials.springAnimation) {
            guessResult = isCorrect
        }

        // Haptic feedback
        if isCorrect {
            HapticManager.playNotification(.success)
        } else {
            HapticManager.playNotification(.error)
        }
    }
}

// MARK: - Reveal Animation View

struct RevealAnimationView: View {
    let imposter: Player?
    let wasCorrect: Bool
    let reduceMotion: Bool

    @State private var revealed = false
    @State private var showGlow = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: LGSpacing.large) {
            // Dramatic title
            Text(revealed ? "THE IMPOSTER IS..." : "REVEALING...")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [LGColors.imposter, LGColors.imposter.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: LGColors.imposter.opacity(0.5), radius: 10)

            // Imposter identity
            ZStack {
                // Pulsing glow behind
                if showGlow {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [LGColors.imposter.opacity(0.6), LGColors.imposter.opacity(0)],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(pulseScale)
                }

                // Question mark (before reveal)
                if !revealed {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 140, height: 140)

                        Image(systemName: "questionmark")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .transition(.scale)
                }

                // Imposter reveal - show their emoji dramatically
                if revealed, let imposter = imposter {
                    VStack(spacing: LGSpacing.medium) {
                        // Large avatar with emoji
                        ZStack {
                            Circle()
                                .fill(LGColors.playerColor(imposter.color))
                                .frame(width: 140, height: 140)

                            Text(imposter.emoji)
                                .font(.system(size: 80))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [LGColors.imposter, .red.opacity(0.5), LGColors.imposter],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                        }
                        .shadow(color: LGColors.imposter.opacity(0.6), radius: 20)

                        // Player name
                        Text(imposter.name)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)

                        // Imposter badge
                        Text("IMPOSTER")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(.white)
                            .padding(.horizontal, LGSpacing.large)
                            .padding(.vertical, LGSpacing.small)
                            .background {
                                Capsule()
                                    .fill(LGColors.imposter)
                            }
                            .shadow(color: LGColors.imposter.opacity(0.5), radius: 8)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 280)
        }
        .onAppear {
            startDramaticReveal()
        }
    }

    private func startDramaticReveal() {
        let revealDelay = reduceMotion ? 0.3 : 1.2

        // Start the glow animation
        withAnimation(.easeIn(duration: 0.3)) {
            showGlow = true
        }

        // Pulsing animation
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }

        // Reveal the imposter
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(revealDelay * 1000)))
            
            // Stop pulsing
            withAnimation(.spring(response: 0.3)) {
                pulseScale = 1.0
            }

            // Reveal with dramatic animation
            withAnimation(reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.5, dampingFraction: 0.6)) {
                revealed = true
            }

            // Haptic feedback
            HapticManager.playNotification(.warning)
        }
    }
}

// MARK: - Preview

#Preview {
    RevealView()
        .environment(GameStore.previewInGame)
}
