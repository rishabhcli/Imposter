//
//  SummaryView.swift
//  Imposter
//
//  Simple game over view (not actively used - game returns to setup after reveal).
//

import SwiftUI

// MARK: - SummaryView

/// Simple game over view - primarily a fallback since game goes directly to setup
struct SummaryView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            // Background
            LGColors.darkBackground
                .ignoresSafeArea()

            VStack(spacing: LGSpacing.extraLarge) {
                Spacer()

                // Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LGColors.success)

                // Title
                Text("Game Complete")
                    .font(LGTypography.displaySmall)
                    .foregroundStyle(.white)

                Text("Thanks for playing!")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                // Return home button
                LGLargeButton("New Game", icon: "arrow.counterclockwise") {
                    store.dispatch(.returnToHome)
                }
                .padding(.horizontal, LGSpacing.large)
                .padding(.bottom, LGSpacing.extraLarge)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
        .environment(GameStore.previewInGame)
}
