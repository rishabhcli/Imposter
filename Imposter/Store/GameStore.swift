//
//  GameStore.swift
//  Imposter
//
//  Observable store with dispatch() for unidirectional data flow.
//

import Foundation
import Observation
import OSLog
import UIKit

// MARK: - WordGenerationStatus

enum WordGenerationStatus: Sendable, Equatable {
    case idle
    case generating
    case generated
    case fallback(WordGenerationFallbackReason)
}

enum WordGenerationFallbackReason: String, Sendable, Equatable {
    case generationFailed
    case duplicateRecentWord
    case nearDuplicateWord
}

// MARK: - GameStore

/// Central store for game state management.
/// Provides a dispatch() method for unidirectional data flow.
@Observable
@MainActor
final class GameStore {
    private static let recentWordAvoidanceLimit = 12

    // MARK: - Properties

    /// The current game state
    private(set) var state: GameState

    /// Services used for persistence and AI-backed generation.
    private let storageService: any StorageServiceProtocol
    private let wordService: any WordServiceProtocol
    private let hintService: any HintServiceProtocol
    private let imageService: any ImageServiceProtocol

    private let logger = Logger(subsystem: "com.imposter", category: "GameStore")

    /// Flag indicating if AI image generation is in progress
    private(set) var isGeneratingImage: Bool = false

    /// Flag indicating if AI word generation is in progress
    private(set) var isGeneratingWord: Bool = false

    /// Non-sensitive status for custom prompt word generation.
    private(set) var wordGenerationStatus: WordGenerationStatus = .idle

    /// Flag indicating if game is being prepared (word/image generation in progress before start)
    private(set) var isPreparingGame: Bool = false

    /// Error message to display as a toast (auto-clears after 4 seconds)
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init(
        state: GameState = GameState(),
        storageService: (any StorageServiceProtocol)? = nil,
        wordService: (any WordServiceProtocol)? = nil,
        hintService: (any HintServiceProtocol)? = nil,
        imageService: (any ImageServiceProtocol)? = nil
    ) {
        self.state = state
        self.storageService = storageService ?? StorageService()
        self.wordService = wordService ?? AIWordService()
        self.hintService = hintService ?? AIHintService()
        self.imageService = imageService ?? ImageService()

        loadSavedPlayers()
    }

    // MARK: - Error Display

    /// Shows an error toast that auto-dismisses after 4 seconds
    private func showError(_ message: String) {
        errorMessage = message
        Task {
            try? await Task.sleep(for: .seconds(4))
            if errorMessage == message {
                errorMessage = nil
            }
        }
    }

    // MARK: - Player Persistence

    /// Loads previously saved players from persistent storage.
    private func loadSavedPlayers() {
        do {
            guard let players = try storageService.loadPlayers(), !players.isEmpty else {
                return
            }

            state.players = players
            logger.debug("Loaded \(players.count) saved players")
        } catch {
            logger.error("Failed to load saved players: \(error.localizedDescription)")
        }
    }

    /// Saves current players to persistent storage.
    private func savePlayers() {
        do {
            guard !state.players.isEmpty else {
                storageService.delete(forKey: StorageKeys.lastPlayers)
                return
            }

            try storageService.savePlayers(state.players)
            logger.debug("Saved \(self.state.players.count) players")
        } catch {
            logger.error("Failed to save players: \(error.localizedDescription)")
            showError("Couldn't save players. Changes will stay available until the app closes.")
        }
    }

    // MARK: - Dispatch

