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
        ZStack(alignment: .bottom) {
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
                .glassEffect(.regular.tint(LGColors.error.opacity(0.3)), in: .capsule)
                .padding(.horizontal, LGSpacing.large)
                .padding(.bottom, LGSpacing.extraLarge)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: store.errorMessage)
            }
        }
        .preferredColorScheme(.dark)
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
