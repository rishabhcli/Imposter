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
        .preferredColorScheme(.dark) // Force dark mode for game's dark aesthetic
    }
}

// MARK: - Discussion View (Placeholder for optional phase)

/// Discussion phase view with optional timer
struct DiscussionView: View {
    @Environment(GameStore.self) private var store
    @State private var timeRemaining: Int = 60
    @State private var timerTask: Task<Void, Never>?
    @State private var isPulsing: Bool = false
    @State private var lastWarningThreshold: Int? = nil

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
        .onDisappear {
            // Cancel timer task to prevent memory leaks
            timerTask?.cancel()
            timerTask = nil
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: LGSpacing.small) {
            // Timer text with warning colors
            Text(timeString)
                .font(LGTypography.timer)
                .foregroundStyle(timerColor)
                .monospacedDigit()
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(isPulsing ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isPulsing)
                .accessibilityLabel("Time remaining: \(accessibleTimeString)")
                .accessibilityAddTraits(.updatesFrequently)
            
            // Warning label
            if let warningText = warningLabelText {
                Text(warningText)
                    .font(LGTypography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(timerColor)
                    .textCase(.uppercase)
                    .transition(.scale.combined(with: .opacity))
            }

            // Progress ring with warning colors
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timerGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // Urgent pulse effect for final seconds
                if timeRemaining <= 5 && timeRemaining > 0 {
                    Circle()
                        .stroke(LGColors.error.opacity(0.5), lineWidth: 12)
                        .scaleEffect(isPulsing ? 1.15 : 1.0)
                        .opacity(isPulsing ? 0 : 0.6)
                        .animation(.easeOut(duration: 0.8).repeatForever(autoreverses: false), value: isPulsing)
                }
            }
            .frame(width: 120, height: 120)
            .accessibilityHidden(true)
        }
        .onChange(of: timeRemaining) { oldValue, newValue in
            checkWarningThreshold(newValue)
        }
    }
    
    // MARK: - Timer Warning States
    
    private var timerColor: Color {
        switch timeRemaining {
        case 0...5:
            return LGColors.error
        case 6...10:
            return LGColors.warning
        case 11...30:
            return LGColors.caution
        default:
            return .white
        }
    }
    
    private var timerGradient: AngularGradient {
        let colors: [Color]
        switch timeRemaining {
        case 0...5:
            colors = [LGColors.error, LGColors.error.opacity(0.7)]
        case 6...10:
            colors = [LGColors.warning, LGColors.error]
        case 11...30:
            colors = [LGColors.caution, LGColors.warning]
        default:
            colors = [LGColors.accentPrimary, LGColors.accentSecondary]
        }
        return AngularGradient(colors: colors, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
    }
    
    private var warningLabelText: String? {
        switch timeRemaining {
        case 1...5:
            return "Hurry!"
        case 6...10:
            return "Almost out of time"
        case 11...30:
            return "Time running low"
        default:
            return nil
        }
    }
    
    private func checkWarningThreshold(_ time: Int) {
        // Trigger haptic and animation at warning thresholds
        let thresholds = [30, 10, 5]
        
        for threshold in thresholds {
            if time == threshold && lastWarningThreshold != threshold {
                lastWarningThreshold = threshold
                HapticManager.timerWarning()
                
                // Start pulsing at 5 seconds
                if threshold == 5 {
                    isPulsing = true
                }
                break
            }
        }
        
        // Stop pulsing when time runs out or resets
        if time == 0 || time > 30 {
            isPulsing = false
        }
    }
    
    private var accessibleTimeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") and \(seconds) second\(seconds == 1 ? "" : "s")"
        } else {
            return "\(seconds) second\(seconds == 1 ? "" : "s")"
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
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timeRemaining -= 1
            }
            
            if !Task.isCancelled && timeRemaining == 0 {
                store.dispatch(.startVoting)
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
