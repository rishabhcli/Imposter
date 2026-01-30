//
//  ClueInputView.swift
//  Imposter
//
//  Text input for submitting clues with character limit.
//

import SwiftUI

// MARK: - ClueInputView

/// Button to advance to the next player's turn
struct ClueInputView: View {
    @Environment(GameStore.self) private var store
    let player: Player

    var body: some View {
        Button {
            advanceToNext()
        } label: {
            HStack(spacing: LGSpacing.small) {
                Image(systemName: "arrow.right")
                Text("Next")
            }
            .font(LGTypography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LGSpacing.medium)
        }
        .buttonStyle(.glass)
        .accessibilityIdentifier(AccessibilityIDs.submitClueButton)
    }

    // MARK: - Actions

    private func advanceToNext() {
        // Just advance to next player (verbal clues, no text needed)
        store.dispatch(.submitClue(playerID: player.id, text: "—"))
        HapticManager.clueSubmitted()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        ClueInputView(player: Player(name: "Alice", color: .crimson))
            .padding()
    }
    .environment(GameStore.previewInGame)
}
