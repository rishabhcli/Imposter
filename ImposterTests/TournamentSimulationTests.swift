//
//  TournamentSimulationTests.swift
//  ImposterTests
//
//  Long-form reducer simulations for multi-round stability.
//

import XCTest
@testable import Imposter

@MainActor
final class TournamentSimulationTests: XCTestCase {

    func testMaximumPlayerTournamentMaintainsInvariantsAcrossManyRounds() throws {
        let players = TestFixtures.maximumPlayers
        var settings = GameSettings.default
        settings.numberOfClueRounds = 2

        let totalRounds = 100
        let startedAt = Date()
        var state = GameState(players: players, settings: settings)
        var previousScoreTotal = 0
        var observedImposterIDs: Set<UUID> = []

        for roundNumber in 1...totalRounds {
            let preparedRound = try makePreparedRound(
                number: roundNumber,
                players: players
            )
            let expectedImposterID = preparedRound.imposterID
            let imposterGuessedCorrectly = roundNumber.isMultiple(of: 5)
            observedImposterIDs.insert(expectedImposterID)

            if roundNumber == 1 {
                state = GameReducer.reduce(
                    state: state,
                    action: .startGameWithPreparedRound(preparedRound)
                )
            } else {
                XCTAssertEqual(state.currentPhase, .summary)
                XCTAssertNil(state.roundState)
                state = GameReducer.reduce(
                    state: state,
                    action: .startNewRoundWithPreparedRound(preparedRound)
                )
            }

            assertActiveRound(
                state,
                phase: .roleReveal,
                roundNumber: roundNumber,
                expectedImposterID: expectedImposterID,
                expectedHistoryCount: roundNumber - 1
            )

            for player in players {
                let revealIndexBefore = try XCTUnwrap(state.roundState?.revealIndex)
                state = GameReducer.reduce(
                    state: state,
                    action: .revealRoleToPlayer(id: player.id)
                )
                XCTAssertEqual(state.roundState?.revealIndex, revealIndexBefore + 1)
            }

            state = GameReducer.reduce(state: state, action: .completeRoleReveal)
            assertActiveRound(
                state,
                phase: .clueRound,
                roundNumber: roundNumber,
                expectedImposterID: expectedImposterID,
                expectedHistoryCount: roundNumber - 1
            )

            let totalClues = players.count * settings.numberOfClueRounds
            for clueTurn in 0..<totalClues {
                let clueGiver = try XCTUnwrap(state.currentClueGiver)
                state = GameReducer.reduce(
                    state: state,
                    action: .submitClue(
                        playerID: clueGiver.id,
                        text: "round \(roundNumber) clue \(clueTurn + 1)"
                    )
                )

                let clues = try XCTUnwrap(state.roundState?.clues)
                XCTAssertEqual(clues.count, clueTurn + 1)
                XCTAssertEqual(clues.last?.playerID, clueGiver.id)
                XCTAssertEqual(clues.last?.roundIndex, clueTurn / players.count)

                let expectedPhase: GamePhase = clueTurn == totalClues - 1 ? .discussion : .clueRound
                XCTAssertEqual(state.currentPhase, expectedPhase)
            }

            XCTAssertEqual(state.roundState?.currentClueIndex, totalClues)
            state = GameReducer.reduce(state: state, action: .startVoting)
            assertActiveRound(
                state,
                phase: .voting,
                roundNumber: roundNumber,
                expectedImposterID: expectedImposterID,
                expectedHistoryCount: roundNumber - 1
            )

            state = GameReducer.reduce(state: state, action: .completeVoting)
            XCTAssertEqual(state.currentPhase, .voting, "Voting should not complete before all players vote.")

            for player in players {
                let votesBefore = try XCTUnwrap(state.roundState?.votes)
                state = GameReducer.reduce(
                    state: state,
                    action: .castVote(voterID: player.id, suspectID: player.id)
                )
                XCTAssertEqual(state.roundState?.votes, votesBefore, "Self-votes must be ignored.")
            }

            for (index, voter) in players.enumerated() {
                let suspectID = suspectID(
                    for: voter,
                    imposterID: expectedImposterID,
                    players: players
                )

                state = GameReducer.reduce(
                    state: state,
                    action: .castVote(voterID: voter.id, suspectID: suspectID)
                )

                XCTAssertEqual(state.roundState?.votes.count, index + 1)
                XCTAssertNotEqual(voter.id, suspectID)

                let expectedPhase: GamePhase = index == players.count - 1 ? .reveal : .voting
                XCTAssertEqual(state.currentPhase, expectedPhase)
            }

            let completedRoundState = try XCTUnwrap(state.roundState)
            XCTAssertEqual(completedRoundState.votes.count, players.count)
            XCTAssertTrue(completedRoundState.votes.allSatisfy { $0.key != $0.value })

            state = GameReducer.reduce(
                state: state,
                action: .completeRound(imposterGuessedCorrectly: imposterGuessedCorrectly)
            )

            XCTAssertEqual(state.currentPhase, .summary)
            XCTAssertNil(state.roundState)
            XCTAssertEqual(state.roundNumber, roundNumber)
            XCTAssertEqual(state.players.count, players.count)
            XCTAssertEqual(Set(state.players.map(\.id)), Set(players.map(\.id)))
            XCTAssertTrue(state.players.allSatisfy { $0.score >= 0 })

            let scoreTotal = state.players.reduce(0) { $0 + $1.score }
            XCTAssertGreaterThan(scoreTotal, previousScoreTotal)
            previousScoreTotal = scoreTotal

            let history = state.gameHistory
            XCTAssertEqual(history.count, roundNumber)
            let completedRound = try XCTUnwrap(history.last)
            XCTAssertEqual(completedRound.roundNumber, roundNumber)
            XCTAssertEqual(completedRound.secretWord, preparedRound.secretWord)
            XCTAssertEqual(completedRound.imposterID, expectedImposterID)
            XCTAssertEqual(completedRound.clues.count, totalClues)
            XCTAssertEqual(completedRound.votes.count, players.count)
            XCTAssertTrue(completedRound.wasImposterCaught)
            XCTAssertEqual(completedRound.imposterGuessedWord, imposterGuessedCorrectly)
        }

        XCTAssertEqual(state.currentPhase, .summary)
        XCTAssertNil(state.roundState)
        XCTAssertEqual(state.roundNumber, totalRounds)
        XCTAssertEqual(state.gameHistory.count, totalRounds)
        XCTAssertEqual(observedImposterIDs, Set(players.map(\.id)))

        let elapsed = Date().timeIntervalSince(startedAt)
        XCTContext.runActivity(named: "Tournament stability summary") { activity in
            let summary = """
            Simulated \(totalRounds) rounds with \(players.count) players.
            Processed \(totalRounds * players.count * settings.numberOfClueRounds) clues and \(totalRounds * players.count) valid votes.
            Final score total: \(previousScoreTotal).
            Elapsed wall time: \(String(format: "%.3f", elapsed)) seconds.
            """
            activity.add(XCTAttachment(string: summary))
        }
    }

