//
//  RevealView.swift
//  Imposter
//
//  Reveals the voting results and the Imposter's identity.
//

import SwiftUI

// MARK: - RevealView

/// Reveals voting results and the Imposter's identity
struct RevealView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showVotes = false
    @State private var showImposter = false
    @State private var showOutcome = false
    @State private var imposterGuess = ""
    @State private var hasGuessed = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            ScrollView {
                VStack(spacing: LGSpacing.extraLarge) {
                    // Title
                    Text("The Votes Are In...")
                        .font(LGTypography.displaySmall)
                        .foregroundStyle(.white)
                        .opacity(showVotes ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showVotes)

                    // Vote results
                    if showVotes {
                        voteResultsSection
                    }

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

    private var voteResultsSection: some View {
        LGCard {
            VStack(spacing: LGSpacing.medium) {
                Text("Vote Results")
                    .font(LGTypography.headlineSmall)

                ForEach(voteCounts.sorted(by: { $0.value > $1.value }), id: \.key) { playerID, count in
                    if let player = store.players.first(where: { $0.id == playerID }) {
                        HStack {
                            LGPlayerColorBadge(player.color, size: 24)
                            Text(player.name)
                                .font(LGTypography.bodyMedium)
                            Spacer()
                            Text("\(count) vote\(count == 1 ? "" : "s")")
                                .font(LGTypography.labelMedium)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
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
            // Secret word reveal
            LGCard {
                VStack(spacing: LGSpacing.medium) {
                    Text("The Secret Word Was")
                        .font(LGTypography.labelMedium)
                        .foregroundStyle(.secondary)

                    Text(store.secretWord ?? "Unknown")
                        .font(LGTypography.displaySmall)
                        .foregroundStyle(LGColors.accentPrimary)
                }
            }

            // Imposter word guess (if allowed and imposter was caught)
            if store.settings.allowImposterWordGuess && wasImposterCaught && !hasGuessed {
                imposterGuessSection
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

                TextField("Your guess...", text: $imposterGuess)
                    .textFieldStyle(.liquidGlass)

                LGButton("Submit Guess", style: .primary, icon: "lightbulb") {
                    submitGuess()
                }
            }
        }
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
            store.dispatch(.completeRound(imposterGuessedCorrectly: false))
        }
        .padding(.top, LGSpacing.medium)
    }

    // MARK: - Helpers

    private var imposter: Player? {
        store.imposter
    }

    private var voteCounts: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for suspectID in store.votes.values {
            counts[suspectID, default: 0] += 1
        }
        return counts
    }

    private var wasImposterCaught: Bool {
        guard let imposterID = store.state.roundState?.imposterID else { return false }
        let maxVotes = voteCounts.values.max() ?? 0
        let mostVoted = voteCounts.filter { $0.value == maxVotes }.map { $0.key }
        return mostVoted.contains(imposterID)
    }

    // MARK: - Actions

    private func startRevealSequence() {
        let baseDelay = reduceMotion ? 0.3 : 0.8

        withAnimation {
            showVotes = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay * 2) {
            withAnimation(LGMaterials.springAnimation) {
                showImposter = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay * 4) {
            withAnimation(LGMaterials.springAnimation) {
                showOutcome = true
            }
        }
    }

    private func submitGuess() {
        hasGuessed = true

        // Haptic feedback
        if imposterGuess.lowercased() == store.secretWord?.lowercased() {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
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
