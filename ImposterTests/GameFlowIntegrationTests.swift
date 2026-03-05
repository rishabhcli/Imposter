//
//  GameFlowIntegrationTests.swift
//  ImposterTests
//
//  Integration tests for the full game flow through the reducer.
//

import XCTest
@testable import Imposter

@MainActor
final class GameFlowIntegrationTests: XCTestCase {

    // MARK: - Full Game Loop

    func testCompleteGameLoop() {
        var state = GameState()

        // Setup: Add 3 players
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Carol", color: .emerald))
        XCTAssertEqual(state.players.count, 3)
        XCTAssertEqual(state.currentPhase, .setup)

        // Start game
        state = GameReducer.reduce(state: state, action: .startGame)
        XCTAssertEqual(state.currentPhase, .roleReveal)
        XCTAssertNotNil(state.roundState)
        XCTAssertEqual(state.roundNumber, 1)

        // Complete role reveal
        state = GameReducer.reduce(state: state, action: .completeRoleReveal)
        XCTAssertEqual(state.currentPhase, .clueRound)

        // Complete voting (skip clue round)
        state = GameReducer.reduce(state: state, action: .completeVoting)
        XCTAssertEqual(state.currentPhase, .reveal)

        // Complete round
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))
        XCTAssertEqual(state.currentPhase, .summary)
        XCTAssertNil(state.roundState)
        XCTAssertEqual(state.gameHistory.count, 1)
    }

    // MARK: - Multi-Round Flow

    func testMultiRoundScoresAccumulate() {
        var state = GameState()

        // Setup
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Carol", color: .emerald))

        // Round 1
        state = GameReducer.reduce(state: state, action: .startGame)
        let imposterID1 = state.roundState!.imposterID
        state = GameReducer.reduce(state: state, action: .completeRoleReveal)
        state = GameReducer.reduce(state: state, action: .completeVoting)

        // Vote for imposter so someone gets points
        for player in state.players where player.id != imposterID1 {
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: imposterID1))
        }

        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))
        XCTAssertEqual(state.currentPhase, .summary)
        XCTAssertEqual(state.roundNumber, 1)

        let totalScoreAfterRound1 = state.players.reduce(0) { $0 + $1.score }
        XCTAssertGreaterThan(totalScoreAfterRound1, 0)

        // Round 2
        state = GameReducer.reduce(state: state, action: .startNewRound)
        XCTAssertEqual(state.currentPhase, .roleReveal)
        XCTAssertEqual(state.roundNumber, 2)
        XCTAssertNotNil(state.roundState)
    }

    // MARK: - Return to Home

    func testReturnToHomeResetsState() {
        var state = GameState()

        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Carol", color: .emerald))

        // Play a round
        state = GameReducer.reduce(state: state, action: .startGame)
        state = GameReducer.reduce(state: state, action: .completeRoleReveal)
        state = GameReducer.reduce(state: state, action: .completeVoting)
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))

        // Return to home
        state = GameReducer.reduce(state: state, action: .returnToHome)
        XCTAssertEqual(state.currentPhase, .setup)
        XCTAssertTrue(state.players.isEmpty)
        XCTAssertEqual(state.roundNumber, 0)
        XCTAssertTrue(state.gameHistory.isEmpty)
    }

    // MARK: - Input Validation

    func testEmptyPlayerNameRejected() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "", color: .crimson))
        XCTAssertTrue(state.players.isEmpty)
    }

    func testWhitespaceOnlyNameRejected() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "   ", color: .crimson))
        XCTAssertTrue(state.players.isEmpty)
    }

    func testPlayerNameTrimmed() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "  Alice  ", color: .crimson))
        XCTAssertEqual(state.players.first?.name, "Alice")
    }

    // MARK: - Voting Tie

    func testVotingTieHandledCorrectly() {
        var round = TestFixtures.roundState(imposterID: TestFixtures.PlayerIDs.alice)

        // Create a tie: Alice and Bob each get 1 vote
        round.votes = [
            TestFixtures.PlayerIDs.bob: TestFixtures.PlayerIDs.alice,
            TestFixtures.PlayerIDs.carol: TestFixtures.PlayerIDs.bob
        ]

        let result = GameReducer.calculateVotingResult(roundState: round)
        XCTAssertTrue(result.isTie)
        XCTAssertNil(result.mostVotedPlayerID)
        XCTAssertFalse(result.isCorrect)
    }

    // MARK: - Phase Transition Guards

    func testCannotStartGameWithTwoPlayers() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .startGame)
        XCTAssertEqual(state.currentPhase, .setup)
    }

    func testCannotCompleteRoundFromWrongPhase() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Carol", color: .emerald))
        state = GameReducer.reduce(state: state, action: .startGame)

        // Try to complete round from roleReveal - should be ignored
        let beforePhase = state.currentPhase
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))
        XCTAssertEqual(state.currentPhase, beforePhase)
    }

    // MARK: - Scoring Through Complete Round

    func testCompleteRoundAppliesScores() {
        var state = GameState()
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Alice", color: .crimson))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Bob", color: .azure))
        state = GameReducer.reduce(state: state, action: .addPlayer(name: "Carol", color: .emerald))

        state = GameReducer.reduce(state: state, action: .startGame)
        let imposterID = state.roundState!.imposterID

        state = GameReducer.reduce(state: state, action: .completeRoleReveal)

        // Cast votes before completing voting (must be in voting phase)
        // completeVoting transitions from clueRound -> reveal, so we need to cast votes
        // while in voting. Use completeClueRounds to get to voting first.
        state = GameReducer.reduce(state: state, action: .completeClueRounds)

        // Now in voting phase - everyone votes for the imposter
        // The imposter also votes (for someone else) so all players have voted
        for player in state.players {
            let suspect = player.id == imposterID
                ? state.players.first { $0.id != imposterID }!.id
                : imposterID
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: suspect))
        }

        // All votes cast auto-transitions to reveal
        XCTAssertEqual(state.currentPhase, .reveal)

        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))

        // Non-imposter voters should have points
        let voterScores = state.players.filter { $0.id != imposterID }.map { $0.score }
        XCTAssertTrue(voterScores.allSatisfy { $0 > 0 })
    }
}