    /// Dispatches an action to modify the game state.
    /// Validates phase transitions before applying changes.
    /// - Parameter action: The action to dispatch
    func dispatch(_ action: GameAction) {
        #if DEBUG
        logger.debug("Dispatching action: \(action.description)")
        #endif

        let newState = GameReducer.reduce(state: state, action: action)

        if newState.currentPhase != state.currentPhase {
            guard state.currentPhase.canTransition(to: newState.currentPhase) else {
                #if DEBUG
                logger.error("Invalid phase transition from \(self.state.currentPhase.rawValue) to \(newState.currentPhase.rawValue)")
                #endif
                return
            }
        }

        let phaseChanged = state.currentPhase != newState.currentPhase

        if newState.gameHistory.count > 50 {
            var capped = newState
            capped.gameHistory = Array(capped.gameHistory.suffix(50))
            state = capped
        } else {
            state = newState
        }

        if phaseChanged {
            AccessibilityAnnouncer.announcePhaseChange(state.currentPhase)
        }

        switch action {
        case .wordGenerationFailed(let error):
            showError("Word generation failed: \(error.message)")
        case .imageGenerationFailed(let error):
            showError("Image generation failed: \(error.message)")
        case .storageFailed(let error):
            showError("Storage error: \(error.message)")
        default:
            break
        }

        switch action {
        case .addPlayer, .removePlayer, .updatePlayer, .returnToHome, .resetGame:
            savePlayers()
        default:
            break
        }

        switch action {
        case .returnToHome, .resetGame:
            wordGenerationStatus = .idle
        default:
            break
        }

        handleSideEffects(for: action)
    }

    // MARK: - Prepare and Start Game

    /// Prepares the game by starting generation early, then dispatches startGame.
    func prepareAndStartGame() {
        startGame()
    }

    /// Starts the game through the store-owned round preparation pipeline.
    func startGame() {
        #if DEBUG
        logger.debug("startGame called - isPreparingGame: \(self.isPreparingGame), canStartGame: \(self.canStartGame), phase: \(self.state.currentPhase.rawValue)")
        #endif

        guard !isPreparingGame else {
            #if DEBUG
            logger.debug("Ignoring startGame because the game is already preparing")
            #endif
            return
        }

        guard currentPhase == .setup else {
            return
        }

        guard canStartGame else {
            #if DEBUG
            logger.debug("Ignoring startGame because the game cannot start in the current state")
            #endif
            return
        }

        beginRoundPreparation(for: .newGame)
    }

    /// Starts the next round through the store-owned round preparation pipeline.
    func startNewRound() {
        guard !isPreparingGame else {
            return
        }

        guard currentPhase == .summary else {
            return
        }

        beginRoundPreparation(for: .nextRound)
    }

    // MARK: - Side Effects

    /// Handles any side effects that should occur after state changes
    private func handleSideEffects(for action: GameAction) {
        switch action {
        case .startGame, .startNewRound, .startGameWithPreparedRound, .startNewRoundWithPreparedRound:
            if state.settings.wordSource == .customPrompt,
               let prompt = state.settings.customWordPrompt,
               !prompt.isEmpty {
                generateWordFromPrompt(prompt)
            } else if let word = state.roundState?.secretWord,
                      let category = state.roundState?.categoryHint {
                if state.settings.imposterHintEnabled {
                    generateImposterHint(for: word, category: category)
                }
                generateSecretImage(for: word, category: category)
            }

        default:
            break
        }
    }

    // MARK: - Round Preparation

    private enum PreparedRoundAction {
        case newGame
        case nextRound

        var expectedPhase: GamePhase {
            switch self {
            case .newGame:
                return .setup
            case .nextRound:
                return .summary
            }
        }
    }

    private func beginRoundPreparation(for action: PreparedRoundAction) {
        isPreparingGame = true
        wordGenerationStatus = .idle

        let players = state.players
        let settings = GameRules.normalized(state.settings)
        let avoidedWords = recentSecretWords()

        Task { @MainActor in
            let preparedRound = await prepareRoundState(
                players: players,
                settings: settings,
                avoiding: avoidedWords
            )

            defer {
                self.isPreparingGame = false
            }

            guard self.state.currentPhase == action.expectedPhase else {
                self.logger.debug("Skipping prepared round dispatch because the phase changed during preparation")
                return
            }

            switch action {
            case .newGame:
                self.dispatch(.startGameWithPreparedRound(preparedRound))
            case .nextRound:
                self.dispatch(.startNewRoundWithPreparedRound(preparedRound))
            }
        }
    }

