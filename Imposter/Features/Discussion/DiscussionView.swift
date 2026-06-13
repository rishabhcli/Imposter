//
//  DiscussionView.swift
//  Imposter
//
//  Discussion phase view with optional timer.
//

import SwiftUI

// MARK: - DiscussionView

/// Discussion phase view with optional timer
struct DiscussionView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences

    @State private var timeRemaining: Int = 60
    @State private var timerTask: Task<Void, Never>?
    @State private var isPulsing: Bool = false
    @State private var lastWarningThreshold: Int? = nil

    var body: some View {
        LGPhaseStage(
            phase: String(localized: "Discussion"),
            title: String(localized: "Discussion Time"),
            subtitle: String(localized: "Compare clues without saying the secret word."),
            icon: "bubble.left.and.bubble.right.fill",
            style: .gameplay,
            accentColor: LGColors.accentPrimary
        ) {
            VStack(spacing: LGSpacing.large) {
                if store.settings.discussionTimerEnabled {
                    timerDisplay
                }

                discussionPromptCard
            }
            .accessibilityIdentifier(AccessibilityIDs.discussionScreen)
        } footer: {
            LGLargeButton(String(localized: "Start Voting"), icon: "hand.raised.fill") {
                store.dispatch(.startVoting)
            }
            .accessibilityIdentifier(AccessibilityIDs.startVotingButton)
        }
        .onAppear {
            if store.settings.discussionTimerEnabled {
                timeRemaining = store.settings.discussionSeconds
                startTimer()
            }
        }
        .onDisappear {
            timerTask?.cancel()
            timerTask = nil
        }
    }

    private var discussionPromptCard: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LGColors.accentPrimary)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(LGColors.accentPrimary.opacity(0.16))
                        }

                    VStack(alignment: .leading, spacing: LGSpacing.extraSmall) {
                        Text(String(localized: "Table Talk"))
                            .font(LGTypography.headlineSmall)
                            .foregroundStyle(.primary)

                        Text(String(localized: "Everyone gets one clue. Challenge patterns, ask follow-ups, and keep the word private."))
                            .font(LGTypography.bodyMedium)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var timerDisplay: some View {
        VStack(spacing: LGSpacing.small) {
            Text(timeString)
                .font(LGTypography.timer)
                .foregroundStyle(timerColor)
                .monospacedDigit()
                .scaleEffect(shouldPulse ? 1.1 : 1.0)
                .animation(shouldPulse ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : nil, value: isPulsing)
                .accessibilityLabel("Time remaining: \(accessibleTimeString)")
                .accessibilityAddTraits(.updatesFrequently)

            if let warningText = warningLabelText {
                Text(warningText)
                    .font(LGTypography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(timerColor)
                    .textCase(.uppercase)
                    .transition(.scale.combined(with: .opacity))
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timerGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)

                if timeRemaining <= 5 && timeRemaining > 0 {
                    Circle()
                        .stroke(LGColors.error.opacity(0.5), lineWidth: 12)
                        .scaleEffect(shouldPulse ? 1.15 : 1.0)
                        .opacity(shouldPulse ? 0 : 0.6)
                        .animation(shouldPulse ? .easeOut(duration: 0.8).repeatForever(autoreverses: false) : nil, value: isPulsing)
                }
            }
            .frame(width: 120, height: 120)
            .accessibilityHidden(true)
        }
        .onChange(of: timeRemaining) { _, newValue in
            checkWarningThreshold(newValue)
        }
    }

    // MARK: - Timer Warning States

    private var timerColor: Color {
        switch timeRemaining {
        case 0...5: return LGColors.error
        case 6...10: return LGColors.warning
        case 11...30: return LGColors.caution
        default: return .white
        }
    }

    private var timerGradient: AngularGradient {
        let colors: [Color]
        switch timeRemaining {
        case 0...5: colors = [LGColors.error, LGColors.error.opacity(0.7)]
        case 6...10: colors = [LGColors.warning, LGColors.error]
        case 11...30: colors = [LGColors.caution, LGColors.warning]
        default: colors = [LGColors.accentPrimary, LGColors.accentSecondary]
        }
        return AngularGradient(colors: colors, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
    }

    private var warningLabelText: String? {
        switch timeRemaining {
        case 1...5: return "Hurry!"
        case 6...10: return "Almost out of time"
        case 11...30: return "Time running low"
        default: return nil
        }
    }

    private func checkWarningThreshold(_ time: Int) {
        let thresholds = [30, 10, 5]
        for threshold in thresholds {
            if time == threshold && lastWarningThreshold != threshold {
                lastWarningThreshold = threshold
                HapticManager.timerWarning()
                if threshold == 5 {
                    isPulsing = !reduceMotion
                }
                break
            }
        }
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

    private var shouldPulse: Bool {
        isPulsing && !reduceMotion
    }

    private var reduceMotion: Bool {
        systemReduceMotion || accessibilityPreferences.forceReduceMotion
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

#Preview {
    DiscussionView()
        .environment(GameStore.preview)
}
