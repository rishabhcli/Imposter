# Imposter – Technical Refactor Implementation Plan

> Comprehensive plan to improve architecture, testing, performance, and code quality.

---

## Executive Summary

This refactor focuses on elevating the Imposter codebase from a working MVP to a production-grade, maintainable iOS application. The current implementation is functional but has opportunities for improved testability, better separation of concerns, enhanced error handling, and comprehensive test coverage.

**Goals:**
- Achieve 80%+ test coverage
- Improve architecture with proper dependency injection
- Eliminate force unwraps and implicit optionals
- Add comprehensive error handling
- Profile and optimize performance
- Document public APIs
- Prepare for long-term maintainability

---

## Table of Contents

1. [Architecture Improvements](#1-architecture-improvements)
2. [Dependency Injection Overhaul](#2-dependency-injection-overhaul)
3. [Error Handling Strategy](#3-error-handling-strategy)
4. [Testing Infrastructure](#4-testing-infrastructure)
5. [Performance Optimization](#5-performance-optimization)
6. [Code Quality Improvements](#6-code-quality-improvements)
7. [Documentation](#7-documentation)
8. [Refactoring Phases](#8-refactoring-phases)

---

## 1. Architecture Improvements

### 1.1 Current State Analysis

**Strengths:**
- Redux-like unidirectional data flow ✅
- @Observable pattern for fine-grained updates ✅
- GamePhase state machine with validated transitions ✅
- Pure reducer functions ✅

**Weaknesses:**
- Side effects mixed into GameStore
- No protocol abstractions for testability
- Tight coupling between store and AI services
- Missing middleware/effect handling pattern

### 1.2 Proposed Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                           │
│   (HomeView, SetupView, RoleRevealView, VotingView, etc.)       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          GameStore                              │
│   @Observable @MainActor                                        │
│   - dispatch(action:) → Effect                                  │
│   - state: GameState                                            │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│   GameReducer    │ │ EffectRunner │ │    Middleware    │
│   (Pure Logic)   │ │ (Side Fx)    │ │  (Logging/Debug) │
└──────────────────┘ └──────────────┘ └──────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│  WordService     │ │ ImageService │ │  StorageService  │
│  (Protocol)      │ │ (Protocol)   │ │  (Protocol)      │
└──────────────────┘ └──────────────┘ └──────────────────┘
```

### 1.3 Effect System

Introduce a proper effect system to handle side effects cleanly:

```swift
// Domain/Effects/Effect.swift
enum Effect: Sendable {
    case none
    case run(@Sendable () async -> GameAction?)
    case batch([Effect])
    case sequence([Effect])

    static func generateWord(settings: GameSettings) -> Effect {
        .run {
            // Word generation logic
        }
    }

    static func generateImage(word: String) -> Effect {
        .run {
            // Image generation logic
        }
    }

    static func persist(state: GameState) -> Effect {
        .run {
            // Persistence logic
        }
    }
}
```

### 1.4 Reducer Returns Effects

Modify the reducer to return effects alongside state changes:

```swift
// Domain/Logic/GameReducer.swift
struct GameReducer {
    static func reduce(
        state: inout GameState,
        action: GameAction
    ) -> Effect {
        switch action {
        case .startGame:
            guard state.currentPhase.canTransition(to: .roleReveal) else {
                return .none
            }
            state.currentPhase = .roleReveal
            return .generateWord(settings: state.settings)

        case .setGeneratedWord(let word):
            state.roundState?.secretWord = word
            return .generateImage(word: word)

        // ... other cases
        }
    }
}
```

### 1.5 New File Structure

```
Imposter/
├── App/
│   ├── ImposterApp.swift
│   └── AppEnvironment.swift          # DI container
├── Domain/
│   ├── Models/
│   │   ├── GameState.swift
│   │   ├── Player.swift
│   │   ├── PlayerColor.swift         # Extract from Player
│   │   ├── PlayerEmoji.swift         # Extract from Player
│   │   ├── RoundState.swift
│   │   ├── GamePhase.swift
│   │   ├── GameSettings.swift
│   │   ├── VotingResult.swift        # New: explicit result type
│   │   └── CompletedRound.swift      # New: history model
│   ├── Actions/
│   │   └── GameAction.swift
│   ├── Effects/
│   │   ├── Effect.swift              # New: effect enum
│   │   └── EffectRunner.swift        # New: effect executor
│   ├── Logic/
│   │   ├── GameReducer.swift
│   │   ├── ScoringEngine.swift       # New: extracted scoring
│   │   └── VoteCalculator.swift      # New: vote tallying
│   └── Errors/
│       └── GameError.swift           # New: domain errors
├── Services/
│   ├── Protocols/
│   │   ├── WordServiceProtocol.swift
│   │   ├── ImageServiceProtocol.swift
│   │   ├── StorageServiceProtocol.swift
│   │   └── HapticsServiceProtocol.swift
│   ├── Implementations/
│   │   ├── WordService.swift         # Refactored from WordSelector
│   │   ├── AIWordService.swift       # Refactored from WordGenerator
│   │   ├── ImageService.swift        # ImagePlayground wrapper
│   │   ├── StorageService.swift      # Refactored from SettingsStore
│   │   └── HapticsService.swift      # Refactored from HapticManager
│   └── Mocks/
│       ├── MockWordService.swift
│       ├── MockImageService.swift
│       └── MockStorageService.swift
├── Store/
│   ├── GameStore.swift
│   └── Middleware/
│       ├── LoggingMiddleware.swift   # New: action logging
│       └── AnalyticsMiddleware.swift # New: analytics hooks
├── Features/
│   └── ... (existing structure)
├── DesignSystem/
│   └── ... (existing structure)
├── Utilities/
│   ├── AccessibilityAnnouncer.swift
│   └── AccessibilityIDs.swift
└── Resources/
    └── ... (existing structure)
```

---

## 2. Dependency Injection Overhaul

### 2.1 Current Problems

- Services instantiated directly in GameStore
- No way to swap implementations for testing
- Environment objects scattered across views
- Hard to test views in isolation

### 2.2 DI Container

Create a proper dependency container:

```swift
// App/AppEnvironment.swift
@MainActor
final class AppEnvironment: Observable {
    let wordService: WordServiceProtocol
    let imageService: ImageServiceProtocol
    let storageService: StorageServiceProtocol
    let hapticsService: HapticsServiceProtocol

    init(
        wordService: WordServiceProtocol = WordService(),
        imageService: ImageServiceProtocol = ImageService(),
        storageService: StorageServiceProtocol = StorageService(),
        hapticsService: HapticsServiceProtocol = HapticsService()
    ) {
        self.wordService = wordService
        self.imageService = imageService
        self.storageService = storageService
        self.hapticsService = hapticsService
    }

    static let live = AppEnvironment()

    static let preview = AppEnvironment(
        wordService: MockWordService(),
        imageService: MockImageService(),
        storageService: MockStorageService(),
        hapticsService: MockHapticsService()
    )

    static func test(
        wordService: WordServiceProtocol? = nil,
        imageService: ImageServiceProtocol? = nil
    ) -> AppEnvironment {
        AppEnvironment(
            wordService: wordService ?? MockWordService(),
            imageService: imageService ?? MockImageService(),
            storageService: MockStorageService(),
            hapticsService: MockHapticsService()
        )
    }
}
```

### 2.3 Service Protocols

Define protocols for all external dependencies:

```swift
// Services/Protocols/WordServiceProtocol.swift
protocol WordServiceProtocol: Sendable {
    func selectWord(
        from categories: [String]?,
        difficulty: GameSettings.Difficulty
    ) async throws -> String

    func generateWord(
        prompt: String
    ) async throws -> String

    var availableCategories: [String] { get }
}

// Services/Protocols/ImageServiceProtocol.swift
protocol ImageServiceProtocol: Sendable {
    var isAvailable: Bool { get }

    func generateImage(
        for word: String,
        style: ImageStyle
    ) async throws -> UIImage?

    enum ImageStyle {
        case illustration
        case sketch
        case photo
    }
}

// Services/Protocols/StorageServiceProtocol.swift
protocol StorageServiceProtocol: Sendable {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func delete(forKey key: String) throws

    func savePlayers(_ players: [Player]) throws
    func loadPlayers() throws -> [Player]?

    func saveSettings(_ settings: GameSettings) throws
    func loadSettings() throws -> GameSettings?
}
```

### 2.4 GameStore with Injected Dependencies

```swift
// Store/GameStore.swift
@Observable
@MainActor
final class GameStore {
    private(set) var state: GameState
    private let environment: AppEnvironment
    private let reducer: (inout GameState, GameAction) -> Effect

    init(
        initialState: GameState = GameState(),
        environment: AppEnvironment = .live,
        reducer: @escaping (inout GameState, GameAction) -> Effect = GameReducer.reduce
    ) {
        self.state = initialState
        self.environment = environment
        self.reducer = reducer
    }

    func dispatch(_ action: GameAction) {
        let effect = reducer(&state, action)
        Task {
            await runEffect(effect)
        }
    }

    private func runEffect(_ effect: Effect) async {
        switch effect {
        case .none:
            break
        case .run(let work):
            if let nextAction = await work() {
                await MainActor.run {
                    dispatch(nextAction)
                }
            }
        case .batch(let effects):
            await withTaskGroup(of: Void.self) { group in
                for effect in effects {
                    group.addTask { await self.runEffect(effect) }
                }
            }
        case .sequence(let effects):
            for effect in effects {
                await runEffect(effect)
            }
        }
    }
}
```

---

## 3. Error Handling Strategy

### 3.1 Domain Errors

Define a comprehensive error hierarchy:

```swift
// Domain/Errors/GameError.swift
enum GameError: LocalizedError, Sendable {
    // Player errors
    case invalidPlayerCount(current: Int, required: ClosedRange<Int>)
    case playerNotFound(id: UUID)
    case duplicatePlayerName(name: String)
    case invalidPlayerName(reason: String)

    // Phase errors
    case invalidPhaseTransition(from: GamePhase, to: GamePhase)
    case actionNotAllowedInPhase(action: String, phase: GamePhase)

    // Word errors
    case wordPackLoadingFailed(category: String, underlying: Error?)
    case noWordsAvailable(categories: [String])
    case wordGenerationFailed(underlying: Error?)
    case wordGenerationTimeout

    // Image errors
    case imageGenerationUnavailable
    case imageGenerationFailed(underlying: Error?)
    case imageGenerationTimeout

    // Voting errors
    case invalidVote(reason: String)
    case votingIncomplete(voted: Int, total: Int)

    // Storage errors
    case persistenceFailed(underlying: Error)
    case loadingFailed(underlying: Error)
    case corruptedData(key: String)

    var errorDescription: String? {
        switch self {
        case .invalidPlayerCount(let current, let required):
            return "Need \(required.lowerBound)-\(required.upperBound) players, have \(current)"
        case .playerNotFound:
            return "Player not found"
        case .duplicatePlayerName(let name):
            return "Player '\(name)' already exists"
        // ... other cases
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidPlayerCount:
            return "Add or remove players to meet the requirement"
        case .wordGenerationFailed:
            return "Try again or use random word pack instead"
        // ... other cases
        }
    }
}
```

### 3.2 Result Types for Operations

Use Result types for fallible operations:

```swift
// Services/Implementations/WordService.swift
final class WordService: WordServiceProtocol, Sendable {
    func selectWord(
        from categories: [String]?,
        difficulty: GameSettings.Difficulty
    ) async throws -> String {
        let packs = try await loadWordPacks(for: categories)

        guard !packs.isEmpty else {
            throw GameError.noWordsAvailable(categories: categories ?? [])
        }

        let filteredWords = packs.flatMap { pack in
            pack.words.filter {
                difficulty == .mixed || $0.difficulty == difficulty
            }
        }

        guard let word = filteredWords.randomElement()?.word else {
            throw GameError.noWordsAvailable(categories: categories ?? [])
        }

        return word
    }

    private func loadWordPacks(for categories: [String]?) async throws -> [WordPack] {
        let categoriesToLoad = categories ?? availableCategories

        return try await withThrowingTaskGroup(of: WordPack?.self) { group in
            for category in categoriesToLoad {
                group.addTask {
                    try? await self.loadWordPack(category: category)
                }
            }

            var packs: [WordPack] = []
            for try await pack in group {
                if let pack = pack {
                    packs.append(pack)
                }
            }
            return packs
        }
    }
}
```

### 3.3 Error Propagation in Effects

```swift
// Domain/Effects/Effect.swift
enum Effect: Sendable {
    case none
    case run(@Sendable () async -> GameAction?)
    case runWithError(@Sendable () async throws -> GameAction?, onError: @Sendable (Error) -> GameAction)
    case batch([Effect])
    case sequence([Effect])
}

// Usage in reducer
static func reduce(state: inout GameState, action: GameAction) -> Effect {
    switch action {
    case .generateWord:
        return .runWithError(
            {
                let word = try await wordService.generateWord(prompt: state.settings.customWordPrompt ?? "")
                return .setGeneratedWord(word)
            },
            onError: { error in
                return .wordGenerationFailed(error)
            }
        )

    case .wordGenerationFailed(let error):
        state.wordGenerationError = error
        // Fallback to random word
        return .selectRandomWord(categories: state.settings.selectedCategories)
    }
}
```

### 3.4 User-Facing Error Presentation

```swift
// Features/Common/ErrorView.swift
struct ErrorBanner: View {
    let error: GameError
    let dismissAction: () -> Void
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: LGSpacing.small) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(error.localizedDescription)
                    .font(LGTypography.bodyMedium)
                Spacer()
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                }
            }

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(.secondary)
            }

            if let retry = retryAction {
                LGButton("Try Again", style: .secondary, action: retry)
            }
        }
        .padding()
        .glassEffect()
    }
}
```

---

## 4. Testing Infrastructure

### 4.1 Test Organization

```
ImposterTests/
├── Domain/
│   ├── Models/
│   │   ├── PlayerTests.swift
│   │   ├── GamePhaseTests.swift
│   │   ├── GameStateTests.swift
│   │   └── RoundStateTests.swift
│   ├── Logic/
│   │   ├── GameReducerTests.swift
│   │   ├── ScoringEngineTests.swift
│   │   └── VoteCalculatorTests.swift
│   └── Effects/
│       └── EffectTests.swift
├── Services/
│   ├── WordServiceTests.swift
│   ├── ImageServiceTests.swift
│   └── StorageServiceTests.swift
├── Store/
│   └── GameStoreTests.swift
├── Integration/
│   ├── FullGameFlowTests.swift
│   ├── AIIntegrationTests.swift
│   └── PersistenceIntegrationTests.swift
├── Snapshots/
│   ├── HomeViewSnapshotTests.swift
│   ├── RoleRevealSnapshotTests.swift
│   └── VotingViewSnapshotTests.swift
└── Helpers/
    ├── TestFixtures.swift
    ├── MockServices.swift
    └── XCTestCase+Extensions.swift

ImposterUITests/
├── Flows/
│   ├── NewGameFlowTests.swift
│   ├── VotingFlowTests.swift
│   └── MultiRoundFlowTests.swift
├── Accessibility/
│   ├── VoiceOverTests.swift
│   └── DynamicTypeTests.swift
└── Helpers/
    └── UITestHelpers.swift
```

### 4.2 Test Fixtures

Create reusable test fixtures:

```swift
// ImposterTests/Helpers/TestFixtures.swift
enum TestFixtures {
    static let defaultPlayer = Player(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Alice",
        color: .crimson,
        emoji: "😀"
    )

    static let defaultPlayers: [Player] = [
        Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Alice", color: .crimson, emoji: "😀"),
        Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Bob", color: .azure, emoji: "😎"),
        Player(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Carol", color: .emerald, emoji: "🤔"),
    ]

    static let defaultSettings = GameSettings.default

    static func gameState(
        players: [Player] = defaultPlayers,
        phase: GamePhase = .setup,
        settings: GameSettings = defaultSettings
    ) -> GameState {
        let state = GameState(players: players, settings: settings)
        state.currentPhase = phase
        return state
    }

    static func roundState(
        secretWord: String = "elephant",
        imposterID: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    ) -> RoundState {
        RoundState(
            secretWord: secretWord,
            imposterID: imposterID,
            firstPlayerID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        )
    }
}
```

### 4.3 Mock Services

```swift
// ImposterTests/Helpers/MockServices.swift
final class MockWordService: WordServiceProtocol, @unchecked Sendable {
    var selectWordResult: Result<String, Error> = .success("elephant")
    var generateWordResult: Result<String, Error> = .success("giraffe")
    var selectWordCallCount = 0
    var generateWordCallCount = 0

    var availableCategories: [String] = ["animals", "technology"]

    func selectWord(from categories: [String]?, difficulty: GameSettings.Difficulty) async throws -> String {
        selectWordCallCount += 1
        return try selectWordResult.get()
    }

    func generateWord(prompt: String) async throws -> String {
        generateWordCallCount += 1
        return try generateWordResult.get()
    }
}

final class MockImageService: ImageServiceProtocol, @unchecked Sendable {
    var isAvailable = true
    var generateImageResult: Result<UIImage?, Error> = .success(nil)
    var generateImageCallCount = 0
    var lastRequestedWord: String?

    func generateImage(for word: String, style: ImageStyle) async throws -> UIImage? {
        generateImageCallCount += 1
        lastRequestedWord = word
        return try generateImageResult.get()
    }
}
```

### 4.4 Reducer Tests

```swift
// ImposterTests/Domain/Logic/GameReducerTests.swift
final class GameReducerTests: XCTestCase {

    // MARK: - Setup Phase

    func testAddPlayer_AddsPlayerToState() {
        var state = TestFixtures.gameState(players: [])

        let effect = GameReducer.reduce(
            state: &state,
            action: .addPlayer(name: "Alice", color: .crimson, emoji: "😀")
        )

        XCTAssertEqual(state.players.count, 1)
        XCTAssertEqual(state.players.first?.name, "Alice")
        XCTAssertEqual(state.players.first?.color, .crimson)
        XCTAssert(effect.isNone)
    }

    func testAddPlayer_RejectsWhenAtMaxPlayers() {
        var state = TestFixtures.gameState(
            players: (0..<10).map { i in
                Player(name: "P\(i)", color: PlayerColor.allCases[i % 8], emoji: "😀")
            }
        )

        let effect = GameReducer.reduce(
            state: &state,
            action: .addPlayer(name: "Extra", color: .crimson, emoji: "😀")
        )

        XCTAssertEqual(state.players.count, 10) // Unchanged
        XCTAssert(effect.isNone)
    }

    func testStartGame_TransitionsToRoleReveal_WhenValid() {
        var state = TestFixtures.gameState(players: TestFixtures.defaultPlayers)
        state.currentPhase = .setup

        let effect = GameReducer.reduce(state: &state, action: .startGame)

        XCTAssertEqual(state.currentPhase, .roleReveal)
        XCTAssertNotNil(state.roundState)
        // Effect should trigger word generation
        XCTAssertTrue(effect.isRun)
    }

    func testStartGame_FailsWithInsufficientPlayers() {
        var state = TestFixtures.gameState(players: [TestFixtures.defaultPlayer])
        state.currentPhase = .setup

        let effect = GameReducer.reduce(state: &state, action: .startGame)

        XCTAssertEqual(state.currentPhase, .setup) // Unchanged
        XCTAssert(effect.isNone)
    }

    // MARK: - Phase Transitions

    func testInvalidPhaseTransition_IsRejected() {
        var state = TestFixtures.gameState()
        state.currentPhase = .setup

        // Try to skip directly to voting (invalid)
        let effect = GameReducer.reduce(state: &state, action: .startVoting)

        XCTAssertEqual(state.currentPhase, .setup) // Unchanged
        XCTAssert(effect.isNone)
    }

    // MARK: - Voting

    func testCastVote_RecordsVote() {
        var state = TestFixtures.gameState()
        state.currentPhase = .voting
        state.roundState = TestFixtures.roundState()

        let voterID = TestFixtures.defaultPlayers[0].id
        let suspectID = TestFixtures.defaultPlayers[1].id

        let effect = GameReducer.reduce(
            state: &state,
            action: .castVote(voterID: voterID, suspectID: suspectID)
        )

        XCTAssertEqual(state.roundState?.votes[voterID], suspectID)
    }

    func testCastVote_CannotVoteForSelf() {
        var state = TestFixtures.gameState()
        state.currentPhase = .voting
        state.roundState = TestFixtures.roundState()

        let playerID = TestFixtures.defaultPlayers[0].id

        let effect = GameReducer.reduce(
            state: &state,
            action: .castVote(voterID: playerID, suspectID: playerID)
        )

        XCTAssertNil(state.roundState?.votes[playerID]) // Vote rejected
    }

    // MARK: - Scoring

    func testCompleteRound_ScoresCorrectVotes() {
        var state = TestFixtures.gameState()
        state.currentPhase = .reveal
        state.roundState = TestFixtures.roundState(
            imposterID: TestFixtures.defaultPlayers[0].id
        )

        // All players except imposter vote for imposter
        state.roundState?.votes = [
            TestFixtures.defaultPlayers[1].id: TestFixtures.defaultPlayers[0].id,
            TestFixtures.defaultPlayers[2].id: TestFixtures.defaultPlayers[0].id,
        ]

        let effect = GameReducer.reduce(state: &state, action: .completeRound)

        // Non-imposters should have scored
        XCTAssertEqual(state.players[1].score, state.settings.pointsForCorrectVote)
        XCTAssertEqual(state.players[2].score, state.settings.pointsForCorrectVote)
        XCTAssertEqual(state.players[0].score, 0) // Imposter didn't score
    }
}
```

### 4.5 Integration Tests

```swift
// ImposterTests/Integration/FullGameFlowTests.swift
@MainActor
final class FullGameFlowTests: XCTestCase {
    var store: GameStore!
    var mockWordService: MockWordService!
    var mockImageService: MockImageService!

    override func setUp() async throws {
        mockWordService = MockWordService()
        mockImageService = MockImageService()

        let environment = AppEnvironment.test(
            wordService: mockWordService,
            imageService: mockImageService
        )

        store = GameStore(environment: environment)
    }

    func testCompleteGameFlow() async throws {
        // Setup phase
        store.dispatch(.addPlayer(name: "Alice", color: .crimson, emoji: "😀"))
        store.dispatch(.addPlayer(name: "Bob", color: .azure, emoji: "😎"))
        store.dispatch(.addPlayer(name: "Carol", color: .emerald, emoji: "🤔"))

        XCTAssertEqual(store.state.players.count, 3)
        XCTAssertEqual(store.state.currentPhase, .setup)

        // Start game
        store.dispatch(.startGame)

        // Wait for async effects
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(store.state.currentPhase, .roleReveal)
        XCTAssertNotNil(store.state.roundState)
        XCTAssertEqual(mockWordService.selectWordCallCount, 1)

        // Reveal roles
        for player in store.state.players {
            store.dispatch(.revealRoleToPlayer(id: player.id))
        }
        store.dispatch(.completeRoleReveal)

        XCTAssertEqual(store.state.currentPhase, .clueRound)

        // Complete clue rounds
        store.dispatch(.advanceToNextClue)
        store.dispatch(.advanceToNextClue)
        store.dispatch(.advanceToNextClue)
        store.dispatch(.completeClueRounds)

        // Skip to voting
        store.dispatch(.startVoting)
        XCTAssertEqual(store.state.currentPhase, .voting)

        // Cast votes
        let imposterID = store.state.roundState!.imposterID
        for player in store.state.players where player.id != imposterID {
            store.dispatch(.castVote(voterID: player.id, suspectID: imposterID))
        }
        store.dispatch(.completeVoting)

        // Reveal
        XCTAssertEqual(store.state.currentPhase, .reveal)
        store.dispatch(.revealImposter)
        store.dispatch(.completeRound)

        // Summary
        XCTAssertEqual(store.state.currentPhase, .summary)

        // Verify scoring
        let nonImposters = store.state.players.filter { $0.id != imposterID }
        for player in nonImposters {
            XCTAssertGreaterThan(player.score, 0)
        }
    }
}
```

### 4.6 UI Tests

```swift
// ImposterUITests/Flows/NewGameFlowTests.swift
final class NewGameFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testCanAddPlayersAndStartGame() {
        // Tap New Game
        app.buttons["New Game"].tap()

        // Verify we're on setup screen
        XCTAssertTrue(app.navigationBars["Player Setup"].exists)

        // Add first player
        let nameField = app.textFields["Player name"]
        nameField.tap()
        nameField.typeText("Alice")
        app.buttons["Add"].tap()

        // Add second player
        nameField.tap()
        nameField.clearAndTypeText("Bob")
        app.buttons["Add"].tap()

        // Add third player
        nameField.tap()
        nameField.clearAndTypeText("Carol")
        app.buttons["Add"].tap()

        // Verify players added
        XCTAssertTrue(app.staticTexts["Alice"].exists)
        XCTAssertTrue(app.staticTexts["Bob"].exists)
        XCTAssertTrue(app.staticTexts["Carol"].exists)

        // Start game
        app.buttons["Start Game"].tap()

        // Should be on role reveal
        XCTAssertTrue(app.staticTexts["Pass to"].exists)
    }

    func testCannotStartGameWithFewerThan3Players() {
        app.buttons["New Game"].tap()

        // Add only 2 players
        let nameField = app.textFields["Player name"]
        nameField.tap()
        nameField.typeText("Alice")
        app.buttons["Add"].tap()

        nameField.tap()
        nameField.clearAndTypeText("Bob")
        app.buttons["Add"].tap()

        // Start button should be disabled or show error
        let startButton = app.buttons["Start Game"]
        XCTAssertFalse(startButton.isEnabled)
    }
}
```

### 4.7 Snapshot Tests

```swift
// ImposterTests/Snapshots/HomeViewSnapshotTests.swift
import SnapshotTesting
import SwiftUI

final class HomeViewSnapshotTests: XCTestCase {

    func testHomeView_Light() {
        let view = HomeView()
            .environment(\.colorScheme, .light)
            .environment(GameStore(environment: .preview))

        let controller = UIHostingController(rootView: view)
        controller.view.frame = UIScreen.main.bounds

        assertSnapshot(of: controller, as: .image(on: .iPhone16Pro))
    }

    func testHomeView_Dark() {
        let view = HomeView()
            .environment(\.colorScheme, .dark)
            .environment(GameStore(environment: .preview))

        let controller = UIHostingController(rootView: view)
        controller.view.frame = UIScreen.main.bounds

        assertSnapshot(of: controller, as: .image(on: .iPhone16Pro))
    }

    func testHomeView_DynamicType_AccessibilityLarge() {
        let view = HomeView()
            .environment(\.sizeCategory, .accessibilityLarge)
            .environment(GameStore(environment: .preview))

        let controller = UIHostingController(rootView: view)
        controller.view.frame = UIScreen.main.bounds

        assertSnapshot(of: controller, as: .image(on: .iPhone16Pro))
    }
}
```

---

## 5. Performance Optimization

### 5.1 Profiling Tasks

| Area | Tool | Target |
|------|------|--------|
| Launch time | Instruments (App Launch) | < 2 seconds |
| Frame rate | Instruments (Animation Hitches) | Steady 60fps |
| Memory | Instruments (Allocations) | < 100MB |
| CPU | Instruments (Time Profiler) | No main thread blocking |
| Hangs | Instruments (Hangs) | 0 hangs > 250ms |

### 5.2 Known Optimization Opportunities

#### 5.2.1 View Body Optimization

```swift
// Before: Expensive computation in body
struct VotingView: View {
    @Environment(GameStore.self) var store

    var body: some View {
        // ❌ Computed every render
        let sortedPlayers = store.state.players.sorted { $0.score > $1.score }
        // ...
    }
}

// After: Pre-computed in reducer or cached
struct VotingView: View {
    @Environment(GameStore.self) var store

    var body: some View {
        // ✅ Access pre-computed value
        let sortedPlayers = store.sortedPlayers
        // ...
    }
}
```

#### 5.2.2 Image Memory Management

```swift
// Services/Implementations/ImageService.swift
final class ImageService: ImageServiceProtocol {
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 5 // Only keep last 5 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }

    func generateImage(for word: String, style: ImageStyle) async throws -> UIImage? {
        let cacheKey = "\(word)-\(style)" as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let image = try await generateImageInternal(word: word, style: style)

        if let image = image {
            cache.setObject(image, forKey: cacheKey)
        }

        return image
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
```

#### 5.2.3 Lazy Loading Word Packs

```swift
// Services/Implementations/WordService.swift
actor WordPackCache {
    private var loadedPacks: [String: WordPack] = [:]

    func getPack(_ category: String) async throws -> WordPack {
        if let cached = loadedPacks[category] {
            return cached
        }

        let pack = try await loadFromDisk(category: category)
        loadedPacks[category] = pack
        return pack
    }

    func preloadPacks(_ categories: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for category in categories {
                group.addTask {
                    _ = try? await self.getPack(category)
                }
            }
        }
    }
}
```

#### 5.2.4 @IgnoreObservation for Non-UI Properties

```swift
// Domain/Models/GameState.swift
@Observable
final class GameState: Sendable {
    var players: [Player]
    var currentPhase: GamePhase
    var settings: GameSettings
    var roundState: RoundState?

    @ObservationIgnored  // Don't trigger view updates for history
    var gameHistory: [CompletedRound] = []

    @ObservationIgnored  // Debug/analytics only
    var actionLog: [String] = []
}
```

### 5.3 Concurrency Best Practices

```swift
// Ensure AI operations don't block main thread
extension GameStore {
    private func handleWordGeneration() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            do {
                let word = try await self.environment.wordService.generateWord(
                    prompt: self.state.settings.customWordPrompt ?? ""
                )

                await MainActor.run {
                    self.dispatch(.setGeneratedWord(word))
                }
            } catch {
                await MainActor.run {
                    self.dispatch(.wordGenerationFailed(error))
                }
            }
        }
    }
}
```

---

## 6. Code Quality Improvements

### 6.1 SwiftLint Configuration

Create `.swiftlint.yml`:

```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_comma
  - identifier_name

opt_in_rules:
  - empty_count
  - empty_string
  - fatal_error_message
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - last_where
  - legacy_random
  - modifier_order
  - overridden_super_call
  - private_action
  - private_outlet
  - prohibited_super_call
  - redundant_nil_coalescing
  - sorted_first_last
  - unavailable_function
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call
  - yoda_condition

excluded:
  - Pods
  - .build
  - DerivedData

force_cast: error
force_try: error
force_unwrapping: error

line_length:
  warning: 120
  error: 200

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 50
  error: 100

cyclomatic_complexity:
  warning: 10
  error: 20

nesting:
  type_level: 2
  function_level: 3

custom_rules:
  no_print:
    name: "No Print Statements"
    regex: "\\bprint\\("
    message: "Use Logger instead of print"
    severity: warning
```

### 6.2 Pre-commit Hooks

Create `.githooks/pre-commit`:

```bash
#!/bin/bash

# Run SwiftLint
if which swiftlint >/dev/null; then
    swiftlint lint --strict
    if [ $? -ne 0 ]; then
        echo "SwiftLint failed. Please fix violations before committing."
        exit 1
    fi
fi

# Run tests
xcodebuild test \
    -scheme Imposter \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -quiet

if [ $? -ne 0 ]; then
    echo "Tests failed. Please fix before committing."
    exit 1
fi

exit 0
```

### 6.3 Logging Infrastructure

```swift
// Utilities/Logger.swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.imposter"

    static let game = Logger(subsystem: subsystem, category: "Game")
    static let ai = Logger(subsystem: subsystem, category: "AI")
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}