    private func prepareRoundState(
        players: [Player],
        settings: GameSettings,
        avoiding avoidedWords: Set<String>
    ) async -> RoundState {
        let settings = GameRules.normalized(settings)
        let secretWord: String
        let imposterWord: String?
        let categoryHint = categoryHint(for: settings)

        if settings.wordSource == .customPrompt {
            secretWord = "GENERATING..."
            imposterWord = nil
        } else {
            secretWord = await selectRandomWord(using: settings, avoiding: avoidedWords)

            if settings.gameMode == .hidden {
                imposterWord = await selectAlternateImposterWord(
                    using: settings,
                    excluding: secretWord,
                    avoiding: avoidedWords
                )
            } else {
                imposterWord = nil
            }
        }

        guard let imposter = players.randomElement() else {
            return RoundState(
                secretWord: secretWord,
                imposterWord: imposterWord,
                categoryHint: categoryHint,
                imposterID: UUID(),
                firstPlayerIndex: 0
            )
        }

        let nonImposterIndices = players.indices.filter { players[$0].id != imposter.id }
        let firstPlayerIndex = nonImposterIndices.randomElement() ?? 0

        return RoundState(
            secretWord: secretWord,
            imposterWord: imposterWord,
            categoryHint: categoryHint,
            imposterID: imposter.id,
            firstPlayerIndex: firstPlayerIndex
        )
    }

    private func categoryHint(for settings: GameSettings) -> String {
        if settings.wordSource == .customPrompt {
            return settings.customWordPrompt ?? "Custom"
        }

        if let categories = settings.selectedCategories, !categories.isEmpty {
            return categories.joined(separator: ", ")
        }

        return "Mixed"
    }

    private func selectRandomWord(
        using settings: GameSettings,
        avoiding avoidedWords: Set<String> = []
    ) async -> String {
        do {
            return try await wordService.selectWord(
                from: settings.selectedCategories,
                difficulty: settings.wordPackDifficulty,
                avoiding: avoidedWords
            )
        } catch {
            logger.error("Failed to select a round word: \(error.localizedDescription)")
            showError("Couldn't prepare the round word. Using a fallback.")
            return "UNKNOWN"
        }
    }

    private func selectAlternateImposterWord(
        using settings: GameSettings,
        excluding secretWord: String,
        avoiding avoidedWords: Set<String>
    ) async -> String? {
        do {
            return try await wordService.selectAlternateWord(
                matching: secretWord,
                from: settings.selectedCategories,
                difficulty: settings.wordPackDifficulty,
                avoiding: avoidedWords
            )
        } catch {
            logger.error("Failed to prepare hidden-mode imposter word: \(error.localizedDescription)")
            return nil
        }
    }

    private func recentSecretWords() -> Set<String> {
        Set(state.gameHistory.suffix(Self.recentWordAvoidanceLimit).map(\.secretWord))
    }

    // MARK: - AI Word Generation

    /// Generates a word from the prompt using the injected word service.
    private func generateWordFromPrompt(_ prompt: String) {
        guard !isGeneratingWord else { return }
        isGeneratingWord = true
        wordGenerationStatus = .generating

        Task {
            await performWordGeneration(from: prompt)
        }
    }

