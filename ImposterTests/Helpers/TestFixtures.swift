//
//  TestFixtures.swift
//  ImposterTests
//
//  Reusable test data and fixtures for unit tests.
//

import Foundation
import XCTest
@testable import Imposter

// MARK: - TestFixtures

/// Provides reusable test data for unit tests.
/// All fixtures use deterministic UUIDs for predictable testing.
@MainActor
enum TestFixtures {

    // MARK: - Deterministic UUIDs

    /// Deterministic UUIDs for players (allows predictable testing)
    /// Using nonisolated(unsafe) since these are constant values initialized once
    enum PlayerIDs {
        // swiftlint:disable force_unwrapping
        // These UUIDs are compile-time constants that will never fail to parse
        nonisolated(unsafe) static let alice = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        nonisolated(unsafe) static let bob = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID()
        nonisolated(unsafe) static let carol = UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID()
        nonisolated(unsafe) static let dave = UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID()
        nonisolated(unsafe) static let eve = UUID(uuidString: "00000000-0000-0000-0000-000000000005") ?? UUID()
        nonisolated(unsafe) static let frank = UUID(uuidString: "00000000-0000-0000-0000-000000000006") ?? UUID()
        nonisolated(unsafe) static let grace = UUID(uuidString: "00000000-0000-0000-0000-000000000007") ?? UUID()
        nonisolated(unsafe) static let hank = UUID(uuidString: "00000000-0000-0000-0000-000000000008") ?? UUID()
        nonisolated(unsafe) static let ivy = UUID(uuidString: "00000000-0000-0000-0000-000000000009") ?? UUID()
        nonisolated(unsafe) static let jack = UUID(uuidString: "00000000-0000-0000-0000-00000000000A") ?? UUID()
        // swiftlint:enable force_unwrapping
    }

    // MARK: - Players

    /// Default test player (Alice)
    static let defaultPlayer = Player(
        id: PlayerIDs.alice,
        name: "Alice",
        color: .crimson,
        emoji: "😀"
    )

    /// Minimum players for a valid game (3 players)
    static let minimumPlayers: [Player] = [
        Player(id: PlayerIDs.alice, name: "Alice", color: .crimson, emoji: "😀"),
        Player(id: PlayerIDs.bob, name: "Bob", color: .azure, emoji: "😎"),
        Player(id: PlayerIDs.carol, name: "Carol", color: .emerald, emoji: "🤔")
    ]

    /// Standard test players (4 players)
    static let standardPlayers: [Player] = [
        Player(id: PlayerIDs.alice, name: "Alice", color: .crimson, emoji: "😀"),
        Player(id: PlayerIDs.bob, name: "Bob", color: .azure, emoji: "😎"),
        Player(id: PlayerIDs.carol, name: "Carol", color: .emerald, emoji: "🤔"),
        Player(id: PlayerIDs.dave, name: "Dave", color: .amber, emoji: "🤩")
    ]

    /// Maximum players for a valid game (10 players)
    static let maximumPlayers: [Player] = [
        Player(id: PlayerIDs.alice, name: "Alice", color: .crimson, emoji: "😀"),
        Player(id: PlayerIDs.bob, name: "Bob", color: .azure, emoji: "😎"),
        Player(id: PlayerIDs.carol, name: "Carol", color: .emerald, emoji: "🤔"),
        Player(id: PlayerIDs.dave, name: "Dave", color: .amber, emoji: "🤩"),
        Player(id: PlayerIDs.eve, name: "Eve", color: .violet, emoji: "😜"),
        Player(id: PlayerIDs.frank, name: "Frank", color: .coral, emoji: "🧐"),
        Player(id: PlayerIDs.grace, name: "Grace", color: .teal, emoji: "😇"),
        Player(id: PlayerIDs.hank, name: "Hank", color: .rose, emoji: "🤓"),
        Player(id: PlayerIDs.ivy, name: "Ivy", color: .crimson, emoji: "😋"),
        Player(id: PlayerIDs.jack, name: "Jack", color: .azure, emoji: "😏")
    ]

    /// Players with scores for testing leaderboard
    static let playersWithScores: [Player] = [
        Player(id: PlayerIDs.alice, name: "Alice", color: .crimson, emoji: "😀", score: 5),
        Player(id: PlayerIDs.bob, name: "Bob", color: .azure, emoji: "😎", score: 3),
        Player(id: PlayerIDs.carol, name: "Carol", color: .emerald, emoji: "🤔", score: 7),
        Player(id: PlayerIDs.dave, name: "Dave", color: .amber, emoji: "🤩", score: 2)
    ]

    // MARK: - Game Settings

    /// Default game settings
    static let defaultSettings = GameSettings.default

    /// Settings with custom prompt enabled
    static var customPromptSettings: GameSettings {
        var settings = GameSettings.default
        settings.wordSource = .customPrompt
        settings.customWordPrompt = "Ocean creatures"
        return settings
    }

    /// Settings with all timers enabled
    static var timedSettings: GameSettings {
        var settings = GameSettings.default
        settings.clueTimerEnabled = true
        settings.clueTimerMinutes = 2
        settings.discussionTimerEnabled = true
        settings.discussionSeconds = 60
        settings.votingTimerEnabled = true
        settings.votingSeconds = 30
        return settings
    }