// Usage
Logger.game.debug("Starting game with \(players.count) players")
Logger.ai.info("Generating word with prompt: \(prompt)")
Logger.storage.error("Failed to save settings: \(error)")
```

### 6.4 Debug Middleware

```swift
// Store/Middleware/LoggingMiddleware.swift
struct LoggingMiddleware {
    static func log(
        action: GameAction,
        stateBefore: GameState,
        stateAfter: GameState
    ) {
        #if DEBUG
        let changes = diff(stateBefore, stateAfter)

        Logger.game.debug("""
        ┌─ Action: \(String(describing: action))
        ├─ Phase: \(stateBefore.currentPhase) → \(stateAfter.currentPhase)
        ├─ Players: \(stateBefore.players.count) → \(stateAfter.players.count)
        └─ Changes: \(changes)
        """)
        #endif
    }
}
```

---

## 7. Documentation

### 7.1 Documentation Standards

All public APIs should have documentation comments:

```swift
/// Calculates the voting result for the current round.
///
/// This method tallies all votes and determines:
/// - The player with the most votes (or tied players)
/// - Whether the imposter was correctly identified
/// - Points to award to each player
///
/// - Parameter roundState: The current round's state containing votes
/// - Parameter players: All players in the game
/// - Returns: A `VotingResult` containing the outcome and score changes
///
/// - Complexity: O(n) where n is the number of players
///
/// - Note: In case of a tie, both tied players are considered "voted out"
///   for scoring purposes.
static func calculateVotingResult(
    roundState: RoundState,
    players: [Player]
) -> VotingResult {
    // Implementation
}
```

### 7.2 Architecture Decision Records

Create `docs/adr/` directory for architecture decisions:

```markdown
# ADR-001: Unidirectional Data Flow with Effects

