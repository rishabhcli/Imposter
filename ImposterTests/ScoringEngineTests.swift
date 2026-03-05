//
//  ScoringEngineTests.swift
//  ImposterTests
//
//  Tests for the ScoringEngine scoring calculations.
//

import XCTest
@testable import Imposter

@MainActor
final class ScoringEngineTests: XCTestCase {

    // MARK: - Imposter Caught Scenarios

    func testCorrectVotersEarnPoints() {
        let players = TestFixtures.standardPlayers
        let imposterID = TestFixtures.PlayerIDs.alice

        var round = TestFixtures.roundState(imposterID: imposterID)
        // Bob and Carol vote for Alice (correct), Dave votes for Bob (wrong)
        round.votes = [
            TestFixtures.PlayerIDs.bob: imposterID,
            TestFixtures.PlayerIDs.carol: imposterID,
            TestFixtures.PlayerIDs.dave: TestFixtures.PlayerIDs.bob
        ]

        let scores = ScoringEngine.calculate(
            roundState: round,
            players: players,
            settings: .default,
            imposterGuessedCorrectly: false
        )

        // Bob and Carol voted correctly: 1 point each
        XCTAssertEqual(scores.playerScores[TestFixtures.PlayerIDs.bob], 1)
        XCTAssertEqual(scores.playerScores[TestFixtures.PlayerIDs.carol], 1)
        // Dave voted wrong: 0 points
        XCTAssertNil(scores.playerScores[TestFixtures.PlayerIDs.dave])
        // Alice (imposter) was caught: 0 points
        XCTAssertNil(scores.playerScores[imposterID])
    }

    func testImposterGuessedWordBonus() {
        let players = TestFixtures.standardPlayers
        let imposterID = TestFixtures.PlayerIDs.alice

        var round = TestFixtures.roundState(imposterID: imposterID)
        round.votes = [
            TestFixtures.PlayerIDs.bob: imposterID,
            TestFixtures.PlayerIDs.carol: imposterID,
            TestFixtures.PlayerIDs.dave: imposterID
        ]

        let scores = ScoringEngine.calculate(
            roundState: round,
            players: players,
            settings: .default,
            imposterGuessedCorrectly: true
        )

        // Imposter guessed correctly: gets 3 bonus points
        XCTAssertEqual(scores.playerScores[imposterID], GameSettings.default.pointsForImposterGuess)
    }

    // MARK: - Imposter Escaped Scenarios

    func testImposterSurvivalPoints() {
        let players = TestFixtures.standardPlayers
        let imposterID = TestFixtures.PlayerIDs.alice

        var round = TestFixtures.roundState(imposterID: imposterID)
        // Nobody votes for the imposter
        round.votes = [
            TestFixtures.PlayerIDs.bob: TestFixtures.PlayerIDs.carol,
            TestFixtures.PlayerIDs.carol: TestFixtures.PlayerIDs.dave,
            TestFixtures.PlayerIDs.dave: TestFixtures.PlayerIDs.bob
        ]

        let scores = ScoringEngine.calculate(
            roundState: round,
            players: players,
            settings: .default,
            imposterGuessedCorrectly: false
        )

        // Imposter escaped: gets survival points
        XCTAssertEqual(scores.playerScores[imposterID], GameSettings.default.pointsForImposterSurvival)
        // No one else gets points
        XCTAssertNil(scores.playerScores[TestFixtures.PlayerIDs.bob])
    }

    func testTieGivesImposterSurvivalPoints() {
        let players = TestFixtures.standardPlayers
        let imposterID = TestFixtures.PlayerIDs.alice

        var round = TestFixtures.roundState(imposterID: imposterID)
        // Tie: Alice and Bob both get 1 vote
        round.votes = [
            TestFixtures.PlayerIDs.bob: imposterID,
            TestFixtures.PlayerIDs.carol: TestFixtures.PlayerIDs.bob
        ]

        let scores = ScoringEngine.calculate(
            roundState: round,
            players: players,
            settings: .default,
            imposterGuessedCorrectly: false
        )

        // Tie = imposter escapes
        XCTAssertEqual(scores.playerScores[imposterID], GameSettings.default.pointsForImposterSurvival)
    }

    // MARK: - Apply Scores

    func testApplyScoresUpdatesPlayerScores() {
        let players = TestFixtures.standardPlayers
        let roundScores = ScoringEngine.RoundScores(playerScores: [
            TestFixtures.PlayerIDs.alice: 3,
            TestFixtures.PlayerIDs.bob: 1
        ])

        let updated = ScoringEngine.applyScores(roundScores, to: players)

        XCTAssertEqual(updated.first { $0.id == TestFixtures.PlayerIDs.alice }?.score, 3)
        XCTAssertEqual(updated.first { $0.id == TestFixtures.PlayerIDs.bob }?.score, 1)
        XCTAssertEqual(updated.first { $0.id == TestFixtures.PlayerIDs.carol }?.score, 0)
        XCTAssertEqual(updated.first { $0.id == TestFixtures.PlayerIDs.dave }?.score, 0)
    }

    func testApplyScoresAccumulatesOverRounds() {
        var players = TestFixtures.standardPlayers
        // Give Alice some existing score
        players[0].score = 5

        let roundScores = ScoringEngine.RoundScores(playerScores: [
            TestFixtures.PlayerIDs.alice: 2
        ])

        let updated = ScoringEngine.applyScores(roundScores, to: players)

        XCTAssertEqual(updated.first { $0.id == TestFixtures.PlayerIDs.alice }?.score, 7)
    }

    // MARK: - Custom Point Values

    func testCustomPointValues() {
        let players = TestFixtures.standardPlayers
        let imposterID = TestFixtures.PlayerIDs.alice

        var settings = GameSettings.default
        settings.pointsForCorrectVote = 3
        settings.pointsForImposterGuess = 5

        var round = TestFixtures.roundState(imposterID: imposterID)
        round.votes = [
            TestFixtures.PlayerIDs.bob: imposterID,
            TestFixtures.PlayerIDs.carol: imposterID,
            TestFixtures.PlayerIDs.dave: TestFixtures.PlayerIDs.bob
        ]

        let scores = ScoringEngine.calculate(
            roundState: round,
            players: players,
            settings: settings,
            imposterGuessedCorrectly: true
        )

        XCTAssertEqual(scores.playerScores[TestFixtures.PlayerIDs.bob], 3)
        XCTAssertEqual(scores.playerScores[TestFixtures.PlayerIDs.carol], 3)
        XCTAssertEqual(scores.playerScores[imposterID], 5)
    }

    // MARK: - No Votes

    func testNoVotesGivesImposterSurvival() {
        let players = TestFixtures.standardPlayers
        let imposterID = TestFixtures.PlayerIDs.alice

        let round = TestFixtures.roundState(imposterID: imposterID)
        // No votes cast

        let scores = ScoringEngine.calculate(
            roundState: round,
            players: players,
            settings: .default,
            imposterGuessedCorrectly: false
        )

        // With no votes, imposter effectively escaped
        XCTAssertEqual(scores.playerScores[imposterID], GameSettings.default.pointsForImposterSurvival)
    }
}
