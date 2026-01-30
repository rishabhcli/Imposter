//
//  GameStore.swift
//  Imposter
//
//  Observable store with dispatch() for unidirectional data flow.
//

import Foundation
import ImagePlayground
import Observation
import UIKit

// MARK: - GameStore

/// Central store for game state management.
/// Provides a dispatch() method for unidirectional data flow.
@Observable
@MainActor
final class GameStore {

    // MARK: - Properties

    /// The current game state
    private(set) var state: GameState

    /// Flag indicating if AI image generation is in progress
    private(set) var isGeneratingImage: Bool = false

    /// Flag indicating if AI word generation is in progress
    private(set) var isGeneratingWord: Bool = false

    /// Flag indicating if game is being prepared (word/image generation in progress before start)
    private(set) var isPreparingGame: Bool = false

    /// UserDefaults key for persisted players
    private static let playersKey = "savedPlayers"

    // MARK: - Initialization

    init(state: GameState = GameState()) {
        self.state = state
        // Load saved players on init
        loadSavedPlayers()
    }

    // MARK: - Player Persistence

    /// Loads previously saved players from UserDefaults
    private func loadSavedPlayers() {
        guard let data = UserDefaults.standard.data(forKey: Self.playersKey),
              let players = try? JSONDecoder().decode([Player].self, from: data),
              !players.isEmpty else {
            return
        }

        // Reset scores for loaded players (fresh game)
        let resetPlayers = players.map { player in
            Player(
                id: player.id,
                name: player.name,
                color: player.color,
                emoji: player.emoji,
                score: 0,
                isEliminated: false
            )
        }

        state.players = resetPlayers

        #if DEBUG
        print("GameStore: Loaded \(resetPlayers.count) saved players")
        #endif
    }

    /// Saves current players to UserDefaults
    private func savePlayers() {
        guard !state.players.isEmpty else {
            UserDefaults.standard.removeObject(forKey: Self.playersKey)
            return
        }

        if let data = try? JSONEncoder().encode(state.players) {
            UserDefaults.standard.set(data, forKey: Self.playersKey)

            #if DEBUG
            print("GameStore: Saved \(state.players.count) players")
            #endif
        }
    }

    // MARK: - Dispatch

    /// Dispatches an action to modify the game state.
    /// Validates phase transitions before applying changes.
    /// - Parameter action: The action to dispatch
    func dispatch(_ action: GameAction) {
        // Log the action for debugging
        #if DEBUG
        print("GameStore: Dispatching \(action)")
        #endif

        // Compute new state using the reducer
        let newState = GameReducer.reduce(state: state, action: action)

        // Validate phase transitions
        if newState.currentPhase != state.currentPhase {
            guard state.currentPhase.canTransition(to: newState.currentPhase) else {
                #if DEBUG
                print("GameStore: Invalid phase transition from \(state.currentPhase) to \(newState.currentPhase)")
                #endif
                return
            }
        }

        // Apply the new state
        let phaseChanged = state.currentPhase != newState.currentPhase
        state = newState

        // Announce phase change for VoiceOver
        if phaseChanged {
            AccessibilityAnnouncer.announcePhaseChange(state.currentPhase)
        }

        // Save players when they change
        switch action {
        case .addPlayer, .removePlayer, .updatePlayer, .returnToHome, .resetGame:
            savePlayers()
        default:
            break
        }

        // Handle side effects after state update
        handleSideEffects(for: action)
    }

    // MARK: - Prepare and Start Game

