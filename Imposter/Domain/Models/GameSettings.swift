//
//  GameSettings.swift
//  Imposter
//
//  Configurable game rules and options.
//

import Foundation

// MARK: - GameSettings

/// Configurable parameters for a game session
struct GameSettings: Codable, Sendable, Equatable {

    // MARK: - Nested Types

    /// How difficulty affects word selection
    enum Difficulty: String, Codable, CaseIterable, Sendable {
        case easy
        case medium
        case hard
        case mixed

        var displayName: String {
            rawValue.capitalized
        }
    }

    /// Source of the secret word
    enum WordSource: String, Codable, Sendable {
        /// Random selection from word packs
        case randomPack
        /// User-provided custom prompt (AI generates a related word)
        case customPrompt

        var displayName: String {
            switch self {
            case .randomPack: return "Random Word"
            case .customPrompt: return "Custom Prompt"
            }
        }
    }

    // MARK: - Word Selection

    /// How the secret word is determined
    var wordSource: WordSource

    /// Categories to draw words from (nil = all categories)
    var selectedCategories: [String]?

    /// Difficulty level for word pack selection
    var wordPackDifficulty: Difficulty

    /// User-provided prompt when wordSource == .customPrompt
    var customWordPrompt: String?

    // MARK: - Round Configuration

    /// Number of clue-giving rounds (each player gives this many clues)
    var numberOfClueRounds: Int

    /// Whether clue round has a timer
    var clueTimerEnabled: Bool

    /// Clue round time limit in minutes (1-5, or 0 for no timer)
    var clueTimerMinutes: Int

    /// Whether discussion phase has a timer
    var discussionTimerEnabled: Bool

    /// Discussion time limit in seconds
    var discussionSeconds: Int

    /// Whether voting phase has a timer
    var votingTimerEnabled: Bool

    /// Voting time limit in seconds
    var votingSeconds: Int

    /// Whether imposter can guess the word after being caught
    var allowImposterWordGuess: Bool

    /// Whether to generate AI hints for the imposter
    /// When enabled, imposter gets a cryptic hint instead of just the category
    var imposterHintEnabled: Bool

    // MARK: - Scoring

    /// Points awarded to each non-imposter for correct vote
    var pointsForCorrectVote: Int

    /// Points awarded to imposter for surviving undetected
    var pointsForImposterSurvival: Int

    /// Points awarded to imposter for correctly guessing the word
    var pointsForImposterGuess: Int

    // MARK: - Default Settings

    static let `default` = GameSettings(
        wordSource: .randomPack,
        selectedCategories: nil,
        wordPackDifficulty: .medium,
        customWordPrompt: nil,
        numberOfClueRounds: 2,
        clueTimerEnabled: false,
        clueTimerMinutes: 0,
        discussionTimerEnabled: false,
        discussionSeconds: 60,
        votingTimerEnabled: false,
        votingSeconds: 30,
        allowImposterWordGuess: true,
        imposterHintEnabled: true,
        pointsForCorrectVote: 1,
        pointsForImposterSurvival: 2,
        pointsForImposterGuess: 3
    )

    /// Available timer durations in minutes
    static let timerOptions = [0, 1, 2, 3, 4, 5]

    /// Display string for timer option
    static func timerDisplayText(minutes: Int) -> String {
        if minutes == 0 {
            return "No Timer"
        }
        return "\(minutes) min"
    }
}

// MARK: - Available Categories

extension GameSettings {
    /// All available word categories
    static let availableCategories = [
        "Animals",
        "Technology",
        "Objects",
        "People",
        "Movies"
    ]
}
