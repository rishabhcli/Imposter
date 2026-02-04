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

    @State private var currentVoterIndex = 0
    @State private var hasVoted = false
    @State private var selectedPlayerID: UUID?
    @State private var voteConfirmationScale: CGFloat = 0.5
    @State private var headerOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var isTransitioning = false

    var body: some View {
        ZStack {
            // Background
            backgroundGradient

            VStack(spacing: LGSpacing.large) {
                // Header with progress
                headerSection
                    .opacity(headerOpacity)

                if isTransitioning {
                    // Empty state during transition
                    Color.clear
                } else if !hasVoted {
                    // Vote prompt
                    votePrompt
                        .offset(y: contentOffset)
                        .opacity(headerOpacity)
                    
                    // Self-vote explanation
                    selfVoteExplanation
                        .offset(y: contentOffset)
                        .opacity(headerOpacity)

                    // Player selection grid
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
                    // Vote confirmation
                    voteConfirmation
                }
            }
            .padding(LGSpacing.large)
        }
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

            // Progress bar
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
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

        withAnimation(LGMaterials.springAnimation) {
            hasVoted = true
        }
    }

    private func advanceToNextVoter() {
        HapticManager.buttonTap()
        
        // Phase 1: Hide current content
        withAnimation(.easeOut(duration: 0.2)) {
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            headerOpacity = 1.0
            contentOffset = 0
        }
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
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VotingView()
        .environment(GameStore.previewInGame)
}
