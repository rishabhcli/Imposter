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
        guard let imposterID = state.roundState?.imposterID else {
            Issue.record("Round state or imposter ID is nil")
            return
        }
        let playerIDs = state.players.map { $0.id }
        #expect(playerIDs.contains(imposterID))
    }

    @Test func createNewRoundAvoidsProvidedRecentWords() throws {
        let animalPack = try #require(
            WordSelector.loadWordPacks().first { $0.category == "Animals" }
        )
        let mediumWords = animalPack.words
            .filter { $0.difficulty == "medium" }
            .map(\.word)
        let expectedWord = try #require(mediumWords.last)
        let avoidedWords = Set(mediumWords.dropLast())

        var settings = GameSettings.default
        settings.selectedCategories = ["Animals"]
        settings.wordPackDifficulty = .medium

        let round = GameReducer.createNewRound(
            players: TestFixtures.minimumPlayers,
            settings: settings,
            avoiding: avoidedWords
        )

        #expect(round.secretWord == expectedWord)
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

    @Test func finalSubmittedClueTransitionsToDiscussion() {
        var state = createGameInClueRound()
        let totalClues = state.players.count * state.settings.numberOfClueRounds

        for i in 0..<totalClues {
            let playerIndex = i % state.players.count
            state = GameReducer.reduce(
                state: state,
                action: .submitClue(playerID: state.players[playerIndex].id, text: "clue \(i)")
            )
        }

        #expect(state.currentPhase == .discussion)
    }

    @Test func completeClueRoundsTransitionsToDiscussion() {
        var state = createGameInClueRound()

        state = GameReducer.reduce(state: state, action: .completeClueRounds)

        #expect(state.currentPhase == .discussion)
    }

    @Test func startVotingIsIgnoredDuringClueRound() {
        let state = createGameInClueRound()

        let newState = GameReducer.reduce(state: state, action: .startVoting)

        #expect(newState.currentPhase == .clueRound)
    }

    @Test func completeVotingIsIgnoredDuringClueRound() {
        let state = createGameInClueRound()

        let newState = GameReducer.reduce(state: state, action: .completeVoting)

        #expect(newState.currentPhase == .clueRound)
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

    @Test func castVoteRejectsSelfVote() {
        var state = createGameInVotingPhase()
        let initialVoteCount = state.roundState?.votes.count ?? 0

        let voterID = state.players[0].id
        state = GameReducer.reduce(state: state, action: .castVote(voterID: voterID, suspectID: voterID))

        #expect(state.roundState?.votes.count == initialVoteCount)
    }

    @Test func completeVotingRequiresAllPlayersToVote() {
        var state = createGameInVotingPhase()
        state = GameReducer.reduce(
            state: state,
            action: .castVote(voterID: state.players[0].id, suspectID: state.players[1].id)
        )

        state = GameReducer.reduce(state: state, action: .completeVoting)

        #expect(state.currentPhase == .voting)
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

    // MARK: - Reset Tests

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

        // The hosted discussion phase is mandatory before voting.
        if state.currentPhase == .discussion {
            state = GameReducer.reduce(state: state, action: .startVoting)
        }

        return state
    }

    private func createGameInSummaryPhase() -> GameState {
        var state = createGameInVotingPhase()

        // All players vote - use first player as fallback if roundState is nil
        let imposterID = state.roundState?.imposterID ?? state.players[0].id
        for player in state.players {
            state = GameReducer.reduce(state: state, action: .castVote(voterID: player.id, suspectID: imposterID))
        }

        // Complete round
        state = GameReducer.reduce(state: state, action: .completeRound(imposterGuessedCorrectly: false))

        return state
    }
}
