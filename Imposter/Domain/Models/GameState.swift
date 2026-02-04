//
//  GameState.swift
//  Imposter
//
//  Central observable state container for the game.
//

import Foundation
import Observation

// MARK: - GameState

/// Central state container for the entire game.
/// Uses @Observable for fine-grained SwiftUI updates.
@Observable
final class GameState: @unchecked Sendable {
    /// All players in the current game
    var players: [Player]

    /// Game configuration settings
    var settings: GameSettings

    /// Current phase of the game
    var currentPhase: GamePhase

    /// State for the current round (nil when not in a round)
    var roundState: RoundState?

    /// Current round number (1-indexed)
    var roundNumber: Int

    /// History of completed rounds
    var gameHistory: [CompletedRound]

    // MARK: - Initialization

    init(
        players: [Player] = [],
        settings: GameSettings = .default,
        currentPhase: GamePhase = .setup,
        roundState: RoundState? = nil,
        roundNumber: Int = 0,
        gameHistory: [CompletedRound] = []
    ) {
        self.players = players
        self.settings = settings
        self.currentPhase = currentPhase
        self.roundState = roundState
        self.roundNumber = roundNumber
        self.gameHistory = gameHistory
    }

    // MARK: - Derived Properties

    /// The current imposter player (if in a round)
    var imposter: Player? {
        guard let imposterID = roundState?.imposterID else { return nil }
        return players.first { $0.id == imposterID }
    }



    /// Whether we have enough players to start (3-10)
    var canStartGame: Bool {
        players.count >= 3 && players.count <= 10
    }

    /// Total number of clues expected for the current round
    var totalCluesExpected: Int {
        players.count * settings.numberOfClueRounds
    }

    /// Whether all clues have been given for the current round
    var allCluesGiven: Bool {
        guard let round = roundState else { return false }
        return round.currentClueIndex >= totalCluesExpected
    }

    /// Whether all players have voted
    var allVotesCast: Bool {
        guard let round = roundState else { return false }
        return round.votes.count >= players.count
    }

    /// The player whose turn it is to give a clue
    var currentClueGiver: Player? {
        guard let round = roundState, currentPhase == .clueRound else { return nil }
        // Offset by firstPlayerIndex so the randomly selected first player starts
        let playerIndex = (round.firstPlayerIndex + round.currentClueIndex) % players.count
        guard playerIndex < players.count else { return nil }
        return players[playerIndex]
    }

    /// The first player to give a clue this round
    var firstClueGiver: Player? {
        guard let round = roundState else { return nil }
        guard round.firstPlayerIndex < players.count else { return nil }
        return players[round.firstPlayerIndex]
    }

    // MARK: - Copy

    /// Creates a deep copy of the game state
    /// Note: Players array is copied by value since Player is a struct
    func copy() -> GameState {
        GameState(
            players: players.map { $0 },  // Explicit copy of player structs
            settings: settings,
            currentPhase: currentPhase,
            roundState: roundState?.copy(),  // Deep copy of round state
            roundNumber: roundNumber,
            gameHistory: gameHistory
        )
    }
}

// MARK: - Equatable for Testing

extension GameState: Equatable {
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        lhs.players == rhs.players &&
        lhs.settings == rhs.settings &&
        lhs.currentPhase == rhs.currentPhase &&
        lhs.roundNumber == rhs.roundNumber
    }
}
