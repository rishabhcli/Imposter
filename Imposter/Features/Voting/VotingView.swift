//
//  VotingView.swift
//  Imposter
//
//  Enhanced pass-and-play voting with progress bar, self-vote explanation, and better feedback.
//

import SwiftUI

// MARK: - VotingView

/// Handles the pass-and-play voting sequence for all players
struct VotingView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences

    @State private var currentVoterIndex = 0
    @State private var hasVoted = false
    @State private var selectedPlayerID: UUID?
    @State private var voteConfirmationScale: CGFloat = 0.5
    @State private var headerOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var isTransitioning = false

    var body: some View {
        LGPhaseStage(
            phase: String(localized: "Voting"),
            title: votingStageTitle,
            subtitle: votingStageSubtitle,
            icon: votingStageIcon,
            style: .gameplay,
            accentColor: votingStageAccentColor
        ) {
            VStack(spacing: LGSpacing.large) {
                votingProgressSection
                    .opacity(headerOpacity)

                if isTransitioning {
                    Color.clear
                        .frame(minHeight: 320)
                } else if !hasVoted {
                    votePrompt
                        .offset(y: contentOffset)
                        .opacity(headerOpacity)
                    
                    selfVoteExplanation
                        .offset(y: contentOffset)
                        .opacity(headerOpacity)

                    PlayerSelectionGrid(
                        players: selectablePlayers,
                        selectedID: $selectedPlayerID,
                        onSelect: { playerID in
                            castVote(for: playerID)
                        }
                    )
                    .offset(y: contentOffset)
                    .opacity(headerOpacity)
                } else {
                    voteConfirmation
                }
            }
        }
        .accessibilityIdentifier(AccessibilityIDs.votingScreen)
        .contentShape(Rectangle())
        .onTapGesture {
            if hasVoted && !isTransitioning {
                advanceToNextVoter()
            }
        }
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Subviews

    private var votingProgressSection: some View {
        VStack(spacing: LGSpacing.small) {
            VotingProgressBar(
                current: currentVoterIndex,
                total: store.players.count,
                hasVoted: hasVoted
            )
            .padding(.horizontal, LGSpacing.extraLarge)

            // Progress text with percentage
            HStack(spacing: LGSpacing.small) {
                Text("Vote \(currentVoterIndex + 1) of \(store.players.count)")
                    .font(LGTypography.labelSmall)
                    .foregroundStyle(.white.opacity(0.6))
                
                Text("•")
                    .foregroundStyle(.white.opacity(0.3))
                
                Text("\(progressPercentage)%")
                    .font(LGTypography.labelSmall)
                    .foregroundStyle(LGColors.accentPrimary)
            }
        }
    }

    private var votingStageTitle: String {
        if hasVoted {
            return String(localized: "Vote Recorded!")
        }

        return String(localized: "Who do you think is the Imposter?")
    }

    private var votingStageSubtitle: String? {
        if hasVoted {
            if currentVoterIndex < store.players.count - 1 {
                return String(localized: "Pass the device to \(nextVoterName)")
            }

            return String(localized: "All votes are in!")
        }

        return String(localized: "Vote \(currentVoterIndex + 1) of \(store.players.count)")
    }

    private var votingStageIcon: String {
        hasVoted ? "checkmark.seal.fill" : "person.2.badge.key.fill"
    }

    private var votingStageAccentColor: Color {
        hasVoted ? LGColors.success : LGColors.accentPrimary
    }
    
    private var progressPercentage: Int {
        guard store.players.count > 0 else { return 0 }
        return Int((Double(currentVoterIndex) / Double(store.players.count)) * 100)
    }

    private var votePrompt: some View {
        LGCard {
            VStack(spacing: LGSpacing.medium) {
                HStack(spacing: LGSpacing.medium) {
                    // Player avatar
                    ZStack {
                        Circle()
                            .fill(LGColors.playerColor(currentVoter.color))
                            .frame(width: 50, height: 50)
                        
                        Text(currentVoter.emoji)
                            .font(.system(size: 30))
                    }

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
    
    private var selfVoteExplanation: some View {
        HStack(spacing: LGSpacing.small) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(LGColors.accentPrimary.opacity(0.8))
            
            Text("You can't vote for yourself")
                .font(LGTypography.labelSmall)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, LGSpacing.small)
    }

    private var voteConfirmation: some View {
        VStack(spacing: LGSpacing.extraLarge) {
            // Animated checkmark
            ZStack {
                // Success glow
                Circle()
                    .fill(LGColors.success.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(voteConfirmationScale * 1.2)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(LGColors.success)
                    .scaleEffect(voteConfirmationScale)
            }

            VStack(spacing: LGSpacing.medium) {
                Text("Vote Recorded!")
                    .font(LGTypography.headlineMedium)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier(AccessibilityIDs.voteHandoffPrompt)

                if currentVoterIndex < store.players.count - 1 {
                    Text("Pass the device to \(nextVoterName)")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Text("All votes are in!")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(LGColors.accentPrimary)
                }
            }

            // Pulsing hint
            Text("Tap anywhere to continue")
                .font(LGTypography.bodySmall)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, LGSpacing.large)
                .modifier(PulsingOpacityModifier())
        }
        .onAppear {
            animateForAccessibility(.spring(response: 0.4, dampingFraction: 0.6)) {
                voteConfirmationScale = 1.0
            }
        }
    }
    
    private var nextVoterName: String {
        let nextIndex = currentVoterIndex + 1
        guard nextIndex < store.players.count else { return "the next player" }
        return store.players[nextIndex].name
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

        // Triple haptic pattern for vote confirmation
        HapticManager.voteSelected()
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            HapticManager.playImpact(.light)
            try? await Task.sleep(for: .milliseconds(100))
            HapticManager.playImpact(.light)
        }

        animateForAccessibility(LGMaterials.springAnimation) {
            hasVoted = true
        }
    }

    private func advanceToNextVoter() {
        HapticManager.buttonTap()
        
        // Phase 1: Hide current content
        animateForAccessibility(.easeOut(duration: 0.2)) {
            isTransitioning = true
            hasVoted = false
            headerOpacity = 0
            contentOffset = 30
        }
        
        // Phase 2: Update index and show new content
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            selectedPlayerID = nil
            voteConfirmationScale = 0.5
            currentVoterIndex += 1
            
            // Check if all players have voted
            if currentVoterIndex >= store.players.count {
                try? await Task.sleep(for: .milliseconds(100))
                store.dispatch(.completeVoting)
            } else {
                isTransitioning = false
                startEntranceAnimation()
            }
        }
    }
    
    private func startEntranceAnimation() {
        animateForAccessibility(.spring(response: 0.5, dampingFraction: 0.8)) {
            headerOpacity = 1.0
            contentOffset = 0
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
}

// MARK: - Voting Progress Bar

struct VotingProgressBar: View {
    let current: Int
    let total: Int
    let hasVoted: Bool
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        let completed = hasVoted ? current + 1 : current
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [LGColors.accentPrimary, LGColors.accentPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Voting progress")
        .accessibilityValue("\(current) of \(total) votes cast")
    }
}

// MARK: - Pulsing Opacity Modifier

struct PulsingOpacityModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(!reduceMotion && isPulsing ? 0.3 : 1.0)
            .onAppear {
                guard !reduceMotion else { return }

                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onChange(of: reduceMotion) { _, isReduced in
                if isReduced {
                    isPulsing = false
                }
            }
    }

    private var reduceMotion: Bool {
        systemReduceMotion || accessibilityPreferences.forceReduceMotion
    }
}

// MARK: - Preview

#Preview {
    VotingView()
        .environment(GameStore.previewInGame)
}
