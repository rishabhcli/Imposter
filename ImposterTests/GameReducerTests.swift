//
//  GameReducerTests.swift
//  ImposterTests
//
//  Unit tests for the GameReducer state transitions.
//

import Foundation
import Testing
@testable import Imposter

@Suite("Game Reducer Tests")
@MainActor
struct GameReducerTests {

    // MARK: - Player Management Tests

    @Test func addPlayerInSetupPhase() {
        let state = GameState()
        let newState = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))

        #expect(newState.players.count == 1)
        #expect(newState.players[0].name == "Alice")
        #expect(newState.players[0].color == .crimson)
    }

    @Test func addMultiplePlayers() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Charlie", color: .emerald))

        #expect(state.players.count == 3)
    }

    @Test func addPlayerMaxLimit() {
        var state = GameState()

        // Add 10 players (maximum)
        for i in 0..<10 {
            state = GameReducer.reduce(state: state, action: .addPlayer(name: "Player \(i)", color: PlayerColor.allCases[i % 8]))
        }

        #expect(state.players.count == 10)

        // Try to add 11th player - should be rejected
        let stateAfter = GameReducer.reduce(state: state, action: .addPlayer(name: "Player 11", color: .crimson))
        #expect(stateAfter.players.count == 10)
    }

    @Test func removePlayer() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))

        let aliceID = state.players[0].id
        state = GameReducer.reduce(state: state, action: .removePlayer(id: aliceID))

        #expect(state.players.count == 1)
        #expect(state.players[0].name == "Bob")
    }

    @Test func updatePlayer() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))

        let playerID = state.players[0].id
        state = GameReducer.reduce(state: state, action: .updatePlayer(id: playerID, name: "Alicia", color: .azure))

        #expect(state.players[0].name == "Alicia")
        #expect(state.players[0].color == .azure)
    }

    // MARK: - Game Start Tests

    @Test func startGameRequiresThreePlayers() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))

        // Try to start with only 2 players - should fail
        let stateAfter = GameReducer.reduce(state: state, action: .startGame)
        #expect(stateAfter.currentPhase == .setup)
        #expect(stateAfter.roundState == nil)
    }

    @Test func startGameInitializesRound() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Charlie", color: .emerald))

        state = GameReducer.reduce(state: state, action: .startGame)

        #expect(state.currentPhase == .roleReveal)
        #expect(state.roundState != nil)
        #expect(state.roundState?.secretWord.isEmpty == false)
        #expect(state.roundNumber == 1)
    }

    @Test func startGameSelectsImposter() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Charlie", color: .emerald))

        state = GameReducer.reduce(state: state, action: .startGame)

        // Imposter should be one of the players
        let imposterID = state.roundState?.imposterID
        let playerIDs = state.players.map { $0.id }
        #expect(playerIDs.contains(imposterID!))
    }

    // MARK: - Clue Round Tests

    @Test func submitClueAdvancesIndex() {
        var state = createGameInClueRound()
        let initialIndex = state.roundState?.currentClueIndex ?? 0

        let playerID = state.players[0].id
        state = GameReducer.reduce(state: state, action: .submitClue(playerID: playerID, text: "test clue"))

        #expect(state.roundState?.currentClueIndex == initialIndex + 1)
        #expect(state.roundState?.clues.count == 1)
    }

    @Test func submitClueRejectsEmpty() {
        var state = createGameInClueRound()
        let initialClueCount = state.roundState?.clues.count ?? 0

        let playerID = state.players[0].id
        state = GameReducer.reduce(state: state, action: .submitClue(playerID: playerID, text: "   "))

        #expect(state.roundState?.clues.count == initialClueCount)
    }

    @Test func submitClueTrimsWhitespace() {
        var state = createGameInClueRound()

        let playerID = state.players[0].id
        state = GameReducer.reduce(state: state, action: .submitClue(playerID: playerID, text: "  hello  "))

        #expect(state.roundState?.clues.first?.text == "hello")
    }

    // MARK: - Voting Tests

    @Test func castVoteRecordsCorrectly() {
        var state = createGameInVotingPhase()

        let voterID = state.players[0].id
        let suspectID = state.players[1].id
        state = GameReducer.reduce(state: state, action: .castVote(voterID: voterID, suspectID: suspectID))

        #expect(state.roundState?.votes[voterID] == suspectID)
    }

    @Test func castVoteRejectsInvalidVoter() {
        var state = createGameInVotingPhase()
        let initialVoteCount = state.roundState?.votes.count ?? 0

        // Try to vote with invalid voter ID
        let invalidID = UUID()
        let suspectID = state.players[1].id
        state = GameReducer.reduce(state: state, action: .castVote(voterID: invalidID, suspectID: suspectID))

        #expect(state.roundState?.votes.count == initialVoteCount)
    }

    @Test func allVotesTransitionsToReveal() {
        var state = createGameInVotingPhase()

        // All players vote
        for (index, player) in state.players.enumerated() {
            let suspectIndex = (index + 1) % state.players.count
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: state.players[suspectIndex].id))
        }

        #expect(state.currentPhase == .reveal)
    }

    // MARK: - Scoring Tests

    @Test func scoringForCorrectVote() {
        var state = createGameInVotingPhase()
        let imposterID = state.roundState!.imposterID

        // All players vote for imposter
        for player in state.players {
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: imposterID))
        }

        // Complete the round
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))

        // Non-imposters should have points
        let nonImposters = state.players.filter { $0.id != imposterID }
        for player in nonImposters {
            #expect(player.score > 0)
        }
    }

    @Test func scoringForImposterSurvival() {
        var state = createGameInVotingPhase()
        let imposterID = state.roundState!.imposterID
        let nonImposterID = state.players.first { $0.id != imposterID }!.id

        // All players vote for non-imposter
        for player in state.players {
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: nonImposterID))
        }

        // Complete the round
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))

        // Imposter should have points for survival
        let imposter = state.players.first { $0.id == imposterID }!
        #expect(imposter.score > 0)
    }

    // MARK: - Reset Tests

    @Test func startNewRoundResetsState() {
        var state = createGameInSummaryPhase()
        let previousRoundNumber = state.roundNumber

        state = GameReducer.reduce(state: state, action: .startNewRound)

        #expect(state.currentPhase == .roleReveal)
        #expect(state.roundNumber == previousRoundNumber + 1)
        #expect(state.roundState?.clues.isEmpty == true)
        #expect(state.roundState?.votes.isEmpty == true)
    }

    @Test func returnToHomeClearsPlayers() {
        var state = createGameInSummaryPhase()

        state = GameReducer.reduce(state: state, action: .returnToHome)

        #expect(state.currentPhase == .setup)
        #expect(state.players.isEmpty)
        #expect(state.roundState == nil)
    }

    // MARK: - Helper Methods

    private func createGameInClueRound() -> GameState {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Charlie", color: .emerald))
        state = GameReducer.reduce(state: state, action: .startGame)
        state = GameReducer.reduce(state: state, action: .completeRoleReveal)
        return state
    }

    private func createGameInVotingPhase() -> GameState {
        var state = createGameInClueRound()

        // Submit clues for all players in all rounds
        let totalClues = state.players.count * state.settings.numberOfClueRounds
        for i in 0..<totalClues {
            let playerIndex = i % state.players.count
            state = GameReducer.reduce(state: state, action: .submitClue(playerID: state.players[playerIndex].id, text: "clue \(i)"))
        }

        // Skip discussion if enabled
        if state.currentPhase == .discussion {
            state = GameReducer.reduce(state: state, action: .startVoting)
        }

        return state
    }

    private func createGameInSummaryPhase() -> GameState {
        var state = createGameInVotingPhase()

        // All players vote
        let imposterID = state.roundState!.imposterID
        for player in state.players {
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: imposterID))
        }

        // Complete round
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))

        return state
    }
}
