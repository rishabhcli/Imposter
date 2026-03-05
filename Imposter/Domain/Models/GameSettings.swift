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

    /// Game mode determines how the imposter experiences the game
    enum GameMode: String, Codable, CaseIterable, Sendable {
        /// Classic mode: Imposter knows they're the imposter and gets a hint
        case classic
        /// Hidden mode: Imposter gets a different word and doesn't know they're the imposter
        case hidden

        var displayName: String {
            switch self {
            case .classic: return "Classic"
            case .hidden: return "Hidden Imposter"
            }
        }

        var description: String {
            switch self {
            case .classic:
                return "The Imposter knows their role and receives a hint about the category."
            case .hidden:
                return "The Imposter receives a different word and doesn't know they're the Imposter."
            }
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

    // MARK: - Game Mode

    /// The game mode (classic or hidden imposter)
    var gameMode: GameMode

    // MARK: - Scoring

    /// Points awarded to each non-imposter for correct vote
    var pointsForCorrectVote: Int

    /// Points awarded to imposter for surviving undetected
    var pointsForImposterSurvival: Int

    /// Points awarded to imposter for correctly guessing the word
    var pointsForImposterGuess: Int

    // MARK: - Multi-Round

    /// Number of rounds to play (0 = unlimited)
    var numberOfRounds: Int

    // MARK: - Initialization

    init(
        wordSource: WordSource,
        selectedCategories: [String]?,
        wordPackDifficulty: Difficulty,
        customWordPrompt: String?,
        numberOfClueRounds: Int,
        clueTimerEnabled: Bool,
        clueTimerMinutes: Int,
        discussionTimerEnabled: Bool,
        discussionSeconds: Int,
        votingTimerEnabled: Bool,
        votingSeconds: Int,
        allowImposterWordGuess: Bool,
        imposterHintEnabled: Bool,
        gameMode: GameMode,
        pointsForCorrectVote: Int,
        pointsForImposterSurvival: Int,
        pointsForImposterGuess: Int,
        numberOfRounds: Int = 0
    ) {
        self.wordSource = wordSource
        self.selectedCategories = selectedCategories
        self.wordPackDifficulty = wordPackDifficulty
        self.customWordPrompt = customWordPrompt
        self.numberOfClueRounds = numberOfClueRounds
        self.clueTimerEnabled = clueTimerEnabled
        self.clueTimerMinutes = clueTimerMinutes
        self.discussionTimerEnabled = discussionTimerEnabled
        self.discussionSeconds = discussionSeconds
        self.votingTimerEnabled = votingTimerEnabled
        self.votingSeconds = votingSeconds
        self.allowImposterWordGuess = allowImposterWordGuess
        self.imposterHintEnabled = imposterHintEnabled
        self.gameMode = gameMode
        self.pointsForCorrectVote = pointsForCorrectVote
        self.pointsForImposterSurvival = pointsForImposterSurvival
        self.pointsForImposterGuess = pointsForImposterGuess
        self.numberOfRounds = numberOfRounds
    }

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
        gameMode: .classic,
        pointsForCorrectVote: 1,
        pointsForImposterSurvival: 2,
        pointsForImposterGuess: 3,
        numberOfRounds: 0
    )

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case wordSource, selectedCategories, wordPackDifficulty, customWordPrompt
        case numberOfClueRounds, clueTimerEnabled, clueTimerMinutes
        case discussionTimerEnabled, discussionSeconds
        case votingTimerEnabled, votingSeconds
        case allowImposterWordGuess, imposterHintEnabled, gameMode
        case pointsForCorrectVote, pointsForImposterSurvival, pointsForImposterGuess
        case numberOfRounds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wordSource = try container.decode(WordSource.self, forKey: .wordSource)
        selectedCategories = try container.decodeIfPresent([String].self, forKey: .selectedCategories)
        wordPackDifficulty = try container.decode(Difficulty.self, forKey: .wordPackDifficulty)
        customWordPrompt = try container.decodeIfPresent(String.self, forKey: .customWordPrompt)
        numberOfClueRounds = try container.decode(Int.self, forKey: .numberOfClueRounds)
        clueTimerEnabled = try container.decode(Bool.self, forKey: .clueTimerEnabled)
        clueTimerMinutes = try container.decode(Int.self, forKey: .clueTimerMinutes)
        discussionTimerEnabled = try container.decode(Bool.self, forKey: .discussionTimerEnabled)
        discussionSeconds = try container.decode(Int.self, forKey: .discussionSeconds)
        votingTimerEnabled = try container.decode(Bool.self, forKey: .votingTimerEnabled)
        votingSeconds = try container.decode(Int.self, forKey: .votingSeconds)
        allowImposterWordGuess = try container.decode(Bool.self, forKey: .allowImposterWordGuess)
        imposterHintEnabled = try container.decode(Bool.self, forKey: .imposterHintEnabled)
        gameMode = try container.decode(GameMode.self, forKey: .gameMode)
        pointsForCorrectVote = try container.decode(Int.self, forKey: .pointsForCorrectVote)
        pointsForImposterSurvival = try container.decode(Int.self, forKey: .pointsForImposterSurvival)
        pointsForImposterGuess = try container.decode(Int.self, forKey: .pointsForImposterGuess)
        numberOfRounds = try container.decodeIfPresent(Int.self, forKey: .numberOfRounds) ?? 0
    }

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
