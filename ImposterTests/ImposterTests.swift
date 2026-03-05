//
//  ImposterTests.swift
//  ImposterTests
//
//  Main test suite for Imposter app.
//

import Testing
@testable import Imposter

@Suite("Imposter Tests")
@MainActor
struct ImposterTests {

    @Test func gameStateInitializesCorrectly() {
        let state = GameState()

        #expect(state.currentPhase == .setup)
        #expect(state.players.isEmpty)
        #expect(state.roundState == nil)
        #expect(state.roundNumber == 0)
    }

    @Test func playerInitializesWithDefaults() {
        let player = Player(name: "Test", color: .azure)

        #expect(player.name == "Test")
        #expect(player.color == .azure)
        #expect(player.score == 0)
    }

    @Test func gameSettingsHaveDefaults() {
        let settings = GameSettings.default

        #expect(settings.wordSource == .randomPack)
        #expect(settings.numberOfClueRounds == 2)
        #expect(settings.allowImposterWordGuess == true)
    }
}

// MARK: - Test Helpers

extension GameState {
    /// Creates a mock game state with the specified number of players
    @MainActor
    static func mock(playerCount: Int = 3) -> GameState {
        var state = GameState()
        for i in 0..<playerCount {
            let color = PlayerColor.allCases[i % PlayerColor.allCases.count]
            let player = Player(name: "Player \(i + 1)", color: color)
            state.players.append(player)
        }
        return state
    }
}

extension Player {
    /// Creates a mock player with default values
    @MainActor
    static func mock(name: String = "Test Player", color: PlayerColor = .azure) -> Player {
        Player(name: name, color: color)
    }
}
