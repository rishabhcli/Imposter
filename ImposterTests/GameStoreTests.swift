//
//  GameStoreTests.swift
//  ImposterTests
//
//  Focused tests for GameStore dependency wiring and persistence behavior.
//

import XCTest
@testable import Imposter

@MainActor
final class GameStoreTests: XCTestCase {

    func testInitLoadsSavedPlayersFromStorageService() throws {
        let storage = MockStorageService()
        let players = TestFixtures.minimumPlayers
        try storage.savePlayers(players)

        let store = GameStore(
            storageService: storage,
            wordService: MockWordService(),
            hintService: MockHintService(),
            imageService: MockImageService()
        )

        XCTAssertEqual(store.players, players)
        XCTAssertEqual(storage.loadCallCount, 1)
    }

    func testAddPlayerPersistsPlayersThroughStorageService() throws {
        let storage = MockStorageService()
        let store = GameStore(
            storageService: storage,
            wordService: MockWordService(),
            hintService: MockHintService(),
            imageService: MockImageService()
        )

        store.dispatch(.addPlayer(name: "Alice", color: .crimson))

        XCTAssertEqual(storage.saveCallCount, 1)
        let persistedPlayers = try storage.loadPlayers()
        XCTAssertEqual(persistedPlayers?.map(\.name), ["Alice"])
    }

    func testAppEnvironmentMakeGameStoreUsesInjectedStorageService() throws {
        let storage = MockStorageService()
        try storage.savePlayers(TestFixtures.minimumPlayers)

        let environment = AppEnvironment.test(
            wordService: MockWordService(),
            imageService: MockImageService(),
            hintService: MockHintService(),
            storageService: storage,
            hapticsService: MockHapticsService()
        )

        let store = environment.makeGameStore()

        XCTAssertEqual(store.players.count, TestFixtures.minimumPlayers.count)
        XCTAssertEqual(storage.loadCallCount, 1)
    }

    func testStartGameWithCustomPromptUsesInjectedHintService() async throws {
        let wordService = MockWordService()
        let hintService = MockHintService()
        let imageService = MockImageService()
        let state = TestFixtures.gameState(
            players: TestFixtures.minimumPlayers,
            phase: .setup,
            settings: TestFixtures.customPromptSettings
        )

        let store = GameStore(
            state: state,
            storageService: MockStorageService(),
            wordService: wordService,
            hintService: hintService,
            imageService: imageService
        )

        store.startGame()

        try await assertEventually("word generation should run") {
            wordService.generateWordCallCount == 1
        }
        try await assertEventually("hint generation should run") {
            hintService.generateHintCallCount == 1
        }

        XCTAssertEqual(wordService.lastGeneratePrompt, "Ocean creatures")
        XCTAssertEqual(hintService.lastSecretWord, "Giraffe")
        XCTAssertEqual(hintService.lastCategory, "Ocean creatures")
        XCTAssertEqual(store.state.roundState?.secretWord, "Giraffe")
        XCTAssertEqual(store.state.roundState?.imposterHint, "Animals")
        XCTAssertEqual(imageService.generateImageCallCount, 1)
    }

    func testHintGenerationFallsBackToCategoryWhenServiceFails() async throws {
        let hintService = MockHintService()
        hintService.failGenerateHint(with: HintServiceError.generationFailed(underlying: nil))

        let store = GameStore(
            state: TestFixtures.gameState(
                players: TestFixtures.minimumPlayers,
                phase: .setup,
                settings: TestFixtures.customPromptSettings
            ),
            storageService: MockStorageService(),
            wordService: MockWordService(),
            hintService: hintService,
            imageService: MockImageService()
        )

        store.startGame()

        try await assertEventually("hint fallback should populate the round state") {
            store.state.roundState?.imposterHint == "Ocean creatures"
        }
    }

    func testStartGameWithRandomPackUsesInjectedWordService() async throws {
        let wordService = MockWordService()
        let hintService = MockHintService()
        let imageService = MockImageService()
        let state = TestFixtures.gameState(
            players: TestFixtures.minimumPlayers,
            phase: .setup,
            settings: TestFixtures.defaultSettings
        )

        let store = GameStore(
            state: state,
            storageService: MockStorageService(),
            wordService: wordService,
            hintService: hintService,
            imageService: imageService
        )

        store.startGame()

        try await assertEventually("prepared round should transition into role reveal") {
            store.currentPhase == .roleReveal
        }

        try await assertEventually("random word selection should run") {
            wordService.selectWordCallCount == 1
        }

        try await assertEventually("hint generation should run for random packs") {
            hintService.generateHintCallCount == 1
        }

        XCTAssertEqual(store.state.roundState?.secretWord, "Elephant")
        XCTAssertEqual(store.state.roundState?.categoryHint, "Mixed")
        XCTAssertEqual(store.state.roundState?.imposterHint, "Animals")
        XCTAssertEqual(imageService.generateImageCallCount, 1)
    }

    func testStartNewRoundUsesInjectedWordService() async throws {
        let wordService = MockWordService()
        let hintService = MockHintService()
        let imageService = MockImageService()
        let state = TestFixtures.gameState(
            players: TestFixtures.minimumPlayers,
            phase: .summary,
            settings: TestFixtures.defaultSettings
        )

        let store = GameStore(
            state: state,
            storageService: MockStorageService(),
            wordService: wordService,
            hintService: hintService,
            imageService: imageService
        )

        store.startNewRound()

        try await assertEventually("next round should transition into role reveal") {
            store.currentPhase == .roleReveal && store.roundNumber == 1
        }

        try await assertEventually("next round should select a random word") {
            wordService.selectWordCallCount == 1
        }

        XCTAssertEqual(store.state.roundState?.secretWord, "Elephant")
        XCTAssertEqual(store.state.roundState?.categoryHint, "Mixed")
    }

    private func assertEventually(
        _ message: @autoclosure () -> String,
        timeout: Duration = .seconds(2),
        pollInterval: Duration = .milliseconds(20),
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping @MainActor () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout

        while ContinuousClock.now < deadline {
            if condition() {
                return
            }

            try await Task.sleep(for: pollInterval)
        }

        XCTFail(message(), file: file, line: line)
    }
}
