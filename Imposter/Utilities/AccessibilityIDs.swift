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
public enum AccessibilityIDs {

    // MARK: - Home Screen

    /// New Game button on home screen
    public static let newGameButton = "newGameButton"

    /// How to Play button on home screen
    public static let howToPlayButton = "howToPlayButton"

    /// Settings button on home screen
    public static let settingsButton = "settingsButton"

    /// Main home title
    public static let homeTitle = "homeTitle"

    // MARK: - Player Setup

    /// Add player button
    public static let addPlayerButton = "addPlayerButton"

    /// Start game button
    public static let startGameButton = "startGameButton"

    /// Player name text field (use the player UUID for uniqueness)
    public static func playerNameField(for playerID: UUID) -> String {
        "playerNameField_\(playerID.uuidString)"
    }

    /// Player color picker (append index for uniqueness)
    public static func playerColorPicker(for playerID: UUID) -> String {
        "playerColorPicker_\(playerID.uuidString)"
    }

    /// Remove player button (append index for uniqueness)
    public static func removePlayerButton(for playerID: UUID) -> String {
        "removePlayerButton_\(playerID.uuidString)"
    }

    /// Back button in category selection
    public static let categoryBackButton = "categoryBackButton"

    /// Continue button in category selection
    public static let categoryContinueButton = "categoryContinueButton"

    /// Custom prompt text field in category selection
    public static let customPromptField = "customPromptField"

    /// Category tile (append category title)
    public static func categoryTile(_ title: String) -> String {
        "categoryTile_\(title)"
    }

    // MARK: - Role Reveal

    /// Reveal role button
    public static let revealRoleButton = "revealRoleButton"

    /// Role card container
    public static let roleCard = "roleCard"

    /// Secret word display
    public static let secretWordDisplay = "secretWordDisplay"

    // MARK: - Clue Round

    /// Clue input text field
    public static let clueInputField = "clueInputField"

    /// Submit clue button
    public static let submitClueButton = "submitClueButton"

    /// Clue history list
    public static let clueHistoryList = "clueHistoryList"

    // MARK: - Discussion

    /// Discussion timer display
    public static let discussionTimer = "discussionTimer"

    /// Start voting button
    public static let startVotingButton = "startVotingButton"

    // MARK: - Voting

    /// Player vote card (append player ID for uniqueness)
    public static func voteCard(for playerID: String) -> String {
        "voteCard_\(playerID)"
    }

    /// Vote confirmation display
    public static let voteConfirmation = "voteConfirmation"

    // MARK: - Reveal

    /// Reveal animation container
    public static let revealAnimation = "revealAnimation"

    /// Imposter word guess input
    public static let imposterGuessField = "imposterGuessField"

    /// Submit guess button
    public static let submitGuessButton = "submitGuessButton"

    /// Continue to summary button
    public static let continueToSummaryButton = "continueToSummaryButton"

    // MARK: - Summary

    /// Scoreboard container
    public static let scoreboard = "scoreboard"

    /// Play again button
    public static let playAgainButton = "playAgainButton"

    /// Main menu button
    public static let mainMenuButton = "mainMenuButton"

    /// Scoreboard row (append player ID for uniqueness)
    public static func scoreboardRow(for playerID: String) -> String {
        "scoreboardRow_\(playerID)"
    }

    // MARK: - Common

    /// Back button
    public static let backButton = "backButton"

    /// Close button (for sheets)
    public static let closeButton = "closeButton"
}
