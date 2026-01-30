//
//  GamePhase.swift
//  Imposter
//
//  State machine for game phases with validated transitions.
//

import Foundation

// MARK: - GamePhase

/// Represents the current phase of the game.
/// Transitions between phases are validated via `canTransition(to:)`.
enum GamePhase: String, Codable, CaseIterable, Sendable {
    /// Player configuration and settings
    case setup

    /// Secret word reveal to each player (pass-and-play)
    case roleReveal

    /// Players give clues in turn
    case clueRound

    /// Open discussion phase (optional timer)
    case discussion

    /// Cast votes for suspected Imposter
    case voting

    /// Reveal Imposter identity and results
    case reveal

    /// Final scoreboard and game over
    case summary

    // MARK: - State Machine

    /// Validates whether a transition to the given phase is allowed
    /// - Parameter next: The target phase to transition to
    /// - Returns: `true` if the transition is valid
    func canTransition(to next: GamePhase) -> Bool {
        switch (self, next) {
        // Setup flow
        case (.setup, .roleReveal):
            return true

        // Role reveal to gameplay
        case (.roleReveal, .clueRound):
            return true

        // Clue round can go to discussion, voting, or directly to reveal
        case (.clueRound, .discussion),
             (.clueRound, .voting),
             (.clueRound, .reveal):
            return true

        // Discussion to voting
        case (.discussion, .voting):
            return true

        // Voting to reveal
        case (.voting, .reveal):
            return true

        // Reveal goes directly to setup (no summary)
        case (.reveal, .setup):
            return true

        // All other transitions are invalid
        default:
            return false
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .setup: return "Setup"
        case .roleReveal: return "Role Reveal"
        case .clueRound: return "Clue Round"
        case .discussion: return "Discussion"
        case .voting: return "Voting"
        case .reveal: return "Reveal"
        case .summary: return "Summary"
        }
    }
}