    /// Prepares the game by starting generation early, then dispatches startGame.
    func prepareAndStartGame() {
        #if DEBUG
        print("GameStore: prepareAndStartGame called - isPreparingGame: \(isPreparingGame), canStartGame: \(canStartGame), phase: \(state.currentPhase)")
        #endif

        guard !isPreparingGame else {
            #if DEBUG
            print("GameStore: Already preparing, returning")
            #endif
            return
        }
        guard canStartGame else {
            #if DEBUG
            print("GameStore: Cannot start game, returning")
            #endif
            return
        }

        isPreparingGame = true

        // Dispatch startGame - this changes phase and triggers side effects
        dispatch(.startGame)

        #if DEBUG
        print("GameStore: After dispatch, phase is: \(state.currentPhase)")
        #endif

        // Reset preparing flag after a brief delay
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            isPreparingGame = false
        }
    }

    // MARK: - Side Effects

    /// Handles any side effects that should occur after state changes
    private func handleSideEffects(for action: GameAction) {
        switch action {
        case .startGame, .startNewRound:
            // FEATURE 1: AI Word Generation (only when using custom prompt)
            // Generates a RELATED word from the user's prompt
            if state.settings.wordSource == .customPrompt,
               let prompt = state.settings.customWordPrompt,
               !prompt.isEmpty {
                generateWordFromPrompt(prompt)
            } else {
                // For random pack mode, generate hint and image right away
                if let word = state.roundState?.secretWord,
                   let category = state.roundState?.categoryHint {
                    // Generate imposter hint (if enabled)
                    if state.settings.imposterHintEnabled {
                        generateImposterHint(for: word, category: category)
                    }
                    // Generate image
                    generateSecretImage(for: word, category: category)
                }
            }

        default:
            break
        }
    }

    // MARK: - AI Word Generation

    /// Generates a word from the prompt using Foundation Models
    private func generateWordFromPrompt(_ prompt: String) {
        guard !isGeneratingWord else { return }
        isGeneratingWord = true

        Task {
            await performWordGeneration(from: prompt)
        }
    }

    /// Performs word generation using Foundation Models
    private func performWordGeneration(from prompt: String) async {
        var finalWord: String

        do {
            // Generate a related word using Foundation Models
            let generatedWord = try await WordGenerator.generateWord(from: prompt)

            #if DEBUG
            print("WordGenerator: Generated '\(generatedWord)' from prompt '\(prompt)'")
            #endif

            finalWord = generatedWord

        } catch {
            #if DEBUG
            print("WordGenerator failed: \(error.localizedDescription)")
            #endif

            // Fallback: use the prompt itself as the word
            finalWord = prompt.capitalized
        }

        // Update the secret word in the state
        dispatch(.setGeneratedWord(word: finalWord))
        isGeneratingWord = false

        // Generate imposter hint (if enabled)
        let category = state.settings.customWordPrompt ?? "Custom"
        if state.settings.imposterHintEnabled {
            generateImposterHint(for: finalWord, category: category)
        }

        // Generate image for the word (separate feature, runs independently)
        generateSecretImage(for: finalWord, category: category)
    }

    // MARK: - AI Hint Generation

    /// Generates an AI hint for the imposter
    private func generateImposterHint(for word: String, category: String) {
        Task {
            await performHintGeneration(for: word, category: category)
        }
    }

    /// Performs hint generation using Foundation Models
    private func performHintGeneration(for word: String, category: String) async {
        do {
            let hint = try await HintGenerator.generateHint(for: word, category: category)

            #if DEBUG
            print("HintGenerator: Generated hint for '\(word)': \(hint)")
            #endif

            dispatch(.setImposterHint(hint: hint))

        } catch {
            #if DEBUG
            print("HintGenerator failed: \(error.localizedDescription)")
            #endif
            // No fallback - just use category as hint
            dispatch(.setImposterHint(hint: category))
        }
    }

    // MARK: - AI Image Generation

    /// Generates an AI image for the secret word using ImagePlayground
    private func generateSecretImage(for word: String, category: String) {
        guard !isGeneratingImage else { return }
        isGeneratingImage = true

        Task {
            await performImageGeneration(for: word, category: category)
        }
    }

    /// Performs the actual image generation off the main actor
    private nonisolated func performImageGeneration(for word: String, category: String) async {
        do {
            // Initialize the ImagePlayground image creator
            // This may throw if the device doesn't support image generation
            let creator = try await ImageCreator()

            // Check available styles and select the best one for a party game
            // Prefer illustration, then animation, then sketch, then first available
            let style: ImagePlaygroundStyle
            let availableStyles = creator.availableStyles

            if availableStyles.contains(.illustration) {
                style = .illustration
            } else if availableStyles.contains(.animation) {
                style = .animation
            } else if availableStyles.contains(.sketch) {
                style = .sketch
            } else if let firstStyle = availableStyles.first {
                style = firstStyle
            } else {
                #if DEBUG
                print("ImagePlayground: No styles available")
                #endif
                await MainActor.run {
                    self.isGeneratingImage = false
                }
                return
            }

            // Create concept from the secret word
            // Use category-safe prompts to avoid people/IP restrictions
            let imagePrompt = Self.safeImagePrompt(for: word, category: category)
            let concepts: [ImagePlaygroundConcept] = [.text(imagePrompt)]

            #if DEBUG
            print("ImagePlayground: Generating image with prompt: '\(imagePrompt)'")
            #endif

            // Request images with the selected style
            let imageSequence = creator.images(
                for: concepts,
                style: style,
                limit: 1
            )

            // Process the async sequence and get the first image
            for try await generatedImage in imageSequence {
                let uiImage = UIImage(cgImage: generatedImage.cgImage)

                #if DEBUG
                print("ImagePlayground: Successfully generated image")
                #endif

                // Update state on main actor - properly handle optional struct mutation
                await MainActor.run { [uiImage] in
                    if var roundState = self.state.roundState {
                        roundState.generatedImage = uiImage
                        self.state.roundState = roundState
                    }
                    self.isGeneratingImage = false
                }

                // Only need the first image
                return
            }

            // If no images were generated, clear the loading state
            await MainActor.run {
                #if DEBUG
                print("ImagePlayground: No images generated")
                #endif
                self.isGeneratingImage = false
            }
        } catch {
            // Log error but don't crash - game continues without image
            #if DEBUG
            print("ImagePlayground generation failed: \(error.localizedDescription)")
            #endif

            await MainActor.run {
                self.isGeneratingImage = false
            }
        }
    }

    /// Creates a safe image prompt that avoids people/IP restrictions
    /// Falls back to category-themed abstract imagery if needed
    private nonisolated static func safeImagePrompt(for word: String, category: String) -> String {
        // Categories that might have people or IP issues
        let sensitiveCategories = ["People", "Movies", "Music", "Sports"]

        if sensitiveCategories.contains(category) {
            // Use abstract/symbolic imagery instead
            switch category {
            case "People":
                return "An abstract silhouette with colorful aura, mysterious figure concept art"
            case "Movies":
                return "A vintage movie camera with film reels, cinema lights, popcorn, dramatic spotlight"
            case "Music":
                return "Musical notes floating in colorful waves, instruments in abstract style"
            case "Sports":
                return "Abstract sports equipment composition, dynamic motion lines, energetic colors"
            default:
                return "Colorful abstract shapes representing: \(category)"
            }
        }

        // Safe categories - use the actual word
        return "A colorful, fun illustration of: \(word)"
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

    /// Players sorted by score
    var leaderboard: [Player] {
        state.leaderboard
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
        let store = GameStore()

        // Add sample players
        store.dispatch(.addPlayer(name: "Alice", color: .crimson))
        store.dispatch(.addPlayer(name: "Bob", color: .azure))
        store.dispatch(.addPlayer(name: "Charlie", color: .emerald))
        store.dispatch(.addPlayer(name: "Diana", color: .amber))

        return store
    }

    /// Creates a store in the clue round phase for previews
    static var previewInGame: GameStore {
        let store = preview
        store.dispatch(.startGame)
        store.dispatch(.completeRoleReveal)
        return store
    }
}