## Status
Accepted

## Context
We need a predictable state management solution that:
- Supports async side effects (AI generation)
- Is testable
- Works with SwiftUI's Observation framework

## Decision
Use a Redux-inspired unidirectional data flow with:
- Pure reducer functions returning Effects
- Effect runners for async operations
- MainActor isolation for state

## Consequences
- Predictable state transitions
- Easy to test reducers
- Clear separation of pure logic and side effects
- Slightly more boilerplate than direct @Observable mutations
```

### 7.3 Generated Documentation

Add DocC documentation target for API reference generation.

---

## 8. Refactoring Phases

### Phase 1: Foundation (Week 1)

| Task | Priority | Effort |
|------|----------|--------|
| Define service protocols | High | 2h |
| Create AppEnvironment DI container | High | 3h |
| Implement Effect enum | High | 4h |
| Create mock services | Medium | 3h |
| Set up test fixtures | Medium | 2h |
| Configure SwiftLint | Low | 1h |

**Deliverables:**
- [ ] `Services/Protocols/` with all protocol definitions
- [ ] `AppEnvironment.swift` with DI container
- [ ] `Domain/Effects/Effect.swift`
- [ ] `Services/Mocks/` with all mocks
- [ ] `ImposterTests/Helpers/TestFixtures.swift`
- [ ] `.swiftlint.yml`

### Phase 2: Service Extraction (Week 2)

| Task | Priority | Effort |
|------|----------|--------|
| Extract WordService from WordSelector | High | 4h |
| Extract AIWordService from WordGenerator | High | 3h |
| Extract ImageService from inline code | High | 4h |
| Extract StorageService from SettingsStore | Medium | 3h |
| Extract HapticsService from HapticManager | Low | 1h |
| Write service unit tests | High | 6h |

**Deliverables:**
- [ ] `Services/Implementations/WordService.swift`
- [ ] `Services/Implementations/AIWordService.swift`
- [ ] `Services/Implementations/ImageService.swift`
- [ ] `Services/Implementations/StorageService.swift`
- [ ] `Services/Implementations/HapticsService.swift`
- [ ] Service unit tests (80%+ coverage)

### Phase 3: Error Handling (Week 2-3)

| Task | Priority | Effort |
|------|----------|--------|
| Define GameError enum | High | 2h |
| Add error handling to services | High | 4h |
| Create error UI components | Medium | 3h |
| Add error effects to reducer | High | 4h |
| Write error handling tests | Medium | 3h |

**Deliverables:**
- [ ] `Domain/Errors/GameError.swift`
- [ ] Services throw appropriate errors
- [ ] `Features/Common/ErrorBanner.swift`
- [ ] Reducer handles error actions
- [ ] Error handling tests

### Phase 4: Reducer Refactor (Week 3)

| Task | Priority | Effort |
|------|----------|--------|
| Modify reducer to return Effects | High | 6h |
| Extract ScoringEngine | Medium | 2h |
| Extract VoteCalculator | Medium | 2h |
| Update GameStore to run effects | High | 4h |
| Comprehensive reducer tests | High | 8h |

**Deliverables:**
- [ ] `GameReducer.reduce() -> Effect`
- [ ] `Domain/Logic/ScoringEngine.swift`
- [ ] `Domain/Logic/VoteCalculator.swift`
- [ ] Updated `GameStore.swift`
- [ ] 90%+ reducer test coverage

### Phase 5: Testing Infrastructure (Week 4)

| Task | Priority | Effort |
|------|----------|--------|
| Set up integration tests | High | 4h |
| Write full game flow tests | High | 6h |
| Set up snapshot testing | Medium | 3h |
| Write snapshot tests for key views | Medium | 4h |
| Configure CI test pipeline | High | 3h |

**Deliverables:**
- [ ] `ImposterTests/Integration/`
- [ ] Full game flow integration tests
- [ ] Snapshot testing infrastructure
- [ ] Key view snapshots (Home, RoleReveal, Voting, Summary)
- [ ] CI configuration

### Phase 6: UI Tests & Accessibility (Week 5)

| Task | Priority | Effort |
|------|----------|--------|
| Write UI flow tests | High | 6h |
| VoiceOver audit and fixes | Medium | 4h |
| Dynamic Type testing | Medium | 3h |
| Add accessibility identifiers | Medium | 2h |
| Write accessibility UI tests | Medium | 4h |

**Deliverables:**
- [ ] `ImposterUITests/Flows/`
- [ ] VoiceOver improvements
- [ ] Dynamic Type verified
- [ ] Comprehensive accessibility IDs
- [ ] `ImposterUITests/Accessibility/`

### Phase 7: Performance & Polish (Week 6)

| Task | Priority | Effort |
|------|----------|--------|
| Profile with Instruments | High | 4h |
| Optimize identified bottlenecks | High | 6h |
| Add @ObservationIgnored where needed | Medium | 2h |
| Implement image caching | Medium | 3h |
| Memory leak audit | High | 3h |
| Add logging infrastructure | Medium | 2h |

**Deliverables:**
- [ ] Performance baseline documented
- [ ] Optimizations applied
- [ ] Memory usage < 100MB verified
- [ ] 60fps verified
- [ ] `Utilities/Logger.swift`

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Test coverage (Domain) | ~20% | 90% |
| Test coverage (Services) | ~0% | 80% |
| Test coverage (Store) | ~30% | 80% |
| UI test coverage | ~10% | 50% |
| Force unwraps | Unknown | 0 |
| SwiftLint violations | Unknown | 0 |
| Launch time | Unknown | < 2s |
| Peak memory | Unknown | < 100MB |
| Documented public APIs | ~0% | 100% |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing functionality | Comprehensive test suite before refactoring |
| Scope creep | Strict phase boundaries, no feature additions |
| Regression bugs | Integration tests covering full game flow |
| Performance degradation | Profile before and after each phase |
| Time overrun | Prioritize high-impact changes first |

---

## Next Steps

1. Review and approve this plan
2. Create GitHub issues for each task
3. Begin Phase 1: Foundation
4. Daily progress updates in TASKS.md

---

*Last updated: January 2026*
