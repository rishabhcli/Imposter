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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.imposterAccessibilityPreferences) private var accessibilityPreferences

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
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
            .animation(reduceMotion ? nil : LGMaterials.springAnimation, value: store.currentPhase)
            .accessibilityHidden(shouldShowPrivacyShield)

            // Error toast
            if let errorMessage = store.errorMessage {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(LGColors.warning)
                    Text(errorMessage)
                        .font(LGTypography.bodySmall)
                        .foregroundStyle(.white)
                }
                .padding(LGSpacing.medium)
                .background {
                    Capsule()
                        .fill(reduceTransparency ? LGColors.error.opacity(0.85) : .clear)
                        .if(!reduceTransparency) { view in
                            view.glassEffect(.regular.tint(LGColors.error.opacity(0.3)), in: .capsule)
                        }
                }
                .padding(.horizontal, LGSpacing.large)
                .padding(.bottom, LGSpacing.extraLarge)
                .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
                .animation(reduceMotion ? nil : .spring(response: 0.4), value: store.errorMessage)
            }

            if shouldShowPrivacyShield {
                PrivacyShieldView()
                    .transition(reduceMotion ? .identity : .opacity)
                    .zIndex(10)
            }

            if shouldExposeAccessibilityPreferencesStatus {
                AccessibilityPreferencesStatusView(
                    reduceMotion: reduceMotion,
                    reduceTransparency: reduceTransparency
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var shouldShowPrivacyShield: Bool {
        store.currentPhase != .setup && (scenePhase != .active || isPrivacyShieldForced)
    }

    private var isPrivacyShieldForced: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-force-privacy-shield")
    }

    private var shouldExposeAccessibilityPreferencesStatus: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing-reduce-motion") ||
        ProcessInfo.processInfo.arguments.contains("-ui-testing-reduce-transparency")
    }

    private var reduceMotion: Bool {
        systemReduceMotion || accessibilityPreferences.forceReduceMotion
    }

    private var reduceTransparency: Bool {
        systemReduceTransparency || accessibilityPreferences.forceReduceTransparency
    }
}

// MARK: - Privacy Shield

/// Covers private game state while the app is inactive so app switcher snapshots do not expose roles or words.
private struct PrivacyShieldView: View {
    @AccessibilityFocusState private var isShieldFocused: Bool

    var body: some View {
        ZStack {
            visualShield
                .accessibilityHidden(true)

            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Private game hidden. Return to Imposter to continue.")
                .accessibilityHint("Private content underneath is hidden from VoiceOver.")
                .accessibilityIdentifier(AccessibilityIDs.privacyShield)
                .accessibilityFocused($isShieldFocused)
                .accessibilitySortPriority(10)
        }
        .onAppear {
            isShieldFocused = true
        }
    }

    private var visualShield: some View {
        ZStack {
            LGColors.darkBackground
                .ignoresSafeArea()

            VStack(spacing: LGSpacing.medium) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(LGColors.accentPrimary)

                Text("Private Game Hidden")
                    .font(LGTypography.headlineMedium)
                    .foregroundStyle(.white)

                Text("Return to Imposter to continue pass-and-play.")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(LGSpacing.extraLarge)
        }
    }
}

// MARK: - Accessibility Preferences Status

private struct AccessibilityPreferencesStatusView: View {
    let reduceMotion: Bool
    let reduceTransparency: Bool

    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 1, height: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(statusLabel)
            .accessibilityIdentifier(AccessibilityIDs.accessibilityPreferencesStatus)
            .accessibilityHidden(false)
    }

    private var statusLabel: String {
        "Reduce Motion \(reduceMotion ? "enabled" : "disabled"). Reduce Transparency \(reduceTransparency ? "enabled" : "disabled")."
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
