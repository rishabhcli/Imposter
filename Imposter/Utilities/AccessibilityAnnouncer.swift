//
//  AccessibilityAnnouncer.swift
//  Imposter
//
//  Handles VoiceOver announcements for game events.
//

import UIKit

// MARK: - AccessibilityAnnouncer

/// Provides VoiceOver announcements for game phase changes and events.
enum AccessibilityAnnouncer {

    // MARK: - Phase Announcements

    /// Announces a game phase change to VoiceOver users
    /// - Parameter phase: The new game phase
    static func announcePhaseChange(_ phase: GamePhase) {
        let announcement: String

        switch phase {
        case .setup:
            announcement = String(localized: "Setup phase. Add players and configure game settings.", comment: "VoiceOver: Setup phase")
        case .roleReveal:
            announcement = String(localized: "Role reveal phase. Pass the device to each player to see their role.", comment: "VoiceOver: Role reveal phase")
        case .clueRound:
            announcement = String(localized: "Clue round. Each player gives a clue about the secret word.", comment: "VoiceOver: Clue round phase")
        case .discussion:
            announcement = String(localized: "Discussion phase. Discuss who you think is the imposter.", comment: "VoiceOver: Discussion phase")
        case .voting:
            announcement = String(localized: "Voting phase. Each player votes for who they think is the imposter.", comment: "VoiceOver: Voting phase")
        case .reveal:
            announcement = String(localized: "Reveal phase. The imposter will be revealed.", comment: "VoiceOver: Reveal phase")
        case .summary:
            announcement = String(localized: "Game summary. View scores and play again.", comment: "VoiceOver: Summary phase")
        }

        postAnnouncement(announcement)
    }

    // MARK: - Event Announcements

    /// Announces that a player is about to give a clue
    /// - Parameter playerName: The name of the player giving a clue
    static func announceClueGiver(_ playerName: String) {
        let announcement = String(localized: "\(playerName)'s turn to give a clue.", comment: "VoiceOver: Player's turn for clue")
        postAnnouncement(announcement)
    }

    /// Announces that a clue was submitted
    /// - Parameters:
    ///   - playerName: The name of the player who gave the clue
    ///   - clue: The clue text
    static func announceClueSubmitted(playerName: String, clue: String) {
        let announcement = String(localized: "\(playerName) gave the clue: \(clue).", comment: "VoiceOver: Clue submitted")
        postAnnouncement(announcement)
    }

    /// Announces that a player is about to vote
    /// - Parameter playerName: The name of the player voting
    static func announceVoterTurn(_ playerName: String) {
        let announcement = String(localized: "\(playerName)'s turn to vote.", comment: "VoiceOver: Player's turn to vote")
        postAnnouncement(announcement)
    }

    /// Announces the voting result
    /// - Parameters:
    ///   - caught: Whether the imposter was caught
    ///   - imposterName: The name of the imposter
    static func announceVotingResult(caught: Bool, imposterName: String) {
        let announcement: String
        if caught {
            announcement = String(localized: "The imposter, \(imposterName), was caught!", comment: "VoiceOver: Imposter caught")
        } else {
            announcement = String(localized: "The imposter, \(imposterName), escaped!", comment: "VoiceOver: Imposter escaped")
        }
        postAnnouncement(announcement)
    }

    /// Announces a timer update
    /// - Parameter seconds: Remaining seconds
    static func announceTimerWarning(seconds: Int) {
        if seconds == 30 {
            postAnnouncement(String(localized: "30 seconds remaining.", comment: "VoiceOver: Timer warning"))
        } else if seconds == 10 {
            postAnnouncement(String(localized: "10 seconds remaining.", comment: "VoiceOver: Timer warning"))
        }
    }

    /// Announces that the timer has ended
    static func announceTimerEnded() {
        postAnnouncement(String(localized: "Time's up!", comment: "VoiceOver: Timer ended"))
    }

    // MARK: - Private Helpers

    /// Posts an announcement to VoiceOver
    /// - Parameter message: The message to announce
    private static func postAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
