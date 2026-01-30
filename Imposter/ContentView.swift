//
//  ContentView.swift
//  Imposter
//
//  Root view that switches between game phases.
//

import SwiftUI

// MARK: - ContentView

/// Root container view that switches display based on current game phase
struct ContentView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        Group {
            switch store.currentPhase {
            case .setup:
                HomeView()

            case .roleReveal:
                RoleRevealView()

            case .clueRound:
                ClueRoundView()

            case .discussion:
                DiscussionView()

            case .voting:
                VotingView()

            case .reveal:
                RevealView()

            case .summary:
                SummaryView()
            }
        }
        .animation(LGMaterials.springAnimation, value: store.currentPhase)
    }
}

// MARK: - Discussion View (Placeholder for optional phase)

/// Discussion phase view with optional timer
struct DiscussionView: View {
    @Environment(GameStore.self) private var store
    @State private var timeRemaining: Int = 60
    @State private var timerActive = false

    var body: some View {
        ZStack {
            // Background
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

            VStack(spacing: LGSpacing.extraLarge) {
                Spacer()

                // Icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.5))

                // Title
                Text("Discussion Time")
                    .font(LGTypography.displayMedium)
                    .foregroundStyle(.white)

                // Timer (if enabled)
                if store.settings.discussionTimerEnabled {
                    timerDisplay
                }

                // Instructions
                Text("Discuss who you think is the Imposter. Don't reveal your clues or the secret word!")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LGSpacing.large)

                Spacer()

                // Start voting button
                LGLargeButton("Start Voting", icon: "hand.raised.fill") {
                    store.dispatch(.startVoting)
                }
                .padding(.horizontal, LGSpacing.large)
                .padding(.bottom, LGSpacing.extraLarge)
            }
        }
        .onAppear {
            if store.settings.discussionTimerEnabled {
                timeRemaining = store.settings.discussionSeconds
                startTimer()
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: LGSpacing.small) {
            Text(timeString)
                .font(LGTypography.timer)
                .foregroundStyle(timeRemaining <= 10 ? LGColors.warning : .white)
                .monospacedDigit()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timeRemaining <= 10 ? LGColors.warning : LGColors.accentPrimary,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }
            .frame(width: 120, height: 120)
        }
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var progress: Double {
        guard store.settings.discussionSeconds > 0 else { return 0 }
        return Double(timeRemaining) / Double(store.settings.discussionSeconds)
    }

    private func startTimer() {
        timerActive = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 && timerActive {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                if timeRemaining == 0 {
                    store.dispatch(.startVoting)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Setup Phase") {
    ContentView()
        .environment(GameStore.preview)
}

#Preview("Role Reveal Phase") {
    ContentView()
        .environment(GameStore.previewInGame)
}
