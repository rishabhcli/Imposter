//
//  AccessibilityIDs.swift
//  Imposter
//
//  Accessibility identifier constants for UI testing.
//

import Foundation

// MARK: - AccessibilityIDs

/// Constants for accessibility identifiers used in UI testing.
/// Apply to views using `.accessibilityIdentifier(AccessibilityIDs.xxx)`
enum AccessibilityIDs {

    // MARK: - Home Screen

    /// New Game button on home screen
    static let newGameButton = "NewGameButton"

    /// How to Play button on home screen
    static let howToPlayButton = "HowToPlayButton"

    /// Settings button on home screen
    static let settingsButton = "SettingsButton"

    // MARK: - Player Setup

    /// Add player button
    static let addPlayerButton = "AddPlayerButton"

    /// Start game button
    static let startGameButton = "StartGameButton"

    /// Player name text field (append index for uniqueness)
    static func playerNameField(at index: Int) -> String {
        "PlayerNameField_\(index)"
    }

    /// Player color picker (append index for uniqueness)
    static func playerColorPicker(at index: Int) -> String {
        "PlayerColorPicker_\(index)"
    }

    /// Remove player button (append index for uniqueness)
    static func removePlayerButton(at index: Int) -> String {
        "RemovePlayerButton_\(index)"
    }

    // MARK: - Role Reveal

    /// Reveal role button
    static let revealRoleButton = "RevealRoleButton"

    /// Role card container
    static let roleCard = "RoleCard"

    /// Secret word display
    static let secretWordDisplay = "SecretWordDisplay"

    // MARK: - Clue Round

    /// Clue input text field
    static let clueInputField = "ClueInputField"

    /// Submit clue button
    static let submitClueButton = "SubmitClueButton"

    /// Clue history list
    static let clueHistoryList = "ClueHistoryList"

    // MARK: - Discussion

    /// Discussion timer display
    static let discussionTimer = "DiscussionTimer"

    /// Start voting button
    static let startVotingButton = "StartVotingButton"

    // MARK: - Voting

    /// Player vote card (append player ID for uniqueness)
    static func voteCard(for playerID: String) -> String {
        "VoteCard_\(playerID)"
    }

    /// Vote confirmation display
    static let voteConfirmation = "VoteConfirmation"

    // MARK: - Reveal

    /// Reveal animation container
    static let revealAnimation = "RevealAnimation"

    /// Imposter word guess input
    static let imposterGuessField = "ImposterGuessField"

    /// Submit guess button
    static let submitGuessButton = "SubmitGuessButton"

    /// Continue to summary button
    static let continueToSummaryButton = "ContinueToSummaryButton"

    // MARK: - Summary

    /// Scoreboard container
    static let scoreboard = "Scoreboard"

    /// Play again button
    static let playAgainButton = "PlayAgainButton"

    /// Main menu button
    static let mainMenuButton = "MainMenuButton"

    /// Scoreboard row (append player ID for uniqueness)
    static func scoreboardRow(for playerID: String) -> String {
        "ScoreboardRow_\(playerID)"
    }

    // MARK: - Common

    /// Back button
    static let backButton = "BackButton"

    /// Close button (for sheets)
    static let closeButton = "CloseButton"
}