    /// Performs word generation using the injected word service with a 15-second timeout.
    private func performWordGeneration(from prompt: String) async {
        var finalWord: String
        let avoidedWords = recentSecretWords()

        do {
            let generatedWord = try await withThrowingTaskGroup(of: String.self) { group in
                group.addTask {
                    try await self.wordService.generateWord(from: prompt)
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(15))
                    throw CancellationError()
                }

                guard let result = try await group.next() else {
                    throw CancellationError()
                }

                group.cancelAll()
                return result
            }

            finalWord = await freshGeneratedWord(
                generatedWord,
                prompt: prompt,
                avoiding: avoidedWords
            )
            logger.debug("Generated word '\(finalWord)' from prompt '\(prompt)'")
        } catch {
            logger.error("Word generation failed: \(error.localizedDescription)")
            wordGenerationStatus = .fallback(.generationFailed)
            finalWord = await fallbackWordForGeneratedPrompt(
                prompt,
                avoiding: avoidedWords
            )
            showError("Word generation timed out. Using a pack word instead.")
        }

        let generatedImposterWord = await generatedImposterWordIfNeeded(
            for: finalWord,
            prompt: prompt,
            avoiding: avoidedWords
        )

        dispatch(.setGeneratedWord(word: finalWord, imposterWord: generatedImposterWord))
        isGeneratingWord = false

        let category = state.settings.customWordPrompt ?? "Custom"
        if state.settings.imposterHintEnabled {
            generateImposterHint(for: finalWord, category: category)
        }