    private func makePreparedRound(
        number: Int,
        players: [Player]
    ) throws -> RoundState {
        let imposterIndex = (number - 1) % players.count
        let imposter = players[imposterIndex]
        let firstPlayerIndex = try XCTUnwrap(
            players.firstIndex { $0.id != imposter.id }
        )

        return RoundState(
            secretWord: "Stability Word \(number)",
            categoryHint: "Stability Lab",
            imposterID: imposter.id,
            firstPlayerIndex: firstPlayerIndex
        )
    }

    private func suspectID(
        for voter: Player,
        imposterID: UUID,
        players: [Player]
    ) -> UUID {
        if voter.id != imposterID {
            return imposterID
        }

        return players.first { $0.id != voter.id }?.id ?? imposterID
    }

    private func assertActiveRound(
        _ state: GameState,
        phase: GamePhase,
        roundNumber: Int,
        expectedImposterID: UUID,
        expectedHistoryCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(state.currentPhase, phase, file: file, line: line)
        XCTAssertEqual(state.roundNumber, roundNumber, file: file, line: line)
        XCTAssertEqual(state.gameHistory.count, expectedHistoryCount, file: file, line: line)
        XCTAssertEqual(state.players.count, TestFixtures.maximumPlayers.count, file: file, line: line)
        XCTAssertNotNil(state.roundState, file: file, line: line)
        XCTAssertEqual(state.roundState?.imposterID, expectedImposterID, file: file, line: line)
        XCTAssertNotNil(state.imposter, file: file, line: line)
    }
}
