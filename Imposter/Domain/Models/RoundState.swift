//
//  RoundState.swift
//  Imposter
//
//  Per-round mutable state including clues, votes, and results.
//

import Foundation
import UIKit

// MARK: - RoundState

/// Tracks the state of the current round in progress
struct RoundState: Codable, Sendable {
    /// The secret word that informed players know
    var secretWord: String

    /// The word shown to the imposter in hidden mode (different from secretWord)
    /// In classic mode, this is nil and the imposter sees a hint instead
    var imposterWord: String?

    /// The category or theme hint for the imposter
    /// For random pack: the category name (e.g., "Animals")
    /// For custom prompt: the user's theme (e.g., "Ocean")
    let categoryHint: String

    /// AI-generated cryptic hint for the imposter
    /// Generated using Foundation Models based on the secret word
    var imposterHint: String?

    /// The player ID of the imposter
    let imposterID: UUID

    /// All clues given during the round
    var clues: [Clue]

    /// Mapping of voter ID to suspect ID
    var votes: [UUID: UUID]

    /// Current position in clue-giving (tracks whose turn it is)
    var currentClueIndex: Int

    /// Index tracking which player needs to reveal their role next
    var revealIndex: Int

    /// Index of the first player to give a clue (randomly selected, never the imposter)
    let firstPlayerIndex: Int

    /// AI-generated image for the secret word (if using custom prompt)
    /// Note: UIImage is not Codable, so we mark this as transient
    var generatedImage: UIImage? {
        get { _generatedImageStorage }
        set { _generatedImageStorage = newValue }
    }

    // Private storage for non-codable image
    private var _generatedImageStorage: UIImage?

    // MARK: - Nested Types

    /// A clue given by a player during the clue round
    struct Clue: Codable, Identifiable, Sendable, Equatable {
        let id: UUID
        let playerID: UUID
        let text: String
        let timestamp: Date
        /// Which round of clues (0 for first go-around, 1 for second, etc.)
        let roundIndex: Int

        init(id: UUID = UUID(), playerID: UUID, text: String, timestamp: Date = Date(), roundIndex: Int) {
            self.id = id
            self.playerID = playerID
            self.text = text
            self.timestamp = timestamp
            self.roundIndex = roundIndex
        }
    }

    // MARK: - Initialization

    init(
        secretWord: String,
        imposterWord: String? = nil,
        categoryHint: String,
        imposterHint: String? = nil,
        imposterID: UUID,
        clues: [Clue] = [],
        votes: [UUID: UUID] = [:],
        currentClueIndex: Int = 0,
        revealIndex: Int = 0,
        firstPlayerIndex: Int = 0
    ) {
        self.secretWord = secretWord
        self.imposterWord = imposterWord
        self.categoryHint = categoryHint
        self.imposterHint = imposterHint
        self.imposterID = imposterID
        self.clues = clues
        self.votes = votes
        self.currentClueIndex = currentClueIndex
        self.revealIndex = revealIndex
        self.firstPlayerIndex = firstPlayerIndex
        self._generatedImageStorage = nil
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case secretWord, imposterWord, categoryHint, imposterHint, imposterID, clues, votes, currentClueIndex, revealIndex, firstPlayerIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        secretWord = try container.decode(String.self, forKey: .secretWord)
        imposterWord = try container.decodeIfPresent(String.self, forKey: .imposterWord)
        categoryHint = try container.decodeIfPresent(String.self, forKey: .categoryHint) ?? "Unknown"
        imposterHint = try container.decodeIfPresent(String.self, forKey: .imposterHint)
        imposterID = try container.decode(UUID.self, forKey: .imposterID)
        clues = try container.decode([Clue].self, forKey: .clues)
        votes = try container.decode([UUID: UUID].self, forKey: .votes)
        currentClueIndex = try container.decode(Int.self, forKey: .currentClueIndex)
        revealIndex = try container.decode(Int.self, forKey: .revealIndex)
        firstPlayerIndex = try container.decodeIfPresent(Int.self, forKey: .firstPlayerIndex) ?? 0
        _generatedImageStorage = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(secretWord, forKey: .secretWord)
        try container.encodeIfPresent(imposterWord, forKey: .imposterWord)
        try container.encode(categoryHint, forKey: .categoryHint)
        try container.encodeIfPresent(imposterHint, forKey: .imposterHint)
        try container.encode(imposterID, forKey: .imposterID)
        try container.encode(clues, forKey: .clues)
        try container.encode(votes, forKey: .votes)
        try container.encode(currentClueIndex, forKey: .currentClueIndex)
        try container.encode(revealIndex, forKey: .revealIndex)
        try container.encode(firstPlayerIndex, forKey: .firstPlayerIndex)
        // generatedImage is not encoded (transient)
    }
}

// MARK: - Equatable

extension RoundState: Equatable {
    static func == (lhs: RoundState, rhs: RoundState) -> Bool {
        lhs.secretWord == rhs.secretWord &&
        lhs.imposterWord == rhs.imposterWord &&
        lhs.categoryHint == rhs.categoryHint &&
        lhs.imposterHint == rhs.imposterHint &&
        lhs.imposterID == rhs.imposterID &&
        lhs.clues == rhs.clues &&
        lhs.votes == rhs.votes &&
        lhs.currentClueIndex == rhs.currentClueIndex &&
        lhs.revealIndex == rhs.revealIndex &&
        lhs.firstPlayerIndex == rhs.firstPlayerIndex
        // generatedImage excluded (UIImage is not Equatable)
    }
}

// MARK: - VotingResult

/// Result of the voting phase
struct VotingResult: Sendable {
    /// The player who received the most votes (nil if tie or no votes)
    let mostVotedPlayerID: UUID?

    /// The actual imposter's ID
    let imposterID: UUID

    /// Whether the most voted player was the imposter
    let isCorrect: Bool

    /// Vote counts per player
    let voteCounts: [UUID: Int]

    /// Whether the vote was a tie (multiple players with same max votes)
    var isTie: Bool = false

    /// Whether the imposter correctly guessed the word (if allowed)
    var imposterGuessedCorrectly: Bool = false
}

// MARK: - CompletedRound

/// Archive of a completed round for game history
struct CompletedRound: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let roundNumber: Int
    let secretWord: String
    let imposterID: UUID
    let imposterName: String
    let wasImposterCaught: Bool
    let imposterGuessedWord: Bool
    let clues: [RoundState.Clue]
    let votes: [UUID: UUID]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        roundNumber: Int,
        secretWord: String,
        imposterID: UUID,
        imposterName: String,
        wasImposterCaught: Bool,
        imposterGuessedWord: Bool,
        clues: [RoundState.Clue],
        votes: [UUID: UUID],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.secretWord = secretWord
        self.imposterID = imposterID
        self.imposterName = imposterName
        self.wasImposterCaught = wasImposterCaught
        self.imposterGuessedWord = imposterGuessedWord
        self.clues = clues
        self.votes = votes
        self.timestamp = timestamp
    }

    /// Creates a CompletedRound from a RoundState and voting result
    init(from round: RoundState, result: VotingResult, roundNumber: Int, imposterName: String) {
        self.id = UUID()
        self.roundNumber = roundNumber
        self.secretWord = round.secretWord
        self.imposterID = round.imposterID
        self.imposterName = imposterName
        self.wasImposterCaught = result.isCorrect
        self.imposterGuessedWord = result.imposterGuessedCorrectly
        self.clues = round.clues
        self.votes = round.votes
        self.timestamp = Date()
    }
}