        generateSecretImage(for: finalWord, category: category)
    }

    private func freshGeneratedWord(
        _ generatedWord: String,
        prompt: String,
        avoiding avoidedWords: Set<String>
    ) async -> String {
        let generatedKey = WordSelector.normalizedWordKey(generatedWord)
        let avoidedKeys = Set(avoidedWords.map(WordSelector.normalizedWordKey))

        guard !avoidedKeys.contains(generatedKey) else {
            logger.info("Generated word repeated recent history; using pack fallback")
            wordGenerationStatus = .fallback(.duplicateRecentWord)
            return await fallbackWordForGeneratedPrompt(
                prompt,
                avoiding: avoidedWords.union([generatedWord])
            )
        }

        let blockedWords = avoidedWords.union([prompt])
        guard WordSelector.isPlayableDistinctWord(generatedWord, from: blockedWords) else {
            logger.info("Generated word was too close to prompt or recent history; using pack fallback")
            wordGenerationStatus = .fallback(.nearDuplicateWord)
            return await fallbackWordForGeneratedPrompt(
                prompt,
                avoiding: avoidedWords.union([generatedWord])
            )
        }

        wordGenerationStatus = .generated
        return generatedWord
    }

    private func fallbackWordForGeneratedPrompt(
        _ prompt: String,
        avoiding avoidedWords: Set<String>
    ) async -> String {
        await selectRandomWord(
            using: state.settings,
            avoiding: avoidedWords.union([prompt])
        )
    }

    private func generatedImposterWordIfNeeded(
        for secretWord: String,
        prompt: String,
        avoiding avoidedWords: Set<String>
    ) async -> String? {
        guard state.settings.gameMode == .hidden else {
            return nil
        }

        do {
            return try await wordService.selectAlternateWord(
                matching: secretWord,
                from: state.settings.selectedCategories,
                difficulty: state.settings.wordPackDifficulty,
                avoiding: avoidedWords.union([prompt])
            )
        } catch {
            logger.error("Failed to prepare custom-prompt hidden decoy: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - AI Hint Generation

    /// Generates an AI hint for the imposter
    private func generateImposterHint(for word: String, category: String) {
        Task {
            await performHintGeneration(for: word, category: category)
        }
    }

    /// Performs hint generation using the injected hint service.
    private func performHintGeneration(for word: String, category: String) async {
        do {
            let hint = try await hintService.generateHint(for: word, category: category)
            logger.debug("Generated imposter hint for '\(word)'")
            dispatch(.setImposterHint(hint: hint))
        } catch {
            logger.error("Hint generation failed: \(error.localizedDescription)")
            dispatch(.setImposterHint(hint: category))
        }
    }

    // MARK: - AI Image Generation

    /// Generates an AI image for the secret word using the injected image service.
    private func generateSecretImage(for word: String, category: String) {
        guard !isGeneratingImage else { return }
        isGeneratingImage = true

        Task {
            await performImageGeneration(for: word, category: category)
        }
    }

    /// Performs the actual image generation using the injected service.
    private func performImageGeneration(for word: String, category: String) async {
        do {
            guard imageService.isAvailable else {
                logger.debug("Skipping image generation because the service is unavailable: \(self.imageService.unavailabilityReason ?? "unknown")")
                isGeneratingImage = false
                return
            }

            let generatedImage = try await imageService.generateImage(
                for: word,
                category: category,
                style: nil
            )

            if let generatedImage {
                dispatch(.setGeneratedImage(generatedImage))
            }
        } catch {
            logger.error("Image generation failed: \(error.localizedDescription)")
        }

        isGeneratingImage = false
    }

    // MARK: - Derived Properties

    /// The player whose turn it is to give a clue
    var currentClueGiver: Player? {
        state.currentClueGiver
    }

    /// The first player to give a clue this round
    var firstClueGiver: Player? {
        state.firstClueGiver
    }

    /// Whether a given player is the imposter
    func isImposter(_ playerID: UUID) -> Bool {
        state.roundState?.imposterID == playerID
    }

    /// The current imposter player
    var imposter: Player? {
        state.imposter
    }

    /// Whether we can start the game
    var canStartGame: Bool {
        state.canStartGame
    }

    /// The secret word for the current round
    var secretWord: String? {
        state.roundState?.secretWord
    }

    /// Current game phase
    var currentPhase: GamePhase {
        state.currentPhase
    }

    /// All players in the game
    var players: [Player] {
        state.players
    }

    /// Current game settings
    var settings: GameSettings {
        state.settings
    }

    /// Current round number
    var roundNumber: Int {
        state.roundNumber
    }

    /// Game history
    var gameHistory: [CompletedRound] {
        state.gameHistory
    }

    /// All clues given in the current round
    var clues: [RoundState.Clue] {
        state.roundState?.clues ?? []
    }

    /// All votes cast in the current round
    var votes: [UUID: UUID] {
        state.roundState?.votes ?? [:]
    }

    /// Whether all clues have been given
    var allCluesGiven: Bool {
        state.allCluesGiven
    }

    /// Whether all votes have been cast
    var allVotesCast: Bool {
        state.allVotesCast
    }

    /// The generated image for the current round (if any)
    var generatedImage: UIImage? {
        state.roundState?.generatedImage
    }

    // MARK: - Convenience Methods

    /// Adds a new player with the next available color
    func addNewPlayer(name: String) {
        let usedColors = state.players.map { $0.color }
        let color = PlayerColor.nextAvailable(excluding: usedColors)
        dispatch(.addPlayer(name: name, color: color))
    }

    /// Gets the vote count for a specific player
    func voteCount(for playerID: UUID) -> Int {
        guard let round = state.roundState else { return 0 }
        return round.votes.values.filter { $0 == playerID }.count
    }

    /// Gets the player who a specific player voted for
    func votedFor(by voterID: UUID) -> Player? {
        guard let suspectID = state.roundState?.votes[voterID] else { return nil }
        return state.players.first { $0.id == suspectID }
    }
}

// MARK: - Preview Support

extension GameStore {
    /// Creates a store with sample data for previews
    static var preview: GameStore {
        let environment = AppEnvironment.preview()
        let store = environment.makeGameStore()

        store.dispatch(.addPlayer(name: "Alice", color: .crimson))
        store.dispatch(.addPlayer(name: "Bob", color: .azure))
        store.dispatch(.addPlayer(name: "Charlie", color: .emerald))
        store.dispatch(.addPlayer(name: "Diana", color: .amber))

        return store
    }

    /// Creates a store in the clue round phase for previews
    static var previewInGame: GameStore {
        let store = preview
        store.startGame()
        store.dispatch(.completeRoleReveal)
        return store
    }
}