    /// Settings with specific categories selected
    static var categorizedSettings: GameSettings {
        var settings = GameSettings.default
        settings.selectedCategories = ["Animals", "Technology"]
        settings.wordPackDifficulty = .easy
        return settings
    }

    // MARK: - Game State

    /// Creates a game state with default configuration
    static func gameState(
        players: [Player] = standardPlayers,
        phase: GamePhase = .setup,
        settings: GameSettings = .default
    ) -> GameState {
        GameState(players: players, settings: settings, currentPhase: phase)
    }

    /// Game state ready to start (3+ players in setup phase)
    static var readyToStartState: GameState {
        gameState(players: minimumPlayers, phase: .setup)
    }

    /// Game state in role reveal phase
    static var roleRevealState: GameState {
        var state = gameState(phase: .roleReveal)
        state.roundState = defaultRoundState
        return state
    }

    /// Game state in clue round phase
    static var clueRoundState: GameState {
        var state = gameState(phase: .clueRound)
        state.roundState = defaultRoundState
        return state
    }

    /// Game state in voting phase
    static var votingState: GameState {
        var state = gameState(phase: .voting)
        state.roundState = defaultRoundState
        return state
    }

    /// Game state in reveal phase
    static var revealState: GameState {
        var state = gameState(phase: .reveal)
        state.roundState = defaultRoundState
        return state
    }

    // MARK: - Round State

    /// Default round state (Alice is imposter, word is "Elephant")
    static var defaultRoundState: RoundState {
        RoundState(
            secretWord: "Elephant",
            categoryHint: "Animals",
            imposterID: PlayerIDs.alice,
            firstPlayerIndex: 1
        )
    }

    /// Round state with a custom word
    static func roundState(
        secretWord: String = "Elephant",
        categoryHint: String = "Animals",
        imposterID: UUID = PlayerIDs.alice,
        firstPlayerIndex: Int = 1
    ) -> RoundState {
        RoundState(
            secretWord: secretWord,
            categoryHint: categoryHint,
            imposterID: imposterID,
            firstPlayerIndex: firstPlayerIndex
        )
    }

    // MARK: - Words

    /// Test words for various categories
    static let testWords: [String: [String]] = [
        "Animals": ["Elephant", "Giraffe", "Penguin", "Dolphin", "Lion"],
        "Technology": ["Computer", "Smartphone", "Robot", "Internet", "Satellite"],
        "Objects": ["Chair", "Clock", "Umbrella", "Bicycle", "Lamp"],
        "People": ["Doctor", "Teacher", "Artist", "Chef", "Athlete"],
        "Movies": ["Titanic", "Avatar", "Inception", "Matrix", "Frozen"]
    ]

    // MARK: - Mock Services

    /// Creates a configured mock word service
    static func mockWordService(
        selectResult: String = "Elephant",
        generateResult: String = "Giraffe"
    ) -> MockWordService {
        let service = MockWordService()
        service.selectWordResult = .success(selectResult)
        service.generateWordResult = .success(generateResult)
        return service
    }

    /// Creates a configured mock image service
    static func mockImageService(
        isAvailable: Bool = true
    ) -> MockImageService {
        let service = MockImageService()
        service.available = isAvailable
        return service
    }

    /// Creates a configured mock storage service
    static func mockStorageService() -> MockStorageService {
        MockStorageService()
    }

    /// Creates a configured mock haptics service
    static func mockHapticsService() -> MockHapticsService {
        MockHapticsService()
    }

    /// Creates a test app environment
    static func testEnvironment() -> AppEnvironment {
        AppEnvironment.test()
    }
}

// MARK: - XCTestCase Extensions

extension XCTestCase {

    /// Asserts that two game states are equal in key properties
    @MainActor
    func assertGameStatesEqual(
        _ state1: GameState,
        _ state2: GameState,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(state1.players.count, state2.players.count, "Player count mismatch", file: file, line: line)
        XCTAssertEqual(state1.currentPhase, state2.currentPhase, "Phase mismatch", file: file, line: line)
        XCTAssertEqual(state1.roundNumber, state2.roundNumber, "Round number mismatch", file: file, line: line)
    }

    /// Asserts that a player exists with the expected properties
    @MainActor
    func assertPlayer(
        _ player: Player?,
        hasName name: String,
        hasColor color: PlayerColor,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNotNil(player, "Player is nil", file: file, line: line)
        guard let player = player else { return }
        XCTAssertEqual(player.name, name, "Player name mismatch", file: file, line: line)
        XCTAssertEqual(player.color, color, "Player color mismatch", file: file, line: line)
    }

    /// Asserts that an effect is `.none`
    @MainActor
    func assertEffectIsNone(_ effect: Effect, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(effect.isNone, "Expected .none effect", file: file, line: line)
    }

    /// Asserts that an effect is a `.run` effect
    @MainActor
    func assertEffectIsRun(_ effect: Effect, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(effect.isRun, "Expected .run effect", file: file, line: line)
    }
}
