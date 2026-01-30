Imposter Game – iOS 26+ Implementation Plan (Native SwiftUI, Liquid Glass Design)

Executive Summary:
This document outlines a comprehensive plan to implement Imposter, a local-only social deduction party game for iPhone/iPad (3–10 players, pass-and-play). The app targets iOS 26.0+ with SwiftUI and Apple’s new Liquid Glass design system. It uses modern Swift 6 concurrency, the Observation framework, and on-device AI features introduced in iOS 26 (Apple Foundation Models). No networking or Game Center – all gameplay is on one shared device. The core mechanic: one player is secretly the “Imposter” who doesn’t know the secret word; players give clues and vote to identify the Imposter.

1. Technical Requirements & Platform

1.1 Development Environment
	•	Xcode: Use Xcode 26 (or later) with the iOS 26 SDK . This ensures access to new APIs like .glassEffect and Foundation Models.
	•	Swift: Swift 6 (enable strict concurrency checking).
	•	Deployment Target: iOS 26.0 minimum (app will run on iOS 26 and above).
	•	Frameworks:
	•	SwiftUI + Observation: For UI and state management.
	•	Liquid Glass Design System: Adopt Apple’s iOS 26 visual language for UI materials and components  .
	•	FoundationModels & ImagePlayground: Utilize Apple’s on-device generative AI for optional word/image generation (iOS 26 feature).
	•	Architecture: Use SwiftUI’s unidirectional data flow (inspired by Redux/TCA) with @Observable objects.

1.2 Key iOS 26 Features to Research and Leverage
	•	Liquid Glass Design: Study Apple’s docs on Liquid Glass material – translucency, depth, and adaptive visuals  . Key topics: material variants (.regular, .clear), lensing effects, and semantic color usage. Liquid Glass controls reflect surroundings and adapt automatically between light/dark modes .
	•	Material & Animation Guidelines: Review iOS 26 Human Interface Guidelines for Liquid Glass: appropriate use of transparency, motion “liquid physics” animations, and interactive behaviors (e.g. bouncy spring animations in SwiftUI).
	•	Observation Framework Enhancements: iOS 26.2 improved the Observation API. Research @Observable macro details and performance best practices for fine-grained view updates.
	•	SwiftUI New APIs (iOS 26): Understand updated state management, new navigation patterns (e.g. NavigationStack as used), new SwiftUI controls (like .glass buttonStyle), and accessibility improvements.
	•	Swift 6 Concurrency: Follow the Swift 6 strict concurrency migration guide – actor isolation rules, Sendable requirements, and use of @MainActor for UI updates.
	•	Foundation Models (AI on-device): Investigate Apple’s FoundationModels framework . iOS 26 provides a large on-device language model for text generation (via SystemLanguageModel) and an image generation API via ImagePlayground . We will use these for an optional feature where the user can input a prompt to generate a custom secret word and image. Ensure to review Apple’s documentation on the ImagePlayground framework (specifically the ImageCreator class and ImagePlaygroundViewController UI) .

1.3 Project Configuration
	•	Project Setup:
	•	Set platform in Package manifest or project settings: .iOS(.v26) (iOS 26.0).
	•	Enable Swift 6 and set Strict Concurrency Checking to complete in build settings.
	•	Add the ImagePlayground.framework to the project (in Xcode’s Frameworks & Libraries) to access image generation APIs. This framework is available on iOS 26+ .
	•	Build Settings:
	•	Deployment Target: iOS 26.0.
	•	Bitcode: Disabled (bitcode is deprecated as of Xcode 14+).
	•	Enable SwiftUI live previews (run in iOS 26 simulator for accurate rendering of Liquid Glass).
	•	Info.plist:
	•	UIRequiredDeviceCapabilities: Ensure it doesn’t restrict devices (game should run on all devices supporting iOS 26).
	•	LSApplicationCategoryType: Set to public.app-category.games.
	•	Privacy usage descriptions: Not strictly needed since no camera/mic/etc. are used (local-only gameplay), but include generic placeholders (e.g. in case future enhancements use haptics or notifications).
	•	Confirm on-device AI usage does not require special entitlements – FoundationModels are available to all developers on iOS 26 (just ensure the framework is linked).

2. Architecture & Design Patterns

2.1 Architecture Overview

We will use a unidirectional data flow pattern with a central game store, similar to Redux/TCA but leveraging Swift concurrency and Observation. The core loop:
User Action → GameStore.dispatch(action) → Reducer (pure function computes new state) → GameState updated → SwiftUI views automatically update (Observation publishes changes).

Key principles:
	•	Single Source of Truth: A single GameState object (within GameStore) holds all game data (players, current phase, settings, etc.).
	•	Pure Reducers: State transitions are handled in pure functions (no side effects), making logic predictable and testable.
	•	State Machine for Phases: Use an enum for game phase (GamePhase) that controls allowed transitions. This prevents invalid flows (e.g. cannot go to voting before clues phase is done).
	•	Value Types for Models: Use structs for models like Player, RoundState for safety and easier copying. Use Sendable conformance to satisfy Swift concurrency.
	•	@Observable for Store: Use SwiftUI’s Observation framework (@Observable on GameStore and on the GameState class) to automatically notify SwiftUI views on state changes, avoiding manual ObservableObject boilerplate. This should provide more granular updates and better performance in SwiftUI (as recommended for iOS 26)  .
	•	MainActor Isolation: Constrain UI-related state updates to run on the main thread using @MainActor on the store to avoid threading issues with SwiftUI.

2.2 Module Structure

Organize code by feature and domain, using SwiftPM or Xcode groups. The structure:

Imposter/  
├── App/  
│   ├── ImposterApp.swift        // @main, configures GameStore environment  
│   └── AppEnvironment.swift     // Dependency injection container if needed (for testing)  
├── Domain/  
│   ├── Models/  
│   │   ├── GameState.swift      // Central state container (@Observable class)  
│   │   ├── Player.swift         // Player model  
│   │   ├── RoundState.swift     // Per-round mutable state (clues, votes)  
│   │   ├── GamePhase.swift      // Enum of phases with state machine logic  
│   │   └── GameSettings.swift   // Configurable game rules and options  
│   ├── Actions/  
│   │   └── GameAction.swift     // Enum of all possible user or system actions  
│   └── Logic/  
│       ├── GameReducer.swift    // Reducer functions for each action  
│       ├── WordSelector.swift   // Word selection logic (random from packs or AI)  
│       └── ScoringEngine.swift  // Points calculation logic  
├── Store/  
│   └── GameStore.swift          // @Observable store with dispatch()  
├── Features/  
│   ├── Home/  
│   │   ├── HomeView.swift       // Start screen UI  
│   │   └── HowToPlaySheet.swift // (If needed, tutorial overlay)  
│   ├── Setup/  
│   │   ├── PlayerSetupView.swift    // Add players, choose settings (categories, AI or not)  
│   │   ├── PlayerRowView.swift      // Subview for each player in list  
│   │   └── SettingsSheet.swift      // Modal for game settings (difficulty, timers, etc.)  
│   ├── RoleReveal/  
│   │   ├── RoleRevealView.swift     // Pass-and-play role reveal instructions  
│   │   └── RoleCardView.swift       // Card showing word or imposter role (Liquid Glass design)  
│   ├── ClueRound/  
│   │   ├── ClueRoundView.swift      // Main view during clue-giving rounds  
│   │   ├── ClueInputView.swift      // TextField for entering a clue  
│   │   └── ClueHistoryList.swift    // List of clues given so far  
│   ├── Voting/  
│   │   ├── DiscussionView.swift     // (Optional) discussion timer UI  
│   │   ├── VotingView.swift         // Pass-and-play voting screen  
│   │   └── PlayerSelectionGrid.swift// Grid of players for vote selection  
│   ├── Reveal/  
│   │   ├── RevealView.swift         // Reveal results (who was imposter, outcome)  
│   │   └── RevealAnimationView.swift// Fancy animation for revealing imposter  
│   └── Summary/  
│       ├── SummaryView.swift        // Final scoreboard and winner  
│       └── ScoreboardRow.swift      // Row view for each player’s score  
├── DesignSystem/  
│   ├── LiquidGlass/  
│   │   ├── LGColors.swift          // Color tokens (semantic colors for Liquid Glass)  
│   │   ├── LGTypography.swift      // Typography scale (fonts, dynamic type)  
│   │   ├── LGSpacing.swift         // Spacing constants  
│   │   ├── LGMaterials.swift       // Material effects (glass materials, shadows, elevations)  
│   │   └── LGComponents/           // Reusable UI components styled for Liquid Glass  
│   │       ├── LGButton.swift      // Custom button style (if not using .glass style directly)  
│   │       ├── LGCard.swift        // Card container view with glass background  
│   │       ├── LGTextField.swift   // TextField styling if needed  
│   │       └── LGBadge.swift       // Badge view (for winner indicator, etc.)  
│   └── Extensions/  
│       ├── View+Extensions.swift   // View modifiers common to design system  
│       └── Color+Extensions.swift  // Helpers for Color (e.g. init from hex or dynamic)  
├── Resources/  
│   ├── WordPacks/  
│   │   ├── words_animals.json     // Example word pack by category (Animals)  
│   │   ├── words_technology.json  // (Technology)  
│   │   ├── words_objects.json     // (Everyday Objects)  
│   │   ├── words_people.json      // (Famous People? Or generic names)  
│   │   └── words_movies.json      // (Movie titles or characters, if appropriate)  
│   └── Localizable.xcstrings      // String Catalog for localization (iOS 26 feature)  
└── Utilities/  
    ├── HapticManager.swift        // Wrapper for haptic feedback (UI feedback vibrations)  
    └── AccessibilityIDs.swift     // Constants for UI test identifiers  

Note: Word packs are organized by category rather than difficulty now (see Section 7). The user can select one or multiple categories for the secret word, or opt to enter a custom prompt for AI generation.

2.3 State Machine Design (GamePhase)

Use a GamePhase enum to encode the game’s finite state machine. Each phase corresponds to a screen/feature and only certain transitions are valid. For example:

enum GamePhase: String, Codable, CaseIterable {
    case setup       // Player configuration
    case roleReveal  // Secret word reveal to each player
    case clueRound   // Players give clues in turn
    case discussion  // Open discussion phase (optional timer)
    case voting      // Cast votes for Imposter
    case reveal      // Reveal Imposter and results
    case summary     // Final scoreboard / game over

    func canTransition(to next: GamePhase) -> Bool {
        switch (self, next) {
        case (.setup, .roleReveal),
             (.roleReveal, .clueRound),
             (.clueRound, .discussion), 
             (.clueRound, .voting),       // If skipping discussion
             (.discussion, .voting),
             (.voting, .reveal),
             (.reveal, .summary),
             (.summary, .roleReveal),     // Next round
             (.summary, .setup):          // Or restart to setup
            return true
        default:
            return false
        }
    }
}

This ensures the game flows in order. The Reducer will check currentPhase.canTransition(to: newPhase) for actions that advance the phase and ignore or throw an error for invalid transitions.

Research: Finite state machine patterns in Swift (e.g., an enum with transitions) can guide this implementation  . We’ll also consider using Swift’s strong typing to enforce some of this (for example, using associated values if needed for phase-specific data).

3. Data Models (Domain Layer)

3.1 Core Models
	•	Player: Represents a participant.

struct Player: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var color: PlayerColor   // Predefined color for this player’s avatar or indicator
    var score: Int
    var isEliminated: Bool   // for multi-round elimination modes, if any

    init(name: String, color: PlayerColor) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.score = 0
        self.isEliminated = false
    }
}

PlayerColor is an enum for a fixed palette of distinct colors (crimson, azure, emerald, etc.) to visually distinguish players. We will map these to actual UI colors in our design system (matching Liquid Glass vibrant accent colors).

enum PlayerColor: String, Codable, CaseIterable, Sendable {
    case crimson, azure, emerald, amber, violet, coral, teal, rose
    var liquidGlassToken: Color {
        // Map to an actual Color in LGColors, e.g. crimson -> LGColors.playerRed
        switch self {
           case .crimson: return LGColors.accentPrimary   // example mapping
           // ... other cases
        }
    }
}

	•	GameState: Central game state, observable.

@Observable
final class GameState: Sendable {
    var players: [Player]
    var settings: GameSettings
    var currentPhase: GamePhase
    var roundState: RoundState?    // Non-nil when a game round is in progress (after startGame)
    var roundNumber: Int
    var gameHistory: [CompletedRound]  // Records of finished rounds (if playing multiple rounds)

    init(players: [Player] = [], settings: GameSettings = .default) {
        self.players = players
        self.settings = settings
        self.currentPhase = .setup
        self.roundNumber = 0
        self.gameHistory = []
    }
}

CompletedRound would be a struct capturing the outcome of a round (could include who was imposter, who was voted, etc., and is used to show history in the summary). We won’t detail it here for brevity.
	•	RoundState: Tracks state for the current round in progress. It includes the secret word, who the imposter is, clues given, and votes.

struct RoundState: Codable, Sendable {
    let secretWord: String
    let imposterID: UUID         // Player.id of the Imposter
    var clues: [Clue]
    var votes: [UUID: UUID]      // Mapping voterID -> suspectID
    var currentClueIndex: Int    // How many clues have been given so far (to manage turn order)

    struct Clue: Codable, Identifiable, Sendable {
        let id: UUID
        let playerID: UUID
        let text: String
        let timestamp: Date
        let roundIndex: Int      // Which round of clues (0 for first go-around, 1 for second, etc.)
    }
}

	•	GameSettings: Configurable parameters for the game, including word selection options and timers/scores.

struct GameSettings: Codable, Sendable {
    enum Difficulty: String, Codable, CaseIterable { case easy, medium, hard, mixed }
    enum WordSource: String, Codable { case randomPack, customPrompt }

    // Word Selection
    var wordSource: WordSource              // Use random from packs or custom prompt
    var selectedCategories: [String]?       // Which categories to draw words from (nil = all)
    var wordPackDifficulty: Difficulty      // Difficulty level for word pack (if using packs)
    var customWordPrompt: String?           // User-provided prompt for AI (if wordSource == .customPrompt)

    // Rounds configuration
    var numberOfClueRounds: Int             // How many times around for clues
    var discussionTimerEnabled: Bool
    var discussionSeconds: Int
    var votingTimerEnabled: Bool
    var votingSeconds: Int
    var allowImposterWordGuess: Bool       // Whether imposter gets a chance to guess the word at the end

    // Scoring
    var pointsForCorrectVote: Int
    var pointsForImposterSurvival: Int
    var pointsForImposterGuess: Int

    static let `default` = GameSettings(
        wordSource: .randomPack,
        selectedCategories: nil,
        wordPackDifficulty: .medium,
        customWordPrompt: nil,
        numberOfClueRounds: 2,
        discussionTimerEnabled: false,
        discussionSeconds: 60,
        votingTimerEnabled: false,
        votingSeconds: 30,
        allowImposterWordGuess: true,
        pointsForCorrectVote: 1,
        pointsForImposterSurvival: 2,
        pointsForImposterGuess: 3
    )
}

Categories: The user can pick specific categories (e.g. Animals, Technology, Movies, etc.) from which the secret word will be drawn. If selectedCategories is non-nil, the WordSelector will restrict random word selection to those categories. If multiple categories are selected, it will combine their word lists. If none selected (or nil), it uses all categories by default.

AI Prompt: If wordSource is .customPrompt, the game will use customWordPrompt as the basis for the secret word. In this mode, instead of randomly picking a word, we will use the prompt directly as the secret word (assuming the user enters a single word or short phrase), and also generate an illustrative image for that word using Apple’s Foundation Models (see Section 7.3).

3.2 Actions (GameAction) Enum

Define all possible actions that can change state. This includes user-initiated events and internal state transitions.

enum GameAction: Sendable {
    // Setup Phase actions
    case addPlayer(name: String, color: PlayerColor)
    case removePlayer(id: UUID)
    case updatePlayer(id: UUID, name: String, color: PlayerColor)
    case updateSettings(GameSettings)      // e.g., changing difficulty, categories
    case startGame                         // Begin the game (moves from setup to roleReveal)

    // Role Reveal Phase
    case revealRoleToPlayer(id: UUID)      // Mark that a given player has viewed their role
    case completeRoleReveal                // All players have seen their role

    // Clue Round Phase
    case submitClue(playerID: UUID, text: String)
    case advanceToNextClue                 // Move to next player’s clue turn
    case completeClueRounds                // All required clues have been given

    // Discussion & Voting Phase
    case startDiscussion
    case endDiscussion                     // (if timed discussion ends early)
    case startVoting
    case castVote(voterID: UUID, suspectID: UUID)
    case completeVoting

    // Reveal Phase
    case revealImposter                    // Trigger reveal of imposter identity
    case imposterGuessWord(guess: String)  // Imposter attempts to guess the secret word (if allowed)
    case completeRound                     // Conclude round, compute scores

    // Summary/Reset
    case startNewRound                     // Play another round with same players
    case endGame                           // End game entirely
    case returnToHome                      // Back to home screen
}

Each action will be handled in the reducer to update GameState. Some actions simply update data (e.g. addPlayer appends a player), others trigger phase transitions (startGame changes phase and initializes a new round).

4. State Management (Store Layer)

4.1 GameStore Implementation

The GameStore holds the GameState and exposes a dispatch function. By marking it @Observable and @MainActor, any changes to its state will prompt SwiftUI to update relevant views on the main thread.

@Observable
@MainActor
final class GameStore {
    private(set) var state: GameState

    init(state: GameState = GameState()) {
        self.state = state
    }

    func dispatch(_ action: GameAction) {
        // Use reducer to get new state
        let newState = GameReducer.reduce(state: state, action: action)
        // Enforce phase transitions validity
        if newState.currentPhase != state.currentPhase {
            // Only allow if valid transition
            guard state.currentPhase.canTransition(to: newState.currentPhase) else {
                NSLog("Invalid phase transition from \(state.currentPhase) to \(newState.currentPhase)")
                return
            }
        }
        // Assign the computed state, which notifies observers (UI)
        self.state = newState

        // Handle side-effects (if any) after state update
        if case .startGame = action, state.settings.wordSource == .customPrompt {
            // If starting game with AI-generated word, kick off image generation asynchronously
            generateSecretImage(for: state.roundState?.secretWord)
        }
    }

    // Derived data for convenience (not strictly necessary but helpful for UI logic)
    var currentPlayer: Player? {
        guard let round = state.roundState else { return nil }
        // Determine which player's turn it is to give a clue
        let idx = round.currentClueIndex % state.players.count
        return state.players[safe: idx]
    }

    func isImposter(_ playerID: UUID) -> Bool {
        return state.roundState?.imposterID == playerID
    }

    // Asynchronous side effect: generate image for the secret word using ImagePlayground
    private func generateSecretImage(for word: String?) {
        guard let prompt = word, state.settings.wordSource == .customPrompt else { return }
        Task.detached(priority: .userInitiated) {
            do {
                let creator = try await ImageCreator()  // Initialize the image generator (might throw if unavailable)
                // Request one image for the text prompt using a fun style (e.g., sketch or illustration)
                let imageSequence = creator.images(for: [.text(prompt)], style: .illustration, limit: 1)
                for try await image in imageSequence {
                    // Got a generated image (CGImage)
                    let uiImage = UIImage(cgImage: image.cgImage)
                    // Pass image to main actor for UI (store it in roundState or a cache)
                    await MainActor.run {
                        self.state.roundState?.generatedImage = uiImage
                    }
                    break  // Only need the first image
                }
            } catch {
                print("Image generation failed: \(error.localizedDescription)")
            }
        }
    }
}

Observation vs. ObservableObject: We choose @Observable (new in iOS 26) to get fine-grained dependency tracking. This should reduce unnecessary view recomputation compared to the older ObservableObject approach by tracking individual properties that are accessed by SwiftUI . The entire GameState is still one big class, but SwiftUI will only re-render parts of the view depending on which properties were read.

MainActor: Marking GameStore as @MainActor ensures any state changes (especially when triggered by UI events) happen on the main thread. This avoids concurrency issues with SwiftUI which expects state updates on main.

Side Effects: Notice that the reducer remains pure. We handle the side-effect of image generation outside the reducer, in the dispatch method after updating state. This keeps the logic testable. (Alternatively, we could integrate something like Combine or async sequence to emit side effects, but here a simple call in dispatch is fine.)

4.2 GameReducer – Pure State Transitions

GameReducer.reduce(state:action:) is a pure function that takes an immutable snapshot of GameState and an action, and returns a new GameState. It does not perform async work or access external data (except possibly random number generation or reading from Word packs, which are local resources).

Pseudocode outline with a few cases:

enum GameReducer {
    static func reduce(state: GameState, action: GameAction) -> GameState {
        var newState = state  // start with a copy (since GameState is class, be careful to clone if needed)

        switch action {
        case .addPlayer(let name, let color):
            let player = Player(name: name, color: color)
            newState.players.append(player)

        case .removePlayer(let id):
            newState.players.removeAll { $0.id == id }

        case .updatePlayer(let id, let name, let color):
            if let idx = newState.players.firstIndex(where: { $0.id == id }) {
                newState.players[idx].name = name
                newState.players[idx].color = color
            }

        case .updateSettings(let settings):
            newState.settings = settings  // simply apply the new settings

        case .startGame:
            guard newState.players.count >= 3 else {
                return state  // need at least 3 players to start
            }
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            // Initialize a new RoundState for this round
            newState.roundState = createNewRound(players: newState.players, settings: newState.settings)

        case .revealRoleToPlayer(let playerId):
            // (Could track which players have seen their role, if needed for UI)
            // Possibly mark something like an index of current player to pass device to next

        case .completeRoleReveal:
            newState.currentPhase = .clueRound

        case .submitClue(let playerID, let text):
            guard var round = newState.roundState else { break }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { break }
            // Create Clue and append
            let clue = RoundState.Clue(
                id: UUID(), playerID: playerID, text: trimmed,
                timestamp: Date(), roundIndex: round.currentClueIndex / newState.players.count
            )
            round.clues.append(clue)
            round.currentClueIndex += 1
            newState.roundState = round
            // If that was the last clue of the final round, advance phase
            if round.currentClueIndex >= newState.players.count * newState.settings.numberOfClueRounds {
                newState.currentPhase = .discussion   // move to discussion (or voting if discussion disabled)
                if !newState.settings.discussionTimerEnabled {
                    // If no discussion phase, jump straight to voting
                    newState.currentPhase = .voting
                }
            }

        case .startDiscussion:
            newState.currentPhase = .discussion
            // (Could start a timer if discussionSeconds is set)

        case .startVoting:
            newState.currentPhase = .voting
            // Maybe initialize votes dict or shuffle player order for voting if needed

        case .castVote(let voterID, let suspectID):
            newState.roundState?.votes[voterID] = suspectID
            // If all non-eliminated players have voted, we can auto-complete voting
            if let round = newState.roundState,
               round.votes.count == newState.players.count {
                // everyone voted
                newState.currentPhase = .reveal
            }

        case .completeVoting:
            newState.currentPhase = .reveal

        case .revealImposter:
            // Could set a flag if needed that reveal animation should start
            // (But likely the UI will handle the animation when phase is .reveal)

        case .imposterGuessWord(let guess):
            // Evaluate guess: if guess == secretWord, maybe award imposter extra points or change outcome

        case .completeRound:
            if var round = newState.roundState {
                // Tally scores for this round
                let result = calculateVotingResult(roundState: round)
                applyScoring(to: &newState, result: result)
                // Archive round result
                let completed = CompletedRound(from: round, result: result)
                newState.gameHistory.append(completed)
            }
            newState.currentPhase = .summary

        case .startNewRound:
            // Reset for next round with same players
            newState.currentPhase = .roleReveal
            newState.roundState = createNewRound(players: newState.players, settings: newState.settings)
            newState.roundNumber += 1

        case .endGame:
            // End game and go to summary or final screen
            newState.currentPhase = .summary

        case .returnToHome:
            newState = GameState(players: [], settings: newState.settings)  // reset state
        }

        return newState
    }

    // Helper: Initialize a new RoundState with a random or AI-generated secret word and random imposter
    private static func createNewRound(players: [Player], settings: GameSettings) -> RoundState {
        let word: String
        if settings.wordSource == .customPrompt, let prompt = settings.customWordPrompt, !prompt.isEmpty {
            word = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            word = WordSelector.selectWord(from: settings)
        }
        let imposter = players.randomElement()!
        return RoundState(secretWord: word, imposterID: imposter.id,
                          clues: [], votes: [:], currentClueIndex: 0)
    }

    // Helper: Determine voting outcome
    private static func calculateVotingResult(roundState: RoundState) -> VotingResult {
        // Tally votes
        let voteCounts = Dictionary(grouping: roundState.votes.values, by: { $0 })
                           .mapValues { $0.count }
        let mostVoted = voteCounts.max(by: { $0.value < $1.value })?.key
        let isCorrect = (mostVoted == roundState.imposterID)
        return VotingResult(mostVotedPlayerID: mostVoted, imposterID: roundState.imposterID, isCorrect: isCorrect)
    }

    // Helper: Apply points based on voting result
    private static func applyScoring(to state: inout GameState, result: VotingResult) {
        if result.isCorrect {
            // Non-Imposters guessed right – each gets pointsForCorrectVote
            for i in state.players.indices where state.players[i].id != result.imposterID {
                state.players[i].score += state.settings.pointsForCorrectVote
            }
        } else {
            // Imposter survived undetected
            if let idx = state.players.firstIndex(where: { $0.id == result.imposterID }) {
                state.players[idx].score += state.settings.pointsForImposterSurvival
            }
        }
        // (If imposter had guess option and guessed correctly, add pointsForImposterGuess accordingly)
    }
}

// Helper struct for voting outcome
struct VotingResult {
    let mostVotedPlayerID: UUID?
    let imposterID: UUID
    let isCorrect: Bool
}

All state changes are done on a copy of state (or in a newState var) and then returned, leaving the original GameState untouched until GameStore replaces it. This approach ensures we don’t accidentally mutate state in the middle of a reducer, which helps maintain consistency and supports time-travel debugging if needed.

Note: We must be careful since GameState is a reference type. We might choose to implement copy-on-write or use a struct for state to ensure newState = state truly makes a copy. Alternatively, since we only assign to GameStore.state at the end, and GameStore.state is @Observable, we can treat it as the single mutable instance that updates atomically. For simplicity, the above approach works but we must avoid directly mutating state outside reduce.

Error Handling: Some actions may be invalid in the current phase (e.g. casting vote during clue phase). The reducer should ideally ignore or throw/log in such cases. We can add assertions or logging in default case or guard conditions around sections.

5. Liquid Glass Design System Integration

The UI will strongly embrace Apple’s Liquid Glass aesthetics introduced in iOS 26. Liquid Glass is a translucent, vibrant material that reflects and refracts background content and dynamically adapts to context  . To implement this consistently, we’ll build a small design system:
	•	Color tokens: Define semantic colors for surfaces, text, and accents, mapped to system defaults.
	•	Typography: Use Apple’s typography styles (SF Pro) at recommended sizes for display, headlines, body, etc., supporting Dynamic Type.
	•	Materials: Use SwiftUI’s new .glassEffect for translucency. Also define fallback materials and shadow styles for depth.
	•	Components: Create reusable components (buttons, cards, etc.) that apply Liquid Glass styling uniformly.

5.1 Design System Research Notes (Apple Liquid Glass)

This section is based on Apple’s WWDC25 guidance and HIG:
	•	Color System: Liquid Glass relies on semantic colors rather than fixed values. Text and icons use system-defined primaries (e.g. .primary, .secondary label colors) to ensure contrast against dynamic backgrounds . The glass material itself can be tinted to create accents (e.g. a confirm button might use a blue-tinted glass). Apple’s design emphasizes vibrancy – glass components automatically adjust their color based on surroundings (light or dark mode, underlying wallpaper) . We will define colors like surfacePrimary, surfaceSecondary for backgrounds of cards and sheets, likely mapping to system background materials or clear color to let glass show through. For text, use LGColors.textPrimary = .primary (which in SwiftUI adapts to context), textSecondary = .secondary, etc. For status colors: Apple provides semantic colors (e.g. systemGreen for success, systemYellow for warning, systemRed for error); we’ll map LGColors.success/warning/error to those to maintain familiarity.
	•	Typography: iOS 26 continues to use the San Francisco font family, but Apple introduced dynamic adjustments especially for Liquid Glass contexts (e.g. Lock screen time uses fluid font scaling ). We will use SwiftUI’s Dynamic Type text styles to automatically get adjustable fonts. The LGTypography constants (displayLarge, headlineSmall, bodyMedium, etc.) correspond to the new design language’s recommended sizes. For example, Display Large might correspond to the font used for large titles (perhaps 34-40pt default, scaling with Dynamic Type), Headline styles for section titles, Body for standard text, Label for smaller UI text. We will retrieve or approximate these using .system(size:weight:) or SwiftUI’s .font(.largeTitle) etc., but ensure they scale. We’ll also respect Dynamic Type sizes (AX accessibility sizes) – using .dynamicTypeSize and relative fonts so that content remains legible at larger text settings.
	•	Material Effects: Apple’s Liquid Glass API is primarily accessed via the SwiftUI modifier .glassEffect() which applies the new material. We should use .glassEffect(.regular, in: shape) for most components (Regular variant of glass, with appropriate shape). Apple provides three base variants: regular (default translucency), clear (less opaque, for use over busy backgrounds), and identity (no effect, essentially transparent) . For most in-app panels and cards, .regular is appropriate; for smaller overlay controls on images, .clear might be used if needed. We will also consider .interactive() and .tint() modifiers: .interactive() adds the built-in Liquid Glass interactive behavior (pressure effects, highlight on touch) for controls  , and .tint(Color) tints the glass with a color (like a colored glass button) .
	•	Depth & Elevation: Liquid Glass itself adds a sense of depth via blur and specular highlights. We will augment this with subtle shadows. Apple recommends soft shadows since the glass already adds depth . We might define 3 elevation levels with small differences in shadow radius and opacity. For example, elevation1: shadow radius ~10, opacity 0.1; elevation2: radius 18, opacity 0.15; etc., to differentiate surface layers.
	•	Corner Radius: Apple’s new design often uses concentric corner radius – aligning corners of content with device corners or containers  . In practice, many panels use a large corner radius (e.g. 28 or 34). Our LGMaterials can define standard radii (e.g. card corner radius = 20 or 28).
	•	Motion & Animation: Animations in Liquid Glass have a fluid, springy feel, reflecting “liquid” physics  . iOS 26 likely provides a preset spring animation (perhaps the .bouncy curve seen in examples). We will use .spring() or .interpolatingSpring with low damping for bouncy effects, especially for transitions like revealing the imposter or toggling UI panels. Also, Apple introduced built-in animations for glass (like the interactive ripple on touch). We’ll use .interactive() on glass where appropriate to automatically get those touch animations . The RevealAnimationView (section 6.6) will use a custom spring animation to scale in the Imposter’s card with bounce.
	•	Components: We will examine Apple’s built-in components for Liquid Glass: notably, SwiftUI has buttonStyle(.glass) and .glassProminent for secondary and primary buttons , and things like GlassEffectContainer to group elements  . Where feasible, we’ll use these out-of-the-box styles (for example, our Cancel or Secondary buttons might just use buttonStyle(.glass) which gives a translucent button, and the Start Game main button could use .glassProminent which is an opaque styled variant for primary actions  ). For learning purposes, we also implement custom components (LGButton, LGCard) to see how we can replicate or tweak these designs. Each component will follow spacing and sizing conventions (e.g. padding values from Apple’s design tokens, minimum tappable area of 44x44 points, etc.).

5.2 Color System (LGColors.swift)

Define a palette of semantic colors for the app’s UI. Important: Many of these will defer to system-provided colors to automatically adapt to Light/Dark mode and ensure contrast on glass.

import SwiftUI

enum LGColors {
    // Background / Surface hierarchy
    static let surfacePrimary   = Color(uiColor: .systemBackground)   // base background color (behind glass, if any)
    static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    static let surfaceTertiary  = Color(uiColor: .tertiarySystemBackground)
    // (On iOS 26, these systemBackground colors might themselves be partially transparent in glass contexts)

    // Accent / Interactive colors
    static let accentPrimary   = Color(uiColor: .systemBlue)    // primary accent (blue by default, or customize)
    static let accentSecondary = Color(uiColor: .systemBlue).opacity(0.7)  // a lighter variant, for secondary buttons perhaps

    // Text hierarchy (these adapt automatically via UIColor)
    static let textPrimary   = Color.primary     // primary label (dynamic based on context) [oai_citation:35‡levelup.gitconnected.com](https://levelup.gitconnected.com/build-a-liquid-glass-design-system-in-swiftui-ios-26-bfa62bcba5be?gi=eba1844733b2#:~:text=Text%28)
    static let textSecondary = Color.secondary   // secondary label
    static let textTertiary  = Color(UIColor.tertiaryLabel)
    static let textInverse   = Color(uiColor: .systemBackground)  // e.g., text on dark backgrounds

    // Semantic status colors
    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemYellow)
    static let error   = Color(uiColor: .systemRed)

    // Player colors – map PlayerColor enum to actual Color
    static func playerColor(_ color: PlayerColor) -> Color {
        switch color {
        case .crimson:  return Color(red: 0.9, green: 0.2, blue: 0.3)    // or use preset shades
        case .azure:    return Color(red: 0.0, green: 0.48, blue: 1.0)   // systemBlue-ish
        case .emerald:  return Color(red: 0.1, green: 0.8, blue: 0.4) 
        case .amber:    return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .violet:   return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .coral:    return Color(red: 1.0, green: 0.5, blue: 0.4)
        case .teal:     return Color(.systemTeal)    // using legacy color for example
        case .rose:     return Color(red: 1.0, green: 0.3, blue: 0.5)
        }
    }
}

Rationale: We lean on UIColor.systemBackground and .label colors so that the app respects user’s Light/Dark mode and Reduce Transparency settings. If the user enables Reduce Transparency, Apple automatically replaces glass materials with solid colors (often systemBackground) . By using those here, our app will remain usable in that mode (for example, LGColors.surfacePrimary might effectively become an opaque dark gray in Dark mode when transparency is reduced, ensuring readability ).

For player colors, we picked vibrant distinct colors. In UI, players are indicated by colored circles or badges. We will need to ensure these colors are accessible on both light and dark backgrounds (e.g., use .playerColor for fill of a circle, which on glass might have dynamic contrast).

5.3 Typography System (LGTypography.swift)

import SwiftUI

enum LGTypography {
    // Display styles (largest titles, e.g. game title on Home screen)
    static let displayLarge  = Font.system(size: 40, weight: .bold, design: .default)  // perhaps used for "Imposter" title
    static let displayMedium = Font.system(size: 34, weight: .bold, design: .default)
    static let displaySmall  = Font.system(size: 28, weight: .bold, design: .default)

    // Headlines (section headers, cards titles)
    static let headlineLarge  = Font.title.bold()        // uses Dynamic Type Title font
    static let headlineMedium = Font.title2.bold()
    static let headlineSmall  = Font.title3.bold()

    // Body text (main content text)
    static let bodyLarge   = Font.body              // default body
    static let bodyMedium  = Font.subheadline       // slightly smaller
    static let bodySmall   = Font.footnote          // for less prominent text

    // Labels (for small UI elements like button text, labels)
    static let labelLarge  = Font.body.bold()       // could use body but semi-bold for button labels
    static let labelMedium = Font.subheadline       // maybe for secondary info on buttons
    static let labelSmall  = Font.caption           // smallest text, e.g. clue counters

    // We rely on SwiftUI’s Font to automatically adapt sizes when user changes Dynamic Type
}

We intentionally use SwiftUI’s predefined text styles (.title, .body, etc.) for many of these, which are Dynamic Type-aware. The numeric sizes for displayLarge etc. are chosen as an approximation; ideally we might use .largeTitle for displayLarge if it matches 40pt at default size, but since Apple in Liquid Glass might have introduced “Display” styles beyond Large Title, we approximate with explicit size. All fonts use .default design (San Francisco). The design system is easily adjustable if Apple provides exact values.

We should test at different Dynamic Type settings to ensure text doesn’t clip and layouts adjust (use .dynamicTypeSize(...)=.xxLarge etc. in previews).

5.4 Material Effects (LGMaterials.swift)

import SwiftUI

enum LGMaterials {
    // Glass material usage
    // For iOS 26+, instead of defining static Material, we will use .glassEffect modifier.
    // But for fallback (or if needed as a separate layer):
    static let cardMaterial: Material = .ultraThinMaterial   // used on iOS 25 fallback (translucent blur)
    static let elevatedMaterial: Material = .thinMaterial    // slightly more opaque
    static let chromeMaterial: Material = .regularMaterial   // for toolbars if needed

    // Elevation levels (for shadow and maybe offset)
    static let elevation1: CGFloat = 1   // base shadow elevation
    static let elevation2: CGFloat = 3
    static let elevation3: CGFloat = 5

    // Shadow definitions: returns a View modifier applying appropriate shadow for given elevation
    static func shadow(elevation: CGFloat) -> Shadow {
        // Use a soft shadow with slight vertical offset
        let radius: CGFloat
        let yOffset: CGFloat
        let opacity: Double
        switch elevation {
        case elevation3:
            radius = 20; yOffset = 8; opacity = 0.2
        case elevation2:
            radius = 12; yOffset = 5; opacity = 0.15
        default:
            radius = 6;  yOffset = 3; opacity = 0.1
        }
        return Shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: yOffset)
    }
}

We define some fallback Material types for older iOS or non-glass contexts, but on iOS 26 our preferred approach will be using .glassEffect. When applying Liquid Glass:
	•	To a view background: use .glassEffect(.regular, in: shape). This automatically handles blur and highlights. If needed, .glassEffect(.regular.tint(color)) can add color.
	•	To an entire container with multiple glass elements: wrap them in GlassEffectContainer to optimize and allow morphing transitions  . For example, our voting screen where multiple player option cards appear/disappear might benefit from this to morph glass if they animate in/out together.
	•	Shadows: Provided by LGMaterials.shadow – these should be used sparingly (Apple warns not to overuse heavy shadows since the glass effect provides depth ). We use subtle default values.

Corner Radius: We will set consistent corner radii on components. Perhaps 20 for cards, and fully rounded (capsule) for buttons if pill-shaped. Apple’s design uses large radii like 28 on modals/sheets . We’ll likely use 20-28 for major surfaces.

5.5 Reusable Components

LGCard (Glass Card Container)
A container view modifier that applies Liquid Glass styling to a content background.

import SwiftUI

struct LGCard<Content: View>: View {
    let content: Content
    let shape: RoundedRectangle

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        self.content = content()
    }

    var body: some View {
        content
            .padding(.all, 16)  // standard padding inside card
            .background {
                // Apply Liquid Glass effect to the shape
                shape.fill(.clear)         // shape as a container
                     .glassEffect(.regular, in: shape)   // primary glass material on this shape
            }
            .overlay {
                // Optional: outline the card with a subtle stroke for definition
                shape.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            }
            .shadow(LGMaterials.shadow(elevation: LGMaterials.elevation1))
    }
}

Usage: Wrap any content in LGCard { ... } to get a glassy panel. For example, in RoleCardView we’ll do LGCard { VStack { ... } }. The .glassEffect(.regular, in: shape) makes the card translucent like real glass  . We also stroke the border with a low-opacity white to create that characteristic highlight edge (this is a common technique to make glass panels stand out from background).

If Reduce Transparency is on, .glassEffect automatically falls back to an opaque style; additionally we could check accessibilityReduceTransparency environment in LGCard and if true, fill shape with a solid color (e.g. .ultraThinMaterial which under reduce transparency becomes a color) . This ensures readability in that accessibility mode.

LGButton
A custom SwiftUI view for buttons with Liquid Glass styling. (We may ultimately favor SwiftUI’s built-in .glass styles, but we define this for full control and to ensure consistency with design system colors.)

struct LGButton: View {
    enum Style { case primary, secondary, tertiary }
    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LGTypography.labelLarge)
                .foregroundStyle(foregroundStyle)   // uses appropriate foreground color style
                .frame(minWidth: 100)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(backgroundView)
        }
        .buttonStyle(.plain)  // use plain style so our custom background applies
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(LGMaterials.shadow(elevation: LGMaterials.elevation1))
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            // Solid accent colored glass (prominent button)
            RoundedRectangle(cornerRadius: 20)
                .fill(LGColors.accentPrimary)
                .glassEffect(.regular.tint(LGColors.accentPrimary), in: RoundedRectangle(cornerRadius: 20))
        case .secondary:
            // Translucent neutral button (glass with a stroke maybe)
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        case .tertiary:
            Color.clear  // no background (maybe just text button)
        }
    }

    private var foregroundStyle: Color {
        switch style {
        case .primary:
            return .white   // white text on primary colored button (since accentPrimary is colored)
        case .secondary:
            return LGColors.textPrimary  // default text color on glass
        case .tertiary:
            return LGColors.accentPrimary // maybe accent-colored text for tertiary
        }
    }
}

In LGButton, for primary style we tint the glass with the accent color (so it looks like a filled colored button but with the glass effect shining through) . For secondary, we use a mostly transparent fill – this will create a subtle frosted glass look. Tertiary might be used for something like a plain text button (no background). We use buttonStyle(.plain) to avoid default SwiftUI styling, since we are handling it manually.

Built-in Alternative: iOS 26 provides .buttonStyle(.glass) and .glassProminent). We could consider using .glassProminent for primary buttons instead of reinventing it, which would automatically handle interactive effects and use the system accent color by default  . In testing, we can compare our custom vs the system-provided ones.

⸻

With the design system in place, all UI code should use these tokens and components, ensuring consistency and easy theming updates. Next, we integrate these into the feature UIs.

6. Feature Implementation Details

We break down each major screen/feature and describe the UI and logic.

6.1 Home Screen (HomeView)

Purpose: Welcome screen where players can start a new game, read how to play, or adjust settings. It should immediately convey the Liquid Glass aesthetic.

UI Layout: A vertical stack with the game title and some buttons. Possibly a cool background (maybe a colorful gradient or abstract shape) to showcase the glass effect on the UI elements above it.

struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var showSettings = false
    @State private var showHowToPlay = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background could be a subtle gradient or image
                LinearGradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6), .pink.opacity(0.5)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: LGSpacing.large) {
                    Text("Imposter")
                        .font(LGTypography.displayLarge)
                        .foregroundStyle(.primary)    // primary text so it adapts [oai_citation:48‡levelup.gitconnected.com](https://levelup.gitconnected.com/build-a-liquid-glass-design-system-in-swiftui-ios-26-bfa62bcba5be?gi=eba1844733b2#:~:text=Text%28)
                        .padding(.top, 50)

                    VStack(spacing: LGSpacing.medium) {
                        // New Game NavigationLink
                        NavigationLink(destination: PlayerSetupView()) {
                            // We can use our LGButton or system style
                            LGButton(title: "New Game", style: .primary) { }
                        }
                        .accessibilityIdentifier("NewGameButton")

                        Button {
                            showHowToPlay = true
                        } label: {
                            LGButton(title: "How to Play", style: .secondary) { }
                        }
                        .accessibilityIdentifier("HowToPlayButton")

                        Button {
                            showSettings = true
                        } label: {
                            LGButton(title: "Settings", style: .secondary) { }
                        }
                        .accessibilityIdentifier("SettingsButton")
                    }
                }
                .padding(.bottom, 80)
                .navigationTitle("")  // no large title, use custom
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet(settings: store.state.settings) { newSettings in
                    store.dispatch(.updateSettings(newSettings))
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showHowToPlay) {
                HowToPlaySheet()
            }
        }
    }
}

Notes:
	•	The background gradient gives a vibrant backdrop that will shine through the glass UI components (like the LGButtons). The gradient uses semi-transparent colors to blend nicely.
	•	The title “Imposter” uses a display font and .foregroundStyle(.primary) so that if background is light or dark, it automatically ensures contrast . We might apply a slight .glassEffect to the title text as well or a shadow for contrast depending on appearance.
	•	Buttons: We wrap LGButton in NavigationLink and Button as needed. The LGButton itself already has styling. The NavigationLink uses a Label by default, but because we provide a custom label (our LGButton), it should render that and not the default arrow.
	•	NavigationStack: We use it for potential future navigation (e.g., a back button from PlayerSetup). On Home, we hide the navigation title. The .sheet modifiers present the Settings and HowToPlay modals.
	•	We assign accessibilityIdentifier to buttons for UI testing (see Testing section).

Liquid Glass on Home: The Home screen’s “cards” (if any) and buttons should feel glassy. We did not explicitly use .glassEffect on LGButton in the code above, but recall LGButton’s backgroundView uses .glassEffect for secondary style. If we want even the primary button to have some translucency, we could adjust it to not be fully opaque. We’ll test and iterate visual fidelity.

6.2 Player Setup Screen (PlayerSetupView)

Purpose: Allows input of player names and selection of player colors, as well as choosing game settings (like categories, difficulty, or the AI custom word prompt) before starting the game.

UI Layout: Likely a form-style list of players with add/remove, and a section for game settings. We will enforce 3–10 players. This screen should scroll if content is large (use a ScrollView or List).

Key elements:
	•	A list of current players with text fields for names and a color picker for each.
	•	“Add Player” button if <10 players.
	•	Validation text if <3 players warning “Need at least 3 players”.
	•	Settings section: difficulty picker (Easy/Med/Hard/Mixed), category selection (could be a NavigationLink to a multi-select list of categories), and an option to enable AI-generated word. If AI option is on, show a TextField for the prompt. Possibly just a toggle “Custom Word” that reveals a text field.
	•	“Start Game” button at bottom, disabled until validation passes.

We can implement with SwiftUI List for a nice form style, or a VStack with custom styling. Given we want a custom look (translucent background etc.), we might do a ScrollView and our own list rows (with LGCard background for each row maybe).

For brevity, pseudo-code:

struct PlayerSetupView: View {
    @Environment(GameStore.self) private var store
    @State private var draftSettings: GameSettings  // copy of store.state.settings to modify locally
    @FocusState private var nameFieldFocused: UUID? // to manage keyboard focus

    init() {
        _draftSettings = State(initialValue: store.state.settings)
    }

    var body: some View {
        VStack {
            Text("Players")
                .font(LGTypography.headlineLarge)
                .padding(.top, 20)

            ScrollView {
                VStack(spacing: LGSpacing.medium) {
                    ForEach(store.state.players) { player in
                        PlayerRowView(player: binding(for: player))
                            .padding(.horizontal, 16)
                    }
                    if store.state.players.count < 10 {
                        Button(action: {
                            store.dispatch(.addPlayer(name: "", color: nextColor()))
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Player")
                                    .font(LGTypography.bodyLarge)
                            }
                            .foregroundStyle(LGColors.accentPrimary)
                        }
                    }
                }
                .padding(.bottom, 50)
            }

            if store.state.players.count < 3 {
                Text("At least 3 players required")
                    .foregroundStyle(LGColors.error)
                    .font(LGTypography.bodySmall)
            }

            // Settings section (maybe collapsible or separate sheet? 
            // But we also have a SettingsSheet invoked from Home for global defaults)
            VStack(alignment: .leading, spacing: 8) {
                Text("Secret Word Source:")
                    .font(LGTypography.bodyMedium)
                Picker("Word Source", selection: $draftSettings.wordSource) {
                    Text("Random (Category)").tag(GameSettings.WordSource.randomPack)
                    Text("Custom Prompt").tag(GameSettings.WordSource.customPrompt)
                }
                .pickerStyle(.segmented)

                if draftSettings.wordSource == .randomPack {
                    // Category selection
                    Text("Categories:")
                        .font(LGTypography.bodyMedium)
                    // Could show a horizontal list of toggle chips or push to another view
                    NavigationLink(destination: CategorySelectionView(selected: $draftSettings.selectedCategories)) {
                        Text(draftSettings.selectedCategories == nil ? "All Categories" :
                             draftSettings.selectedCategories!.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                    }
                    // Difficulty picker
                    Picker("Difficulty", selection: $draftSettings.wordPackDifficulty) {
                        ForEach(GameSettings.Difficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue.capitalized).tag(diff)
                        }
                    }
                } else if draftSettings.wordSource == .customPrompt {
                    Text("Enter a word or prompt for the secret word:")
                        .font(LGTypography.bodyMedium)
                    TextField("e.g. \"Medieval Castle\"", text: $draftSettings.customWordPrompt.unwrapDefault(""))
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFieldFocused, equals: UUID())  // just to manage focus, hacky
                }
            }
            .padding()
            .background(LGColors.surfaceSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            // Start Game Button
            LGButton(title: "Start Game", style: .primary) {
                // Save settings and dispatch startGame
                store.dispatch(.updateSettings(draftSettings))
                store.dispatch(.startGame)
            }
            .disabled(store.state.players.count < 3 || (draftSettings.wordSource == .customPrompt && (draftSettings.customWordPrompt ?? "").isEmpty))
            .padding(.vertical, 20)
        }
        .padding(.horizontal, 10)
        .navigationTitle("Setup")
        .onAppear {
            // Ensure at least 3 empty players to start with?
            if store.state.players.count < 3 {
                for _ in store.state.players.count..<3 {
                    store.dispatch(.addPlayer(name: "", color: nextColor()))
                }
            }
        }
    }

    private func binding(for player: Player) -> Binding<Player> {
        // Returns a binding to a player in store.state (via store dispatch)
        Binding(get: {
            player
        }, set: { newValue in
            store.dispatch(.updatePlayer(id: newValue.id, name: newValue.name, color: newValue.color))
        })
    }

    private func nextColor() -> PlayerColor {
        // Pick a PlayerColor not much used yet (simple approach)
        let used = Set(store.state.players.map { $0.color })
        return PlayerColor.allCases.first(where: { !used.contains($0) }) ?? .crimson
    }
}

Explanation:
	•	We display a list of player entries using PlayerRowView, which likely contains a TextField for the name and maybe color picker. We manage updates via a Binding that dispatches updatePlayer action on change.
	•	The “Add Player” button appends a new player with an empty name and a chosen color (cycling through colors).
	•	We visually warn if <3 players (and disable Start button in that case).
	•	The settings portion allows choosing the word source. If random, the user can pick categories (maybe a separate multi-select view) and difficulty. If custom prompt, show a TextField to input the prompt for the secret word. We ensure to disable Start if prompt is empty in that case.
	•	We keep draftSettings as a State to modify settings locally until “Start Game” is pressed, at which point we dispatch an update. Alternatively, we could write directly to store’s settings, but isolating changes until confirmed is cleaner.
	•	The settings UI uses some default styling. We wrapped it in a semi-translucent rectangle (using surfaceSecondary.opacity(0.5)) to slightly separate it from the background. We could instead present a modal for settings (like the SettingsSheet), but that was more for global defaults. Since these settings specifically affect the upcoming game, it’s fine to have them here.
	•	CategorySelectionView would present checkboxes for each category. Simpler: we could toggle categories in place by listing them with Toggle. But given many categories, a separate view is cleaner.

We will apply Liquid Glass style to interactive elements: e.g., the Add Player button icon and text should perhaps be within a glass pill as well. But it might be okay as plain text with accent color for now.

PlayerRowView: Each row likely has: a colored circle (showing the player’s color), a TextField for name, and maybe a delete button (if >3 players). The row can be styled with LGCard to appear as a translucent panel or just be plain if we want the whole background to be already a card.

Pseudo:

struct PlayerRowView: View {
    @Binding var player: Player
    var body: some View {
        HStack {
            // Color picker or swatch
            Circle()
                .fill(LGColors.playerColor(player.color))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .onTapGesture {
                    // cycle to next color
                    if let currentIndex = PlayerColor.allCases.firstIndex(of: player.color) {
                        player.color = PlayerColor.allCases[(currentIndex+1) % PlayerColor.allCases.count]
                    }
                }
                .accessibilityLabel(Text("Player color"))
            TextField("Name", text: $player.name)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
            if /* can remove */ {
                Button(action: { /* remove player action */ }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Remove player")
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12).glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

This would make each player row a little glass card. We ensure interaction (tapping color circle cycles colors instead of a full picker to keep it simple and local). Alternatively, could use a Picker with popover.

Validation: The Start Game button is disabled if players <3 or if custom prompt is selected but empty. Possibly also validate no duplicate names (not strictly necessary, but could mention it as a potential improvement).

6.3 Role Reveal Phase (RoleRevealView)

Purpose: Pass the device to each player so they can privately see their role (secret word or “You are the Imposter”). This phase must secure the info from others – i.e., use a cover screen until tapped by the intended player.

Flow:
	1.	After tapping “Start Game”, the app transitions to RoleRevealView. It likely shows instructions: “Hand the device to Player 1 (Name)”. Possibly we show the player’s name large to avoid confusion.
	2.	When Player 1 has the device, they tap a button like “Reveal your role”. Then show the RoleCardView with either the secret word (if they are not imposter) or the imposter message. Perhaps require another tap to hide it again.
	3.	Then prompt to pass the device to next player and repeat until all players have seen their role.
	4.	Once done, an action (CompleteRoleReveal) transitions to the clue round phase.

Privacy Implementation: We should cover the screen between reveals. Options: Use a full-screen blur or some sort of obscuring view that hides the text when not actively revealing. For example, by default show a “Tap to reveal” button on an opaque background. After a short delay showing the role, hide it when tapped to continue. Possibly also incorporate a delay or a cover so that as you hand the device, others can’t peek easily (maybe add a 3-second timer auto-hiding or instruct player to tap to hide before handing over).

UI elements:
	•	Prompt text: e.g., “Give the device to Alice” and a next button “Reveal Role”.
	•	When revealing: show RoleCardView(role: .informed(word) or .imposter) with the info. Possibly add a blur overlay behind the card as an extra privacy layer.
	•	A “Done” button to cover it again and go to next player.

We can manage state like an index of current player being revealed. That can live in RoleRevealView (local @State) or be derived from how many have been revealed. Or simply reuse roundState.currentClueIndex or similar to track position (though that was for clues, better separate). Perhaps maintain an index in GameState or just compute as playersSeen = some count.

We will implement it with a local index and when reaching end, call .completeRoleReveal.

Pseudo-code:

struct RoleRevealView: View {
    @Environment(GameStore.self) private var store
    @State private var currentRevealIndex = 0
    @State private var roleRevealed = false

    var body: some View {
        let players = store.state.players
        let currentPlayer = players[currentRevealIndex]
        VStack {
            if !roleRevealed {
                Text("Pass the device to \(currentPlayer.name)")
                    .font(LGTypography.headlineLarge)
                    .foregroundStyle(LGColors.textPrimary)
                    .padding()
                LGButton(title: "Reveal Role", style: .primary) {
                    roleRevealed = true
                }
                .accessibilityIdentifier("RevealRoleButton")
            } else {
                // Show the secret role card
                if let round = store.state.roundState {
                    if currentPlayer.id == round.imposterID {
                        RoleCardView(role: .imposter, secretWord: nil)
                    } else {
                        RoleCardView(role: .informed(word: round.secretWord), secretWord: round.secretWord)
                    }
                }
                // Instruction to tap to continue
                Text("Tap to continue")
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(LGColors.textSecondary)
                    .padding(.top, 20)
            }
        }
        .contentShape(Rectangle()) // make whole area tappable when role revealed
        .onTapGesture {
            if roleRevealed {
                // Hide and move to next player
                roleRevealed = false
                currentRevealIndex += 1
                if currentRevealIndex >= players.count {
                    // All done
                    store.dispatch(.completeRoleReveal)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

RoleCardView: This view shows either the secret word or the imposter message. We will style it as a card with the Liquid Glass look (using LGCard internally). If an image was generated for the secret word (AI mode), we will display it here for informed players.

struct RoleCardView: View {
    enum Role { case informed(word: String), imposter }
    let role: Role
    let secretWord: String?  // pass the word for convenience (or image lookup)

    var body: some View {
        LGCard(cornerRadius: 20) {
            VStack(spacing: LGSpacing.large) {
                switch role {
                case .informed(let word):
                    Text("Secret Word:")
                        .font(LGTypography.bodyLarge)
                        .foregroundStyle(LGColors.textSecondary)
                    Text(word.uppercased())
                        .font(LGTypography.displayMedium)
                        .foregroundStyle(LGColors.accentPrimary)
                        .fontWeight(.heavy)
                    if let img = imageForWord(word) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    }
                    Text("You are NOT the Imposter.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(LGColors.textPrimary)

                case .imposter:
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(LGColors.error)
                    Text("You are the Imposter!")
                        .font(LGTypography.headlineLarge)
                        .foregroundStyle(LGColors.textPrimary)
                    Text("You don't know the word.\nBlend in with your clues!")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(LGColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(LGSpacing.extraLarge)
        }
        .frame(maxWidth: 300)
    }

    private func imageForWord(_ word: String) -> UIImage? {
        // Retrieve generated image from GameStore or a cache if available
        // For simplicity, this might be stored in roundState.generatedImage
        if let round = GameStore.shared.state.roundState,   // assuming singleton or env object
           let genImage = round.generatedImage {
            return genImage
        }
        return nil
    }
}

We included an imageForWord which fetches the generatedImage if it exists (we may have stored a UIImage in roundState.generatedImage when the image generation completed, see GameStore’s side effect earlier). That image is shown below the secret word for non-imposters. This visual aid makes the game more engaging (players who know the word see a picture, the imposter sees nothing) – and could help clue-givers think of clues. The imposter’s view, of course, has no image (we ensure RoleCardView(role:.imposter) does not try to show any image).

We should ensure that if the image is still generating when a player reveals, we either delay reveal or show a loading indicator. Simplicity: we kicked off generation at startGame, so by the time players pass device, hopefully it’s ready. If not, imageForWord returns nil and we just won’t show an image (or we could show a ProgressView). This is acceptable, though ideally we’d await it – in practice, generation might take a second or two per image .

To further secure the reveal, we might consider automatically hiding the role after, say, 5 seconds. But since we rely on user to tap to continue, that’s fine. The screen is full-screen so others shouldn’t see unless they peek over shoulder.

Also, we should apply a blur to the background content while a role is revealed, to ensure no one else sees reflections. Using .blur(radius: 30) on the ZStack behind RoleCard could do. Alternatively, make the RoleCard itself stand out with an opaque backdrop. Our LGCard has blur in it, but surrounding parts of screen might still show some content. For extra safety, we could overlay a Color.black.opacity(0.8) behind the card while roleRevealed.

6.4 Clue Round Phase (ClueRoundView)

Purpose: Players take turns giving clues about the secret word. Each player (including the imposter, who must fake it) gives a one-word or short phrase clue per round, for a set number of rounds (GameSettings.numberOfClueRounds).

UI Layout:
	•	A header indicating the round number of clues (e.g. “Round 1 of 2 – Clues”).
	•	The current player’s name with prompt to give a clue. Possibly highlight their assigned color.
	•	A text field to input the clue and a submit button. We restrict clue length (say 30 characters as given).
	•	Below, a list of all clues given so far (with player names or colors next to each). This updates live.
	•	Possibly an indication of whose turn is next, etc., but not strictly needed.

When a clue is submitted, the view should advance to the next player’s input. We can manage the focus on the TextField accordingly.

Use of @FocusState to focus the TextField automatically when it appears (so players don’t have to tap it every time).

We should consider how to handle the device passing for clue input. Typically, during clue giving, everyone can hear the clues, so device can be stationary or passed to each player to type themselves. Since the imposter doesn’t know the word, they might prefer not to type last (to gather info). But in local play, possibly one person (like a moderator) could type all clues, but that’s not intended. We expect each player types their clue on their turn.

So yes, device passing each turn is expected. We should show clearly whose turn it is: e.g., “Alice, enter your clue.”

Implement logic: The order is likely the same as player list order (or randomized once). We’ll assume player list order (or we could randomize to avoid predictability – could mention as future feature).

Pseudo-code:

struct ClueRoundView: View {
    @Environment(GameStore.self) private var store
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        if let round = store.state.roundState {
            let currentIndex = round.currentClueIndex
            let totalPlayers = store.state.players.count
            let currentPlayer = store.state.players[currentIndex % totalPlayers]

            VStack {
                Text("Clue Round \(round.currentClueIndex / totalPlayers + 1) of \(store.state.settings.numberOfClueRounds)")
                    .font(LGTypography.headlineMedium)
                    .foregroundStyle(LGColors.textSecondary)
                    .padding(.top, 10)

                // Current player's turn prompt
                Text("\(currentPlayer.name), give a clue:")
                    .font(LGTypography.headlineLarge)
                    .foregroundStyle(LGColors.textPrimary)
                    .padding(.top, 5)

                ClueInputView(player: currentPlayer, onSubmit: { clueText in
                    store.dispatch(.submitClue(playerID: currentPlayer.id, text: clueText))
                    // If that was the last player in a round, maybe automatically proceed or focus handling
                })
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

                // List of previous clues
                if !round.clues.isEmpty {
                    ClueHistoryList(clues: round.clues, players: store.state.players)
                        .padding(.horizontal, 16)
                        .frame(maxHeight: 200)
                }

                Spacer()

                if round.currentClueIndex >= store.state.players.count * store.state.settings.numberOfClueRounds {
                    // All clues given, show continue to voting/discussion
                    LGButton(title: "Proceed", style: .primary) {
                        if store.state.settings.discussionTimerEnabled {
                            store.dispatch(.startDiscussion)
                        } else {
                            store.dispatch(.startVoting)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .onAppear {
                textFieldFocused = true
            }
        } else {
            Text("No round in progress").foregroundStyle(.secondary)
        }
    }
}

We rely on ClueInputView to manage the TextField and submission.

ClueInputView:

struct ClueInputView: View {
    let player: Player
    let onSubmit: (String) -> Void
    @State private var clueText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LGSpacing.small) {
            TextField("Enter clue", text: $clueText)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(LGColors.textPrimary)
                .focused($isFocused)
                .onChange(of: clueText) { newValue in
                    if newValue.count > 30 {
                        clueText = String(newValue.prefix(30))
                    }
                }
                .submitLabel(.done)
                .onSubmit {
                    submitClue()
                }
            HStack {
                Text("\(clueText.count)/30")
                    .font(LGTypography.labelSmall)
                    .foregroundStyle(LGColors.textSecondary)
                Spacer()
                Button(action: submitClue) {
                    Text("Submit")
                        .font(LGTypography.bodyMedium)
                }
                .buttonStyle(.glass)  // or use LGButton style tertiary
                .disabled(clueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            isFocused = true  // focus the field when this view appears
        }
    }
    private func submitClue() {
        let trimmed = clueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        clueText = ""
        // focus will move to next player's field when ClueRoundView reinitializes with new player
    }
}

We ensure a max length of 30 chars and display a counter. The Submit button is disabled if only whitespace. We used .buttonStyle(.glass) for the submit to quickly give it a glassy look consistent with our design (or we could embed a small LGButton).

ClueHistoryList: Shows each clue given so far with the giver’s name or color.

struct ClueHistoryList: View {
    let clues: [RoundState.Clue]
    let players: [Player]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(clues) { clue in
                    if let player = players.first(where: {$0.id == clue.playerID}) {
                        HStack {
                            Circle().fill(LGColors.playerColor(player.color)).frame(width: 10, height: 10)
                            Text("\(player.name): \(clue.text)")
                                .font(LGTypography.bodySmall)
                                .foregroundStyle(LGColors.textPrimary)
                        }
                    }
                }
            }
        }
    }
}

We represent players by a small colored dot and name, then the clue text. This list should update as new clues are submitted (since clues is part of GameState.roundState which is observed).

Device Passing: We might include a note like “Hand device to [NextPlayer]” in the UI after each clue submission. However, since in clue phase all players can see clues, secrecy isn’t needed – they could just place device on a table. So no explicit pass instruction needed here.

6.5 Discussion & Voting Phase (DiscussionView & VotingView)

After clues, players discuss who they think the imposter is (if a discussion phase is enabled). Then the game enters Voting.

DiscussionView: If discussionTimerEnabled is true, we should present a countdown timer and instructions to discuss. If false or timer ends, we proceed to Voting. This view can be simple: show “Discuss now!” and maybe an animated timer circle. For brevity, we might not implement full timer logic in code, but conceptually:
	•	Use a Timer.publish Combine or asyncTimer to count down from discussionSeconds. Announce via VoiceOver as it ticks if needed (for accessibility).
	•	When timer hits 0 (or user taps “Skip” if everyone is done), dispatch .startVoting.

We’ll assume discussion is short and skip code here.

VotingView: This is pass-and-play again: each player in turn votes for who they think is the imposter. We must ensure the imposter also votes (they will try to deflect). Typically, players shouldn’t vote for themselves (we may decide to allow or disallow self-votes; it’s usually not allowed to vote yourself in these games).

Flow:
Show voter’s name -> they tap on one of the player cards to cast their vote. Immediately hide their choice and prompt to pass to next voter.

We can reuse a grid of players as selectable targets.

UI Layout:
	•	Display “Alice, select who you think is the Imposter.”
	•	Show a grid of PlayerVoteCard for each player (maybe excluding Alice themselves if we disallow self vote). The card shows player’s name and maybe their color icon.
	•	When tapped, record vote and then automatically proceed to next voter (covering the screen in between so others don’t see the choice). Possibly we can simply immediately increment a local index to next voter and not show the chosen vote to others.
	•	We should consider privacy: after Alice votes, Bob shouldn’t know who Alice voted for. So as soon as a vote is cast, we likely move on. We might show a brief “Vote recorded” and then instruct passing device.

We use a similar pattern as role reveal: manage a currentVoterIndex and a state for whether selection UI is active.

Pseudo:

struct VotingView: View {
    @Environment(GameStore.self) private var store
    @State private var currentVoterIndex: Int = 0
    @State private var hasVoted: Bool = false

    var body: some View {
        let players = store.state.players
        let voter = players[currentVoterIndex]
        VStack {
            if !hasVoted {
                Text("\(voter.name), tap who you think is the Imposter:")
                    .font(LGTypography.headlineLarge)
                    .foregroundStyle(LGColors.textPrimary)
                    .padding()
                PlayerSelectionGrid(players: players.filter { $0.id != voter.id }) { selectedPlayer in
                    // Record vote
                    store.dispatch(.castVote(voterID: voter.id, suspectID: selectedPlayer.id))
                    hasVoted = true
                }
                .padding()
            } else {
                Text("Vote recorded.")
                    .font(LGTypography.headlineMedium)
                    .foregroundStyle(LGColors.textSecondary)
                    .padding()
                Text("Pass the device to the next player.")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(LGColors.textPrimary)
                    .padding(.bottom, 20)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if hasVoted {
                // Proceed to next voter
                hasVoted = false
                currentVoterIndex += 1
                if currentVoterIndex >= players.count {
                    // All votes cast
                    store.dispatch(.completeVoting)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

PlayerSelectionGrid: Lays out PlayerVoteCard in an adaptive grid.

struct PlayerSelectionGrid: View {
    let players: [Player]
    let onSelect: (Player) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 140))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: LGSpacing.medium) {
            ForEach(players) { player in
                PlayerVoteCard(player: player)
                    .onTapGesture {
                        HapticManager.playImpact(.medium)
                        onSelect(player)
                    }
            }
        }
    }
}

We set minimum 100 and max 140 for cells to accommodate up to perhaps 4 across on tablet and 2-3 on phone.

PlayerVoteCard: Visual representation of a player as a vote option.

struct PlayerVoteCard: View {
    let player: Player
    var body: some View {
        LGCard(cornerRadius: 16) {
            VStack(spacing: LGSpacing.small) {
                Circle()
                    .fill(LGColors.playerColor(player.color))
                    .frame(width: 50, height: 50)
                Text(player.name)
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(LGColors.textPrimary)
                    .lineLimit(1)
            }
            .padding(LGSpacing.medium)
        }
        .frame(minWidth: 80, maxWidth: 120, minHeight: 100)
    }
}

Each vote card is a glass card with the player’s color circle and name. Tapping it triggers the onSelect closure.

We included a simple haptic feedback on tap for better UX (via HapticManager wrapper of UIImpactFeedback).

After the last vote, we dispatch .completeVoting which in reducer sets phase to .reveal (or we could directly go to .reveal when votes count is complete as shown earlier in reducer).

6.6 Reveal Phase (RevealView & RevealAnimationView)

Purpose: Show the result of the round: who was the imposter, did the group correctly vote them out, and allocate points. Also handle the imposter’s word guess if that rule is enabled.

This is the climax of the round, so we want to make it dramatic: reveal slowly, with animation.

RevealView: We can break it down into subviews or states: e.g., first show something like “The votes are in…” then after a moment show who was voted (maybe a tally), then reveal actual imposter, then outcome text.

To keep it manageable, we could simply do: show a text “The Imposter was…” then animate in the imposter’s name or card.

RevealAnimationView: described as custom animations, likely handles the dramatic reveal of the imposter’s identity. For example, initially show a spinning question mark or a blurred card, then flip or scale to reveal the imposter’s card.

We can use a state var isRevealed = false and an .onAppear with withAnimation after delay to flip it.

Pseudo:

struct RevealView: View {
    @Environment(GameStore.self) private var store
    @State private var showWordGuess = false
    @State private var imposterGuess: String = ""

    var body: some View {
        if let round = store.state.roundState,
           let imposter = store.state.players.first(where: { $0.id == round.imposterID }) {
            VStack(spacing: 20) {
                Text("The votes are in...")
                    .font(LGTypography.headlineLarge)
                    .foregroundStyle(LGColors.textPrimary)
                // Show who got the most votes:
                if let votedOutID = round.votes.values.sorted(by: { $0.uuidString < $1.uuidString }).first {
                    // This is simplistic; better to tally and find max
                    if let votedPlayer = store.state.players.first(where: {$0.id == votedOutID}) {
                        Text("\(votedPlayer.name) received the most votes.")
                            .font(LGTypography.bodyMedium)
                            .foregroundStyle(LGColors.textSecondary)
                    }
                }
                // Reveal the actual imposter
                RevealAnimationView(imposter: imposter)
                    .frame(height: 200)
                    .padding()

                if round.imposterID == round.votes.values.max(by: { _ in true }) {
                    Text("The group was correct!")
                        .foregroundStyle(LGColors.success)
                } else {
                    Text("The group was wrong...")
                        .foregroundStyle(LGColors.error)
                }

                if store.state.settings.allowImposterWordGuess && round.votes.values.contains(round.imposterID) == false {
                    // If imposter wasn't caught, allow guess
                    Text("Imposter, you have one chance to guess the word!")
                        .font(LGTypography.bodyMedium)
                    TextField("Your guess", text: $imposterGuess)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                    Button("Submit Guess") {
                        store.dispatch(.imposterGuessWord(guess: imposterGuess))
                        showWordGuess = false
                    }
                }

                LGButton(title: "Continue", style: .primary) {
                    store.dispatch(.completeRound)
                }
                .padding(.top, 20)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

The above is somewhat simplistic and not fully accurate logically (e.g., determining correctness). Actually, we should use our computed VotingResult. Perhaps better: when we did .completeVoting we could compute and store something like state.roundResult or mark in roundState that group was correct or not, etc. But we can recalc easily: if imposterID was among those voted (the voteCounts result).

Focus on visuals: The core is RevealAnimationView(imposter: imposter) – it should animate revealing the imposter.

RevealAnimationView:

struct RevealAnimationView: View {
    let imposter: Player
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            if isRevealed {
                // Show imposter's card
                LGCard(cornerRadius: 16) {
                    VStack {
                        Text(imposter.name)
                            .font(LGTypography.headlineLarge)
                            .foregroundStyle(LGColors.textPrimary)
                        Text("was the Imposter!")
                            .font(LGTypography.bodyMedium)
                            .foregroundStyle(LGColors.textSecondary)
                    }
                    .padding()
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Hidden state (question mark)
                Circle()
                    .fill(LGColors.surfacePrimary)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(LGColors.textPrimary)
                    )
            }
        }
        .onAppear {
            // Delay then reveal
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0).delay(1.0)) {
                isRevealed = true
            }
        }
    }
}

We start with a question mark in a circle (maybe styled as glass too), then after 1 second, animate to show the Imposter’s name card with a spring scale+fade in. The .transition(.scale.combined(with: .opacity)) ensures it scales from small to full size with opacity fade.

We might also want a background overlay during reveal for drama, e.g., a dimmed background (Color.black.opacity(0.7)) covering the screen behind the card. This could be done by putting RevealAnimationView in a ZStack with a full-screen Color when !isRevealed ? maybe not needed as we already likely are on a dedicated screen with nothing behind.

Points display: We should display points awarded this round. For instance, “+1 point to Alice, Bob, Charlie for voting correctly” or “+2 points to Imposter for surviving”. Could be a simple list. Or in summary screen highlight anyway.

Given time, we skip detailed point breakdown here, but note: the reducer updated scores, so we can reflect the new scores when we reach summary.

After any imposter word guess, call .completeRound which transitions to summary.

6.7 Summary Phase (SummaryView)

Purpose: Present final results after one or multiple rounds. If playing just one round, it’s the game result. If multiple rounds, show cumulative scores.

UI Layout:
	•	Big “Game Over” or “Round X Summary” title.
	•	A leaderboard list of players sorted by score (highest first). Highlight the winner(s). Possibly confetti or crown icon for winner.
	•	If multiple rounds or if continuing, a “Play Again” (new round same players) and “Main Menu” button. If only one round mode, perhaps just “New Game” and “Home”.
	•	Optionally, a breakdown of each round in an expandable list (each CompletedRound from gameHistory).

ScoreboardRow: We defined to show each player’s rank, name, score, and a crown if winner.

Implement sorting by score:

struct SummaryView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let players = store.state.players.sorted(by: { $0.score > $1.score })
        let highScore = players.first?.score ?? 0
        VStack(spacing: 16) {
            Text("Game Summary")
                .font(LGTypography.displaySmall)
                .foregroundStyle(LGColors.textPrimary)
                .padding(.top, 20)
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                ScoreboardRow(player: player,
                              rank: index + 1,
                              isWinner: player.score == highScore)
            }
            .padding(.horizontal, 20)

            if store.state.roundNumber > 1 {
                Button("View Round Details") {
                    // toggle showing gameHistory details
                }
            }

            HStack(spacing: 20) {
                LGButton(title: "Play Again", style: .primary) {
                    store.dispatch(.startNewRound)
                }
                LGButton(title: "Main Menu", style: .secondary) {
                    store.dispatch(.returnToHome)
                }
            }
            .padding(.vertical, 20)
        }
        .navigationBarBackButtonHidden(true)
    }
}

ScoreboardRow:

struct ScoreboardRow: View {
    let player: Player
    let rank: Int
    let isWinner: Bool

    var body: some View {
        HStack(spacing: LGSpacing.medium) {
            Text("\(rank).")
                .font(LGTypography.headlineMedium)
                .foregroundStyle(LGColors.textSecondary)
                .frame(width: 30, alignment: .trailing)
            Circle()
                .fill(LGColors.playerColor(player.color))
                .frame(width: 30, height: 30)
            Text(player.name)
                .font(LGTypography.bodyLarge)
                .foregroundStyle(LGColors.textPrimary)
            Spacer()
            Text("\(player.score)")
                .font(LGTypography.headlineLarge)
                .foregroundStyle(LGColors.accentPrimary)
            if isWinner {
                Image(systemName: "crown.fill")
                    .foregroundStyle(LGColors.warning)
            }
        }
        .padding(12)
        .background(isWinner ? LGColors.accentPrimary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

The winner row gets a slight highlighted background (accentPrimary at 10% opacity) and a crown icon. We assume single winner (ties not handled specially, could have multiple isWinner true if tie).

Multilingual and accessibility note: The score row has ordering, so we should ensure the voiceover reads it sensibly (maybe add .accessibilityLabel("\(player.name), \(player.score) points, rank \(rank)")). But we’ll address in section 9.

Round details: If needed, we could list each CompletedRound with who was imposter, who was caught or not, etc. This can help players review. This could be a simple ForEach of gameHistory, but we skip detailed implementation here.

Buttons: “Play Again” resets for a new round with same players. It essentially dispatches .startNewRound which sets phase to .roleReveal and picks a new word, incrementing roundNumber. If they choose “Main Menu”, we dispatch .returnToHome to reset state (maybe clearing players or maybe leaving them – we chose to clear players to require setup each time; could adjust if we want to keep last players as convenience).

At summary, you might also allow “New Game” which could go to setup if wanting to change players – that’s similar to main menu.

7. Word Selection & Content

7.1 Word Pack Structure (JSON Content)

We will prepare several JSON files with word lists. Each file corresponds to a category (or difficulty). Given the updated feature, we’ll organize by category. For example:
	•	words_animals.json – Contains a list of animal names (maybe even subcategorized by easy/medium/hard internally if needed).
	•	words_technology.json – Tech-related words (computer, smartphone, etc).
	•	words_objects.json – Everyday objects.
	•	words_people.json – Possibly names of well-known figures or generic roles (“doctor”, “pirate”).
	•	words_movies.json – Movie titles or characters (ensuring generally known/popular ones to avoid obscurity).

If difficulty differentiation is desired, each JSON can include a difficulty field per word or separate lists by difficulty. Simpler: we might assume all words in a category share similar difficulty (or just use the Difficulty to decide which categories to include: e.g., easy difficulty might use only a subset of categories or shorter words).

Example JSON (words_animals.json):

{
  "category": "Animals",
  "words": [
    { "word": "Cat",    "difficulty": "easy" },
    { "word": "Elephant", "difficulty": "medium" },
    { "word": "Cheetah",  "difficulty": "medium" },
    { "word": "Axolotl",  "difficulty": "hard" },
    ...
  ]
}

We can parse this into a structure:

struct WordPack: Codable {
    let category: String
    let words: [WordEntry]

    struct WordEntry: Codable {
        let word: String
        let difficulty: GameSettings.Difficulty
    }
}

Alternatively, our previous plan had a combined JSON with categories array. We can also do one big JSON with multiple categories:

Example (combined):

{
  "difficulty": "medium",
  "categories": [
    {
      "name": "Food & Drink",
      "words": ["Pizza", "Coffee", ...]
    },
    {
      "name": "Animals",
      "words": ["Elephant", "Dolphin", ...]
    },
    ...
  ]
}

But since we pivoted to categories, we might not need difficulty field at top level. Instead, use difficulty field on words or separate files per difficulty and category (that could be a lot of files). Simpler: ignore difficulty except as a filter like:
If GameSettings.difficulty == .easy, maybe filter out words marked hard.

We will implement selection to respect both difficulty and category:
	•	Load all selected categories’ word lists.
	•	Within those, filter by difficulty if needed (e.g. if difficulty is easy, maybe exclude words with difficulty hard).

We ensure the word content is age-appropriate (no offensive terms, etc.). Also avoid overly proper nouns unless category calls for it (like movie titles might be proper nouns but recognizable).

7.2 WordSelector Implementation

The WordSelector handles loading JSON and picking a random word given the game settings.

enum WordSelector {
    static func selectWord(from settings: GameSettings) -> String {
        // Determine which word list(s) to use
        let categoryFiles: [String]
        if let selected = settings.selectedCategories, !selected.isEmpty {
            // Use selected categories
            categoryFiles = selected.map { "words_\($0.lowercased())" }
        } else {
            // All categories (we know our file names)
            categoryFiles = ["words_animals", "words_technology", "words_objects", "words_people", "words_movies"]
        }

        // Load words from those files
        var candidates: [String] = []
        for file in categoryFiles {
            if let pack = loadWordPack(named: file) {
                // If difficulty filtering is needed:
                let filteredWords = pack.words.filter { wordEntry in
                    switch settings.wordPackDifficulty {
                    case .easy: return wordEntry.difficulty == .easy
                    case .medium: return wordEntry.difficulty == .medium
                    case .hard: return wordEntry.difficulty == .hard
                    case .mixed: return true
                    }
                }
                candidates.append(contentsOf: filteredWords.map { $0.word })
            }
        }
        if candidates.isEmpty {
            return "UNKNOWN"
        }
        return candidates.randomElement()!
    }

    private static func loadWordPack(named name: String) -> WordPack? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(WordPack.self, from: data)
    }
}

If selectedCategories is nil, we load all categories (simulate a “mixed bag”). If .mixed difficulty, we don’t filter by difficulty (all words possible). If difficulty is specified, we only choose suitable words.

This function runs locally from JSON, no networking – fits offline constraint.

7.3 AI-Generated Word & Image (Foundation Models Integration)

Feature: The user can opt to use Apple’s on-device AI to generate a custom secret word (based on their prompt) and an accompanying image. This uses Apple’s Foundation Models introduced in iOS 26, specifically the ImagePlayground framework for image generation.

When used: If GameSettings.wordSource == .customPrompt and the user provided a prompt in customWordPrompt. In this case, GameReducer.createNewRound will set secretWord = prompt. We then asynchronously generate an image for that prompt (see GameStore.dispatch implementation).

Image Generation Implementation:
	•	We import ImagePlayground and use ImageCreator. The Apple docs state: “Use the ImagePlayground framework to generate custom images using system-supported styles. To generate images, you specify a text description of what you want.” .
	•	We must check availability: ImageCreator() is async and can throw (if device doesn’t support or user has some restriction). We handle errors gracefully (no image if fails).
	•	We request the generator for images for concept .text(prompt) with a chosen style. Styles include .photo, .illustration, .monochrome, .sketch, etc. We might use .illustration or .fantasy if available to get a fun drawing.
	•	The result comes as an AsyncSequence of images (likely because the model generates multiple candidates progressively). We take the first result and convert to UIImage.

This generation happens in background as soon as the game starts. It typically takes a second or two per image (depending on complexity and device speed). By doing it during role reveal phase (or earlier), we overlap it with the time players are passing device around, so hopefully by clue phase it’s ready. If not, the image might appear halfway, which is acceptable.

Displaying the image: We added an optional generatedImage property in RoundState (in code we mentioned storing it in GameStore or RoundState). When ImageCreator yields a result, we set roundState.generatedImage = uiImage on the main actor. SwiftUI will then show it in RoleCardView (since we wrote it to fetch from roundState).

We should also manage memory – the image should be reasonably sized (ImagePlayground likely returns something like 512x512 or 1024x1024 CGImage). Displaying it at smaller size is fine.

Alternate approach (ImagePlayground UI): Apple also allows presenting a full ImagePlayground UI (.imagePlaygroundSheet) which lets the user refine the image manually . For our game flow, we likely do not want an extra UI step (it would interrupt the game). So we choose programmatic generation for a seamless experience.

Language Model (text generation): The feature description mentioned “Apple Language Foundation Models”. For completeness: Apple’s Foundation Models include a SystemLanguageModel for text . We considered whether to use it to pick a random word given a user prompt like “medieval”. That could be done by prompting the LLM to output a random related noun. However, since the user can just directly type the word they want, we skipped that. If we wanted a surprise element (user provides a theme, AI picks a secret word), we could implement it by using SystemLanguageModel with a prompt such as “Give me one random word related to [theme].” This would be on-device and offline as well. But due to complexity and unpredictability, we avoid it for now. The user’s prompt is taken as the actual word.

Content filtering: The ImagePlayground framework has content guidelines (e.g., might refuse certain prompts for safety). We assume normal use (players likely enter an object or scenario). If generation fails (perhaps due to disallowed content or other error), we’ll simply have no image.

Summing up, the AI integration enhances the game’s variety (custom words and fun images) while keeping everything on-device, preserving the local-only requirement.

8. Persistence & Settings

Even though the game is local-only, we may want to persist some data for convenience across app launches:
	•	Game settings (so user’s preferred timers, etc. are remembered).
	•	Last players names and colors (to quickly set up rematch with same people).
	•	Statistics like number of games played, a high score record, etc.

We can use UserDefaults or the new @AppStorage / @Observable objects.

8.1 Local Storage Strategy

Use UserDefaults for simple key-value storage. Keys enumerated:

enum StorageKeys {
    static let gameSettings    = "imposter.gameSettings"
    static let lastPlayers     = "imposter.lastPlayers"        // maybe store an array of names/colors
    static let gamesPlayed     = "imposter.gamesPlayed"
    static let highScore       = "imposter.highScore"
}

We might store GameSettings as Data (by encoding to JSON/Data) in defaults.

For last players, could store an array of dictionaries or just store names and colors in parallel arrays. But easier: we can store a small custom struct or just reuse [Player] with only name & color and encode that.

8.2 SettingsStore

We can create a separate observable object for app-wide settings if needed (though GameSettings in GameState might suffice for our purposes). But suppose we want a persistent global default that pre-fills new GameSettings each game – that could be SettingsStore.

@Observable
final class SettingsStore {
    var settings: GameSettings {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.gameSettings),
           let decoded = try? JSONDecoder().decode(GameSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.gameSettings)
        }
    }
}

We would use SettingsStore in the HomeView’s environment to feed SettingsSheet. The SettingsSheet modifies this store’s settings which auto-saves.

Additionally, when a game ends, we could save lastPlayers:

func saveLastPlayers(_ players: [Player]) {
    let simple = players.map { ["name": $0.name, "color": $0.color.rawValue] }
    UserDefaults.standard.set(simple, forKey: StorageKeys.lastPlayers)
}

And load similarly on app launch to prepopulate PlayerSetup.

These are UX conveniences beyond core functionality.

9. Accessibility & Localization

9.1 Accessibility Considerations

We want Imposter to be enjoyable for all players, including those with disabilities.

VoiceOver & Dynamic Type:
	•	All interactive elements (buttons, text fields, player cards) should have accessible labels and hints. E.g., for the vote grid, a VoiceOver user should hear “Alice, button, double tap to vote for Alice as Imposter”. We can achieve this by setting .accessibilityLabel on PlayerVoteCard as "\(player.name) (player.color.rawValue) button" and maybe .accessibilityHint("Vote for this player as the imposter"). We may also mark elements as .accessibilityElement(children: .combine) where appropriate to have a cohesive readout.
	•	Announce phase changes: Use UIAccessibility.post(notification: .announcement, argument: "Clue round started, pass device to first player") when transitioning phases to alert VoiceOver users about what’s happening. For example, when currentPhase changes to .clueRound, we do an announcement. We can encapsulate this in didSet of GameState.currentPhase or in GameStore.dispatch.
	•	Dynamic Type: Our text is largely using Font styles that scale. We should test at largest settings to ensure layout holds. If needed, use .minimumScaleFactor on large titles to avoid truncation, or adjust layout for vertical scrolling. The design uses mostly flexible VStack/ScrollView, so it should be fine.

Color Blindness:
	•	We chose distinct colors for players, but some (e.g., rose vs coral) might look similar to certain color blindness. We should not rely solely on color to identify players – that’s why we also show player names with every color indicator. Additionally, we can provide shapes/patterns if needed (e.g., a stripe on a player circle for certain players). Since players are in-person, they can also clarify verbally if confusion arises, but we want the UI to be as clear as possible.
	•	Ensure sufficient contrast for text on glass. The .foregroundStyle(.primary/.secondary) should automatically ensure contrast by adjusting vibrancy if behind glass . We should test that our backgrounds don’t make text illegible. If needed, apply a slight dimming layer behind text on busy backgrounds (as Apple does for clear variant requirements ).

Reduced Transparency & Motion:
	•	If Reduce Transparency is on, our .glassEffect views will become solid. We should double-check things like RoleCard which might be translucent – in reduce transparency mode, it will likely just be a light gray or something. That’s fine, but ensure text still contrasts (system should handle it though).
	•	If Reduce Motion is on, avoid overly bouncy or lengthy animations. We can use .animation(..., reducesMotion: true) for things like Reveal to automatically shorten or simplify animations if the user prefers. Or check UIAccessibilityReduceMotion environment. For our spring reveal, maybe just do a simple fade if reduce motion is true.

Accessibility Identifiers:
We placed some via .accessibilityIdentifier for UI tests (not user facing). We should also ensure labels for VoiceOver:
	•	New Game, How to Play, Settings buttons: already have text label which VO will read. But the LGButton might just be a custom view, hopefully VO picks up the Text. If not, we explicitly set .accessibilityLabel(title).
	•	In PlayerSetup, each TextField should have a hint like “Player name, text field”. The placeholder “Name” helps. We might also group the color circle and name field so VO user knows which color corresponds to which name – perhaps label the color circle as “Color for (player.name)” or if name is empty, just “Select player color”.
	•	Voting: We should focus VoiceOver appropriately when passing the device. Possibly use .accessibilityFocused if needed to focus the “Alice, select who is imposter” text.

We will add an extension for accessible labels, e.g.:

extension View {
    func accessibilityPlayerBadge(player: Player) -> some View {
        self.accessibilityLabel("\(player.name), color \(player.color.rawValue)")
             .accessibilityHint("Player indicator")
    }
}

Then apply it to color circles etc. Also for ScoreboardRow, combine rank, name, score into one accessible text to avoid needing to swipe multiple elements.

Announcing Phase Changes Example:

func announcePhaseChange(_ phase: GamePhase) {
    let message: String
    switch phase {
    case .roleReveal:
        message = "Secret roles are being handed out. Pass the device around."
    case .clueRound:
        message = "Clue round started. Each player will give a clue."
    case .voting:
        message = "Time to vote for the imposter."
    case .reveal:
        message = "Revealing the results."
    case .summary:
        message = "Game over. Here are the final scores."
    default:
        message = ""
    }
    if !message.isEmpty {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

We call this when we change phases (perhaps in GameStore after dispatching a phase change action).

9.2 Localization

We will support multiple languages using Apple’s new String Catalog (Localizable.xcstrings) approach for iOS 26. This allows us to manage translations easily.
	•	All user-facing text should be in Text("key") form with a localization key and a comment for context. For instance:
	•	Text("new_game_button", comment: "Button to start a new game") in code, and in the Strings catalog map “new_game_button” -> “New Game” for English, “Nouvelle Partie” for French, etc.
	•	Similarly for dynamic strings, use String.localizedStringWithFormat or Text("\(player.name) ...") might need manual localization for grammar (we could use %@ placeholder in a string catalog entry).
	•	We will prepare translations for at least: Spanish, French, German, Japanese as requested. We’ll ensure that our UI can accommodate potentially longer text (German tends to be longer, Japanese might need slightly larger text for readability).
	•	Use appropriate pluralization and gender if needed. For example, if we had a string like “%d players”, we should use a .stringdPlural or provide plural forms in the catalog. But since most text is short and likely fine with simple translation, we may not need complex plural handling beyond English (our content doesn’t have a lot of count-specific phrases except maybe “players required”).
	•	Right-to-left (Arabic/Hebrew) support: Using SwiftUI, it should automatically flip layout for RTL if we use standard components. Our layout is mostly center or vertical, so probably fine. We should test at least one RTL locale.
	•	We have to localize the word packs as well or decide they remain in English. Probably the secret words should ideally be localized for a fair game in other languages. That’s a bigger task (e.g., provide separate word lists for each language). Possibly out-of-scope, but we could at least provide Spanish word packs if doing Spanish localization. For now, assume game is played in the language it’s localized to, so ideally yes, word list should match. This could be a future enhancement (maybe not fully done in MVP).

Implementation: We create a String catalog in Xcode named Localizable (which generates Localizable.strings for each locale). We ensure to mark all Text("...") for localization and provide base translations.

Examples:

Text("imposter_title", comment: "Game title on home screen")
Text("players_section_title", comment: "Title for players section on setup screen")

In English .xcstrings:

"imposter_title" = "Imposter";
"players_section_title" = "Players";

For Spanish:

"imposter_title" = "Impostor";
"players_section_title" = "Jugadores";

(We must double check context; “Impostor” is Spanish for Imposter, etc.)

We also ensure our accessibility labels are localized (VoiceOver will read in the user’s language). If we used actual player names or dynamic content, that remains as is, but static hints like “Pass device to next player” should be localized.

Apple’s new string catalog can handle even SwiftUI strings nicely, and since we target iOS 26, we can fully adopt it.

10. Testing Strategy

We will implement a thorough testing approach including unit tests for game logic and UI tests for user flows.

10.1 Unit Tests

Focus on the pure parts: GameReducer, WordSelector, etc.

GameReducerTests: Validate that each action results in expected state changes.

Examples:

final class GameReducerTests: XCTestCase {
    func testAddPlayer() {
        var state = GameState(players: [], settings: .default)
        let action = GameAction.addPlayer(name: "Alice", color: .crimson)
        state = GameReducer.reduce(state: state, action: action)
        XCTAssertEqual(state.players.count, 1)
        XCTAssertEqual(state.players[0].name, "Alice")
        XCTAssertEqual(state.players[0].color, .crimson)
    }

    func testStartGameInitializesRound() {
        var state = GameState(players: [
            Player(name: "A", color: .crimson),
            Player(name: "B", color: .azure),
            Player(name: "C", color: .amber)
        ], settings: .default)
        XCTAssertNil(state.roundState)
        state = GameReducer.reduce(state: state, action: .startGame)
        XCTAssertNotNil(state.roundState)
        XCTAssertEqual(state.currentPhase, .roleReveal)
        // Secret word should be set
        XCTAssertFalse(state.roundState!.secretWord.isEmpty)
        // One of the players should be the imposter
        XCTAssertTrue(state.players.map{$0.id}.contains(state.roundState!.imposterID))
    }

    func testVotingOutcomeCorrect() {
        // Setup a scenario: 3 players, A is imposter
        var state = GameState(players: [
            Player(name: "A", color: .crimson),
            Player(name: "B", color: .azure),
            Player(name: "C", color: .amber)
        ], settings: .default)
        state = GameReducer.reduce(state: state, action: .startGame)
        // Set A as imposter explicitly for test consistency
        state.roundState?.imposterID = state.players[0].id
        // B and C vote for A
        state = GameReducer.reduce(state: state, action: .castVote(voterID: state.players[1].id, suspectID: state.players[0].id))
        state = GameReducer.reduce(state: state, action: .castVote(voterID: state.players[2].id, suspectID: state.players[0].id))
        state = GameReducer.reduce(state: state, action: .completeVoting)
        // After voting completed, we should be in reveal phase
        XCTAssertEqual(state.currentPhase, .reveal)
        // Since A was imposter and got votes, check scores: B and C should have +1
        XCTAssertEqual(state.players[1].score, state.settings.pointsForCorrectVote)
        XCTAssertEqual(state.players[2].score, state.settings.pointsForCorrectVote)
        XCTAssertEqual(state.players[0].score, 0) // imposter gets nothing when caught
    }

    // Additional tests:
    // - Imposter survives scenario (no one votes them)
    // - Edge cases like ties in votes (if tie, our logic picks max by value might pick first arbitrarily; ensure it’s deterministic or document it)
    // - Word selection returns valid results given various settings
    // - That invalid actions (like startGame with <3 players) do not change state
}

WordSelectorTests: ensure correct filtering.

func testWordSelectorFiltersByCategoryAndDifficulty() {
    // Prepare a WordPack with mixed difficulties
    // ... (we can embed some test JSON or stub the load function)
    GameSettings settings = GameSettings.default
    settings.selectedCategories = ["animals"]
    settings.wordPackDifficulty = .easy
    let word = WordSelector.selectWord(from: settings)
    // Ensure the word returned is from animals category and of easy difficulty.
    // If our test pack has known values, we assert on them.
}

We might need to inject a testable version of WordSelector (or allow dependency injection for the data) to avoid relying on actual JSON files in tests.

AI Integration Tests: Could simulate the scenario of .customPrompt – but since ImageCreator is not easily testable without device and possibly requires actual hardware availability, we may skip testing that integration beyond ensuring that if prompt is set, createNewRound uses it and that dispatch triggers image gen (we could mock ImageCreator in tests or simply test that roundState.secretWord == prompt).

10.2 UI Tests (XCTest + XCUITest)

We set up UI tests to simulate user interaction flows:

Important flows:
	•	Complete game flow: Launch app, go through adding players, starting game, clue, voting, summary.
	•	Edge cases: Not enough players should disable Start.
	•	Navigation: Pressing home or back does the right thing (though our design doesn’t use navigation back in gameplay; summary has main menu button).

Example UI test:

final class ImposterUITests: XCTestCase {
    let app = XCUIApplication()

    func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testCompleteGameFlow() {
        // Home screen
        XCTAssertTrue(app.buttons["NewGameButton"].exists)
        app.buttons["NewGameButton"].tap()

        // We should be on player setup. Add default players if not present.
        // Assuming PlayerSetupView auto-added 3 players:
        let nameFields = app.textFields
        XCTAssertTrue(nameFields.firstMatch.exists)
        // Enter names
        let playerNames = ["Alice", "Bob", "Charlie"]
        for i in 0..<playerNames.count {
            let tf = nameFields.element(boundBy: i)
            tf.tap()
            tf.typeText(playerNames[i])
        }
        // Start game
        let startButton = app.buttons["Start Game"] // if labeled as such
        XCTAssertTrue(startButton.exists)
        XCTAssertFalse(startButton.isEnabled)  // It might be disabled until names non-empty or 3 players, depending on logic
        // If disabled because names empty or so, fill them then:
        // (We did fill names above)
        XCTAssertTrue(startButton.isEnabled)
        startButton.tap()

        // Role reveal for Alice
        let revealButton = app.buttons["RevealRoleButton"]
        XCTAssertTrue(revealButton.waitForExistence(timeout: 2))
        revealButton.tap()
        // Now role should show. We won't know if Alice is imposter or not in test easily to assert specific text, but:
        XCTAssertTrue(app.staticTexts["Imposter!"].exists || app.staticTexts["Secret Word:"].exists)
        // Tap to continue to next player
        app.staticTexts["Tap to continue"].tap()  // or generally tap anywhere
        // Repeat for Bob and Charlie:
        app.buttons["RevealRoleButton"].tap()
        app.staticTexts["Tap to continue"].tap()
        app.buttons["RevealRoleButton"].tap()
        app.staticTexts["Tap to continue"].tap()

        // Now should be in ClueRoundView
        XCTAssertTrue(app.staticTexts["Clue Round"].exists)
        // Enter clues for each in turn:
        let clueField = app.textFields["Enter clue"]
        for _ in 0..<2 * playerNames.count {  // 2 rounds * 3 players = 6 clues in default
            clueField.tap()
            clueField.typeText("testclue")
            app.buttons["Submit"].tap()
        }
        // After clues, proceed to voting
        if app.buttons["Proceed"].exists {
            app.buttons["Proceed"].tap()
        }

        // Voting: each player votes (simulate by tapping first option each time for simplicity)
        for name in playerNames {
            let prompt = app.staticTexts.element(matching:.any, identifier: nil).label // get the "Alice, tap who..." text
            XCTAssertTrue(prompt.contains("tap who"))
            // Just vote the first card:
            app.otherElements.containing(.staticText, identifier: name).element(boundBy: 0).tap() 
            // Actually, better to find a vote button by player name:
            // e.g. if we choose to always vote for Alice:
            if app.staticTexts["Alice"].exists {
                app.staticTexts["Alice"].tap()
            }
            // Tap to go to next voter
            app.staticTexts["Vote recorded."].tap()
        }

        // Reveal phase
        XCTAssertTrue(app.staticTexts["The votes are in..."].waitForExistence(timeout: 2))
        // Continue to summary
        app.buttons["Continue"].tap()
        // Summary
        XCTAssertTrue(app.staticTexts["Game Summary"].exists)
        XCTAssertTrue(app.staticTexts["Alice"].exists)
        XCTAssertTrue(app.staticTexts["Play Again"].exists)
        XCTAssertTrue(app.staticTexts["Main Menu"].exists)
    }
}

The UI test uses accessibility identifiers for reliable access (we added a few like “NewGameButton”). We’d add more if needed (e.g., to identify text fields vs others). Some parts are tricky to automate (the roles and votes are random). In such cases, we might not verify exact content but ensure navigation proceeded.

We also consider UI tests for:
	•	Localization: Possibly launch app in a different locale and verify a known string is translated (XCTest can launch with arguments -AppleLanguages (fr) etc).
	•	Dark/Light mode: Could force interfaceStyle and ensure things still visible (but automated checking of UI appearance is limited, mostly manual visual test).

Development Tools for Testing
	•	Use SwiftUI Previews heavily during development to test views in different scenarios (e.g., RoleCardView preview with imposter vs informed, SummaryView with sample data, etc.). Previews can simulate Dark mode, Dynamic Type, etc.
	•	Use Instruments to catch memory leaks (especially around our use of Observation and reference types) and to ensure image generation isn’t causing retain cycles.
	•	Profiler to ensure image generation and usage doesn’t spike memory too high (foundation model is heavy, but Apple likely keeps it optimized; still ensure we don’t keep large images unnecessarily).

11. Performance & Optimization

The app scope is modest, but we must ensure smooth performance especially with the fancy UI effects and on-device AI:

11.1 SwiftUI Performance
	•	Observation vs State: Using fine-grained @Observable on GameState means large sub-objects like players array changes will re-render only views that depend on it. We should mark things like @IgnoreObservation if needed (if some part of GameState should not trigger UI updates on every minor change). Example: the gameHistory array might not need to be observed live, so we could mark it to ignore to reduce overhead.
	•	Avoiding heavy computations in body: Keep view bodies simple. Expensive tasks (like tallying votes for display) should be pre-computed in the model or computed property outside the body. In our RevealView, we did some logic inline (like picking most votes). For performance, better to compute that in reducer and store in a property (e.g., store.state.roundState?.mostVotedPlayerID) to avoid recalculating on every re-render.
	•	EquatableView or .id: If we find a view reloading too often, consider adding .equatable() if the view can equate input to avoid re-render. For example, the PlayerVoteCard could be equatable by player id, so SwiftUI might skip re-drawing them if nothing changed.
	•	Image caching: The generated image – make sure we don’t generate it multiple times unnecessarily. In our flow, we generate once on startGame. We store it in state so it persists; if someone navigates (though they can’t really go back without ending game), it remains. That’s fine. Remove it when round ends if memory is a concern (but one image is okay).
	•	Use .drawingGroup() carefully if any complex drawing needed (not really needed here).

11.2 Memory Management
	•	Our objects are mostly small (GameState, arrays). The big one is the AI model – but that’s handled by Apple’s framework. It likely loads ~3GB quantized model, but in memory likely few hundred MB. Apple ensures it unloads after use or when not needed. We should call ImageCreator in a local scope and not keep it around unnecessarily. In our code, we instantiate, get result, then it goes out of scope. That should free the context (maybe, or maybe not – we might need an explicit cancellation to free memory if user quits early, but since no cancel mechanism shown, perhaps not needed).
	•	Avoid strong reference cycles: e.g., closures capturing self in GameStore.generateSecretImage – we used await MainActor.run { self.state.roundState?.. } which is fine since GameStore is MainActor (no cycle since Task is detached). Just be mindful not to self strongly in a long-lived Task that outlives the store (not likely here).
	•	We might implement a cleanup: after summary or endGame, if any large data (like gameHistory or images) are no longer needed, drop them (the objects will deallocate when GameState reset).

11.3 Battery & Thermal Considerations
	•	The heavy compute is the image generation. Running the on-device diffusion model will spike CPU/GPU for a few seconds. We should do it at most once per round. If user plays repeatedly and keeps using AI, it’s their choice – but we trust Apple’s model to run efficiently on ANE (Apple Neural Engine). Perhaps advise playing on charger if doing many rounds with AI, but realistically one or two images is fine.
	•	We minimize continuous animations. The only ones are short (reveal bounce, maybe a timer countdown which could be a trivial animation of a circle stroke, nothing intense).
	•	Haptics: brief impacts are fine (low power cost).
	•	Ensure the app doesn’t prevent screen lock unnecessarily. If a round is going slow, screen might dim – but since they are actively passing and tapping, not an issue. We could consider disabling idle timer during gameplay using UIApplication.shared.isIdleTimerDisabled, but probably unnecessary for a party game (people will be interacting frequently).

By following these, we expect a consistent 60fps. The only hitch might be during image generation – which could cause a momentary UI stutter if not handled off-main. We did it off-main, but when the result comes, converting to UIImage and setting state on main is quick. We should test on a device to ensure there’s no jank at reveal time.

12. Build & Deployment

12.1 Build Configurations

We will have standard Debug and Release configurations (no special flavors needed).

Debug Mode:
	•	Enable all compiler warnings (-Wall). Treat warnings as errors for clean code.
	•	Keep SWIFT_STRICT_CONCURRENCY = complete even in debug to catch issues early.
	•	Use the OS_ACTIVITY_MODE to see logs (if needed for debugging state machine).
	•	SwiftUI Previews: Those are only at dev time. Possibly define dummy data for previews using #if DEBUG code in preview providers.

Release Mode:
	•	Optimization: Use -Osize or -O for better performance. Ensure no debug code runs (like ensure any assert or logging doesn’t impact release).
	•	Symbol stripping: enable to reduce binary size.
	•	Bitcode: not applicable (we set off as Apple deprecated it, and App Store now ignores it).
	•	Ensure we set correct app icon, launch screen assets in asset catalog.

We should also test Release build on device for any SwiftUI differences (sometimes @Observable might behave slightly differently in optimized builds – likely fine though).

12.2 App Store Preparation

App Icon & Screenshots:
	•	Design an icon following Liquid Glass style – perhaps a glassy question mark to signify imposter. Size 1024x1024 for App Store.
	•	Provide screenshots for all required device sizes (in iOS 26 that’s likely iPhone 14/15 Pro Max, iPad Pro etc.). Highlight the UI in action – show clue screen, voting screen, maybe the generated image feature. Since it’s local multiplayer, show multiple people around device in marketing if possible (though App Store screenshots typically just device screens).
	•	Write App Store description focusing that it’s a fun party game, local-only (no data collection). Emphasize “new Liquid Glass design” maybe as a tech novelty.
	•	Choose category Games > Party (and maybe Family subcategory). Age rating: 4+ (unless we worry some words might be not suitable for very young, but likely fine).
	•	App Privacy: We collect no personal data, do not transmit anything (the AI is on-device). So we can confidently fill out that no data is collected. (Just ensure if we use haptics or something, that doesn’t require disclosure – it shouldn’t.)

App Store compliance:
	•	Confirm we aren’t using any private APIs (we use only public frameworks like ImagePlayground). But note: FoundationModels might be new; ensure it’s not beta-only by time of submission. Assuming iOS 26.0+ final has it.
	•	Localization: we mention supporting multiple languages, so provide those localizations in the app bundle. App Store metadata also localized appropriately.
	•	App Store Review: Since it’s offline and doesn’t require accounts, should be straightforward. The only potential concern: the image generation feature – Apple might review that to ensure it follows their content guidelines (foundation model is on-device though, no remote calls, so it should be fine. The app doesn’t provide user a way to generate disallowed content beyond what Apple’s model would allow). We should implement the recommended usage description if any for FoundationModels (none required as it’s not like Camera or Mic).

13. Implementation Timeline

A proposed 6-week schedule for one developer:
	•	Week 1: Project Foundation
	•	Set up Xcode project targeting iOS 26.0.
	•	Initialize Git repository and CI if any.
	•	Research Apple Liquid Glass design APIs (read HIG, try sample code) and Apple Foundation Models basics.
	•	Implement core data models (Player, GameState, etc.) and GamePhase state machine.
	•	Implement basic GameStore and reducer with a couple of actions (add/remove player) to test architecture.
	•	Create design system structure (LGColors, LGTypography with placeholders).
	•	Week 2: Liquid Glass Design System
	•	Fill in LGColors with actual semantic color mapping  and test them in light/dark.
	•	Define LGTypography constants and verify scaling in Accessibility sizes.
	•	Implement LGMaterials: test .glassEffect usage in a sample view, ensure shadows look good with glass. Possibly create a demo view with multiple overlapping glass components to tweak parameters.
	•	Build LGButton and LGCard and verify in previews their appearance (compare against Apple’s styles from WWDC videos).
	•	Create a preview library: e.g., Preview for LGCard with text, Preview for LGButton in each style state.
	•	Adjust components for accessibility (e.g., ensure LGButton has .accessibilityLabel(title) if needed).
	•	Week 3: Core Gameplay Features
	•	Implement HomeView UI with navigation and modals. Use design system styles.
	•	Implement PlayerSetupView: list management, text fields, color picking. Validate min player count.
	•	Hook up SettingsSheet for game settings or integrate settings into PlayerSetup as decided.
	•	Implement WordSelector logic and load sample JSON files into app bundle. Test that random selection works.
	•	Implement the startGame flow: when button tapped, ensure state transitions and RoundState created. Possibly print the secret word in console for debugging.
	•	Basic navigation wiring: after startGame, show RoleRevealView (conditionally via NavigationLink in PlayerSetup or programmatic nav). This might involve having an @State in ImposterApp to control navigation, or simpler, using NavigationStack with state-bound path. We might instead structure it as one NavigationStack through phases, or multiple if using programmatic. Possibly will use a switch in the top-level view on gamePhase to show different view hierarchies. This might require revising navigation approach.
	•	Week 4: Gameplay Phases Implementation
	•	RoleRevealView and RoleCardView: implement pass-and-play reveal logic. Test with 3 players to ensure it cycles properly. Add delays or safety as needed (like maybe requiring a double tap to hide to prevent accidental immediate tap-through).
	•	ClueRoundView and ClueInputView: implement clue submission, list display. Ensure when one clue submitted, the UI updates to next player’s turn (our state currentClueIndex drives that). Test a full set of clues.
	•	DiscussionView: if doing a simple version, just a placeholder with maybe a manual “Start Voting” button for now. Timer can be added if time permits.
	•	VotingView: implement sequential voting as designed. Test with 3 players voting. Ensure votes stored correctly and phase advances to reveal after last vote.
	•	RevealView and RevealAnimationView: implement the reveal animation and showing results. Tie into scoring logic (which should have been implemented in reducer applyScoring). Check that scores updated in GameState. Possibly animate score changes (maybe not necessary in reveal, but could flash +1 next to names, etc. If time permits, else show final in summary).
	•	SummaryView and Scoreboard: display final scores, implement Play Again (which essentially goes to next round’s roleReveal) and Home (pop to home).
	•	Ensure that if Play Again is tapped, a new RoundState is created with a new word (but same players and scores accumulate). Or if we intended rounds to accumulate points, yes we keep scores; if not, we could reset scores. By default in code we accumulate, which is more interesting (like best of several rounds).
	•	Week 5: Polish & Additional Features
	•	Integrate Haptic feedback: use HapticManager to trigger appropriate feedback on clue submission (maybe light tick), on vote tap (medium impact), on reveal (success or failure vibes). Test on device to fine tune patterns.
	•	Sound effects (optional): Could add a drum roll sound for reveal, etc., if time. Requires adding audio assets and using AVFoundation. This is nice-to-have, can skip if time short or just stub for future.
	•	AI Integration: Implement the ImagePlayground image generation. Test with a known prompt to see if image appears in RoleCard. Optimize style/size if needed. Add any UI to handle generation delay (e.g., maybe show a ProgressView if image not ready by time of reveal – check RoundState.generatedImage in RoleCardView, if nil, maybe show ProgressView “Generating image…” instead of blank).
	•	Test the AI feature thoroughly on device (since simulator might not support the model or be very slow). Ensure it doesn’t crash or hang. Possibly test on different devices (foundation model might not be available on older devices if any limitation – Apple claims on-device LLM on A12 Bionic and later likely).
	•	Accessibility: Go through each screen with VoiceOver (enable it on device) to see if navigation and labels make sense. Add .accessibilityLabel and .accessibilityHint where needed. Test dynamic type by launching app with extra large text (Developer Settings). Adjust layout if something is cut off (maybe make some text scrollable if absolutely needed).
	•	Ensure focus transitions for VoiceOver: e.g., after pressing Start Game, focus should move to Pass device instruction automatically. We might need accessibilityFocus modifiers for that.
	•	Perhaps add VoiceOver specific hints like reading the secret word letters individually if needed (maybe not, one can figure “CAT” vs “C.A.T.” – maybe not needed).
	•	Week 6: Finalization
	•	Localization: Export strings, get translations (or use Google Translate for placeholder if needed to test layout). Import into Xcode string catalog. Test switching language to Spanish, see that UI shows translated text. Make adjustments if some languages need different UI sizing (e.g., a long German phrase might need a multiline).
	•	Extensive testing: Run unit tests, UI tests. Achieve ~80% code coverage on critical files (Reducer, WordSelector). Fix any logic bugs found.
	•	Profile performance: use Instruments “Time Profiler” when generating image to ensure no major main-thread blockage. Also use “Memory” instrument to see memory usage doesn’t continually grow (no leaks).
	•	Optimize if needed (maybe turned some large arrays to lazy sequences if needed – probably fine).
	•	Prepare App Store assets: finalize app icon design, take screenshots in both light/dark mode if it looks nice (maybe prefer light for clarity, but dark might show glass nicely too). Maybe include one screenshot showing an AI-generated image in a clue.
	•	Double-check compliance: ensure no placeholder text or debug info remains (e.g., we should remove any print(secretWord) left in code for debugging).
	•	Submit to App Store, monitoring TestFlight for any issues on other devices.

14. Critical Research Checklist (for Agent/Developer)

Before and during implementation, ensure these topics are understood and referenced:
	•	Liquid Glass design system specification: Read Apple’s HIG and developer talks for Liquid Glass. Key points noted (transparency levels, .glassEffect usage, etc.)  .
	•	Semantic Color tokens: Confirm what system colors to use (we used .label, .systemBackground, etc., which align with semantic use ). Check if Apple provided any new named colors specifically for glass (possibly not explicitly, they rely on vibrancy).
	•	Typography scale: Verify the naming and sizes Apple uses (we approximated). If Apple provided a resource (like the SF Symbols or SF Font reference for new styles), incorporate that.
	•	Material APIs: Confirm correct usage of .glassEffect and GlassEffectContainer for performance . Also ensure understanding of .interactive() and .buttonStyle(.glass) for built-in interactions .
	•	Animation curves: See if Apple introduced new ones (we saw .bouncy). Confirm usage of .spring() parameters for good effect. Possibly consult WWDC session on SwiftUI animations in iOS 26 for any new static curves.
	•	Observation framework (iOS 26.2): Read up on Apple developer documentation for the Observation macro improvements, especially around thread-safety and re-entrancy to avoid any pitfalls with our design. Ensure knowledge of any gotchas (e.g., no nested @Observable objects? Not sure, check docs).
	•	SwiftUI Navigation (iOS 26): Confirm best practice for multi-phase flow. Perhaps use one NavigationStack and programmatically push different screens or use conditionals. Ensure no memory leaks in NavigationStack with Observables (maybe simpler: we might use a single view that switches on gamePhase instead of pushing new view – but then need nice transitions). Research what approach Apple suggests for wizard-like flows.
	•	Swift 6 Sendable: Check that our data types conform to Sendable where used across threads (we did mark some). For instance, RoundState.Clue is Sendable. If any warnings appear, address them (e.g., perhaps UIImage is not Sendable – we could avoid sending it across threads or mark appropriately).
	•	State machine pattern: Possibly look up articles or Apple sample for implementing game state logic. Though we did our own, ensure it covers edge cases.
	•	@Observable vs @StateObject performance: Confirm that using one @Observable GameStore for whole app is okay performance-wise, or if splitting into smaller Observables per feature would be better. According to WWDC, Observation is very efficient even for large models, so probably fine .
	•	Foundation Models usage: Read Apple’s documentation on the FoundationModels framework. Understand any setup needed (maybe nothing beyond import). Confirm if we need to include any large assets or if system provides them (system provides). Check if any entitlement or capability needed (shouldn’t, as it’s on-device and open to devs as per Apple’s WWDC talk).
	•	ImagePlayground specifics: Read the developer doc for ImageCreator and ImagePlaygroundViewController to ensure proper usage. For instance, confirm that creator.images(for: [.text(prompt)], style: .*) returns images progressively and how to handle that AsyncSequence properly (we did for try await). Also confirm available styles (sketch, illustration, etc.) and choose one that fits our aesthetic (sketch might be fun).
	•	Localization with String Catalog: Make sure how to use .xcstrings in SwiftUI (likely just using Text(“key”) works). Check if any issues reading localized strings in SwiftUI vs UIKit. Possibly use LocalizedStringKey for interpolation.
	•	SwiftUI accessibility: Review Apple’s accessibility guide for SwiftUI (like how to use AccessibilityAttachmentModifier, accessibilitySortedChildren if needed, etc.). Ensure understanding of reading order and grouping elements.
	•	Xcode 26 Release Notes: Skim for any known issues that might affect us (e.g., known bugs in Observation or navigation that we might need to work around).
	•	App Store Guidelines: Particularly, since we use AI-generated content, ensure it doesn’t violate any rule. Apple likely is okay with on-device generation. Also ensure no trademark issues (our game concept is generic enough, name “Imposter” should be fine – there is the game Among Us with impostor role, but “Imposter” as a generic term should be fine and our game is an independent implementation of a known party game concept).
	•	Community resources: Perhaps check SwiftUI forums or blogs for any tips on implementing multi-round games or using the new Observation API effectively, to avoid common pitfalls.

By completing this research and preparation, the development should proceed smoothly with fewer surprises.

15. Code Quality and Standards

15.1 Swift Style Guide

We follow Apple’s Swift API Design Guidelines for naming and clarity:
	•	Use uppercase camel for types, lowercase for properties and functions.
	•	Functions and properties named for clarity: e.g. createNewRound() rather than newRound to indicate an action.
	•	Minimize abbreviations, e.g., use playerCount not numP.
	•	Document complex logic with comments. Public API (if any) could use Swift Doc comments, though our app is mostly internal.
	•	Keep functions small and focused. E.g. our reducer’s cases are somewhat large; we might refactor chunks into helper functions (like we did with applyScoring).
	•	Avoid force-unwrapping optionals. Use guard/if let. In our code, we’ve done that for state.roundState usage etc.
	•	We will ensure any potential error is handled (like try? for JSON decode, we provided fallback).
	•	Use extensions to keep code organized (e.g., extension GamePhase to add a canTransition logic, done; extension Sequence or Collection for utilities if needed).
	•	Use MARK comments in code to separate sections (especially in large files like GameReducer).
	•	No magic numbers – we have constants for timings and limits (like 30 char limit clearly stated).

15.2 SwiftUI Best Practices
	•	Views are broken down logically (we have many small subviews). This aids reuse and testing.
	•	We keep state minimal in views; most state is in GameState. We use @State only for local UI toggles or text field content.
	•	We avoid excessive use of .force unwrap in SwiftUI (like if we had an optional image, we check it safely).
	•	For any complex view computations, use computed vars outside body to keep body simple.
	•	We consider using environment for things like GameStore (we did via @Environment(GameStore.self) after injecting it in App). This is a nice use of SwiftUI’s environment for global state.
	•	Use GeometryReader or .layoutPriority if needed to handle resizing text (for example, if one player’s name is very long, our ScoreboardRow might break layout; we could give the name Text a layoutPriority of 1 to ensure it truncates last maybe, etc.).
	•	Keep accessibility modifiers near the views they describe for clarity.
	•	Use of ZStack/overlays for visual effects as needed (we did some background overlays).
	•	We prefer SwiftUI built-in components (like Picker, ButtonStyle) where possible to leverage their default behavior (like localization of “Cancel”/“Save” if such text used – not needed here aside from our own strings).

15.3 Error Handling

Potential error scenarios:
	•	Starting game with insufficient players: We guard and ignore the action. We might present an alert in UI instead. But at least we handle it gracefully (no crash, just do nothing). Could set a custom error in state to show a message. Simpler: disable the Start button if invalid.
	•	Loading word packs failure: If JSON missing or corrupted, our WordSelector returns “ERROR” or “UNKNOWN”. We should not crash; at worst the secret word is “ERROR” which players will obviously know something’s wrong. We will ensure our packaged JSON is correct and perhaps during dev we assert if no word found. For extra safety, we could hardcode a backup word list in code so the game still playable if files missing.
	•	AI image generation error: We catch and simply do nothing (no image). We may want to notify user “Image generation failed” in a subtle way, but not critical. It’s a bonus feature. Possibly set a default “no image” icon to show instead if it fails.
	•	Concurrency errors: Since we use @MainActor and structured concurrency, we should be safe. If any non-Sendable slip through, Swift will warn in debug mode due to strict concurrency checking. We’ll fix those appropriately (e.g., if needed mark something as @UncheckedSendable, but likely not needed).
	•	We define a custom error enum ImposterError for a few scenarios (as in user prompt):

enum ImposterError: LocalizedError {
    case invalidPlayerCount
    case wordPackLoadingFailed
    case invalidGameState

    var errorDescription: String? {
        switch self {
        case .invalidPlayerCount:
            return NSLocalizedString("Game requires 3–10 players.", comment: "Error when starting game with too few players")
        case .wordPackLoadingFailed:
            return NSLocalizedString("Unable to load word list. Please reinstall the app or contact support.", comment: "Word pack missing error")
        case .invalidGameState:
            return NSLocalizedString("An unexpected error occurred. Please restart the game.", comment: "Generic game state error")
        }
    }
}

We might not actually throw these in code (because we instead prevent actions), but it’s there if needed for e.g. showing an alert if something seriously wrong happens.

If we had more time, we might add a global error handling: e.g., if any reducer case’s preconditions fail, we set an .invalidGameState error in state and the UI can show an alert and reset game.

16. References & Documentation

Apple Documentation:
	•	Human Interface Guidelines – Liquid Glass: Describes how the new material works and when to use it  . Emphasizes translucency adapting to environment and maintaining focus on content.
	•	SwiftUI API (iOS 26): Apple Developer Documentation for glassEffect and GlassEffectContainer  . This helped in implementing our design system and ensuring performance by grouping glass elements.
	•	Observation Framework: Apple’s WWDC talk “Meet Observation in SwiftUI” (2025) and documentation guided how to replace ObservableObject with @Observable for fine-grained updates .
	•	Foundation Models: Apple Developer Documentation for FoundationModels framework and the WWDC25 session “Meet the Foundation Models framework”  . These sources confirm the on-device model capabilities and usage.
	•	ImagePlayground: Apple Developer Doc for ImagePlayground (ImageCreator class)  and sample code from Apple’s site on how to call images(for: style:) and handle the AsyncSequence. This was crucial for implementing our AI image feature.
	•	WWDC Sessions: “Build a SwiftUI app with the new design” and “Meet Liquid Glass” gave insight into design tokens and interactive behaviors. For example, how text uses semantic styles (from a developer blog quoting Apple) , and how .interactive() adds effects .
	•	Xcode Release Notes: Ensured that building for iOS 26 requires Xcode 15 (which we reference as Xcode 26 in our numbering) . This ensures we use proper SDK.
	•	App Store Guidelines: Especially section 5 (Safety) and section 4 (Design) – our app avoids user-generated content online, so minimal concerns. Using on-device AI is new but should be within guidelines since no content leaves the device (so no issue with privacy or needing to filter inappropriate content server-side).

Third-Party Resources:
	•	Developer blog posts on implementing Liquid Glass in SwiftUI   which reinforced the need for semantic colors and an environment check for reduceTransparency.
	•	Swift forums for any early adopters of Foundation Models to see if any gotchas (e.g., memory footprint, required device capabilities).
	•	WWDC notes (like wwdcnotes.com) for quick reference of code snippets (the glassEffectID usage, etc., we referenced partly)  .
	•	UIKit vs SwiftUI Liquid Glass: some dev discussions indicated to prefer SwiftUI for easier integration. Our app is SwiftUI-first so that is fine.

We will keep these references handy throughout development to resolve any uncertainties.

17. Success Criteria

To declare the project successful, we set the following criteria:

MVP Completion:
	•	Support 3 to 10 players local gameplay with at least one round.
	•	The full game loop works: setup → role reveal → clue giving → (discussion) → voting → reveal → summary, without crashes or logic dead-ends.
	•	UI fully adopts Liquid Glass design for a modern look (translucent cards, dynamic backgrounds). It should feel “instantly iOS 26 native” when used  .
	•	Include at least 3 categories of words (with ~100+ words each) so replay value is decent.
	•	The AI-generated word mode works on devices that support it: user can input a prompt, and the players (except imposter) see an image for that word on their device. If device doesn’t support (older than A12), the feature should be hidden or disabled gracefully (maybe if ImageCreator.isSupported if such property exists).
	•	Basic accessibility: VoiceOver can be used to go through at least the voting process and identify who to vote; text is scalable without clipping major info.
	•	No data is sent off-device, and privacy info reflects that (so it should pass App Store privacy review easily).

Polish (stretch goals achieved):
	•	Smooth animations throughout: no jitter in transitions, and nice touches like bounce on reveal, subtle animations on button presses (we get that via .interactive glass by default).
	•	Haptic feedback on key actions (vote tap, reveal results).
	•	VoiceOver fully supported: The game can be played by a VoiceOver user instructing sighted players, or a group of visually impaired players could in theory use VoiceOver with the pass-and-play (though that might leak the word to all via audio – probably not fully, but at least ensure it doesn’t read secret word aloud unintentionally!). We might need to mark the secret word text as hidden from accessibility or use a label like “secret word, 5 letters” rather than reading the word, to avoid spoiling if one player is using VoiceOver and others can hear. This is a tricky scenario (multiple VO users in one game), likely out of scope, but we consider at least one VO user scenario.
	•	Localization into 5 languages (as listed).
	•	High score tracking: e.g., after game ends, if someone beat a previous high score, highlight it. This is an extra feature; we might simply record in UserDefaults the max score ever achieved and show it on summary or home (“High Score: X”).
	•	A simple tutorial or “How to Play” overlay for new users, explaining rules. We had a HowToPlaySheet trigger. Ensure it’s informative and concise.

Performance Targets:
	•	App launch time < 2s on average device (without any heavy content to load except maybe AI model on first use, which we do lazily). Cold launch might take a bit to load the model if we generate image immediately, but we do it on first game start, not launch.
	•	Steady 60 FPS during normal interactions (clue typing, scrolling, etc.). Possibly minor drop during AI generation, but should not freeze UI.
	•	Memory usage comfortably low: ideally under 100 MB for main game (not counting AI model which might not show in our app’s memory usage if it’s in a system process, not sure). With simple data and images, we should be well under that.
	•	No crashes or leaks found in extended play sessions (simulate playing 5 rounds in a row, etc.). Instruments Leaks tool should show 0 leaks after a few rounds.

We will test on an actual device (or multiple: e.g., an older iPhone that can run iOS 26 and a newer one) to ensure these performance criteria.

Once all criteria are met, Imposter should be ready for release as a fun, modern party game that showcases iOS 26’s design and capabilities.

Appendix A: Liquid Glass Research Notes

Color System:
Liquid Glass components automatically adapt their color based on the environment. Rather than using static colors, Apple emphasizes using semantic colors like .label, .systemBackground, etc., which become “vibrant” when placed on glass . The new design system likely introduced tints for glass as well, but under the hood those are applied via .glassEffect(.regular.tint(Color)). Our mapping of LGColors to system colors ensures that in Light mode text is dark on light backgrounds, and in Dark mode text is light on dark, and when layered on glass these get adjusted for contrast. Apple also provides user settings to adjust overall glass intensity, but that is handled by the system when using these APIs. In Reduce Transparency mode, our .glassEffect calls result in an opaque color, so by using primary/secondary label colors, text will still be readable . We also choose high contrast colors for player identifiers and ensure background isn’t purely white transparency (we added subtle strokes, shadows to differentiate layers).

For player colors, we picked a palette that is bright and distinct. We might add patterns or icons if needed for differentiation (not implemented yet).

Typography:
Apple’s Human Interface team adjusted typography for the new design – especially with how text appears on glass. They mention in the press release that SF typeface can dynamically adjust weight/width for certain contexts (like the Lock Screen clock) . For our app, we use standard dynamic type so that if user has accessibility bold text on, it automatically applies, etc. Liquid Glass design encourages bolder text for legibility on translucent backgrounds since backgrounds can be unpredictable. So we often use .bold() on titles and headings on glass (as seen in our styles). Our typography scale of Display/Headline/Body/Label is derived from iOS default styles, which should suffice. If Apple provided exact values (e.g., “Display Large: 44pt, medium: 36pt, small: 28pt”), we approximated. The key is we use relative sizes (Title, body etc.) that will respond to Dynamic Type.

Line heights and spacing: We used default line spacing from SwiftUI (which is generally fine). If needed, we can adjust by applying .lineSpacing or .leading modifiers for multi-line text (like RoleCard imposter description we center and allow multiline).

Materials & Effects:
Liquid Glass offers a regular and clear variant – we mainly use regular for moderate translucency. The clear variant is more transparent, intended for overlay on busy backgrounds  (not heavily needed in our app because our backgrounds aren’t too busy behind small controls). But if we had, say, a floating toolbar on a photo (like their example), we’d use clear with a dimming behind it. We ensure that if content behind glass is very bright, the glass provides a dimming effect automatically (this is part of .regular behavior). We have to trust the system’s composition.

Depth: We incorporate subtle shadows to layer elements. Also note: Apple’s design language uses parallax and motion to convey depth (specular highlights move with device tilt) . The .glassEffect likely already does some of that – but only on actual device, might see a slight sheen when moving device (like Control Center in iOS 26 does). That’s automatic with .interactive() possibly, or built-in for certain system components. We won’t simulate device motion highlights manually.

Corner radius values: Apple often uses 12 for small elements, 20 for cards, 34 for full-screen sheets (to match device corner). We used 20 for cards, which is a nice round number. Using .containerConcentric corner style could align to container (like if we had a big panel aligning to screen, we could use that to match screen corner radius)  . In our case, our panel (like settings background in setup) we gave 16 which is fine. A possibly nice touch: for the summary sheet perhaps use .containerConcentric to match iPad corner radius if it’s a sheet. Could refine later.

Animation:
We utilize spring animations for reveal. Apple introduced .bouncy as shorthand for a spring with certain damping. If available, we could use withAnimation(.bouncy) as seen in WWDC examples  . We opted to manually set spring parameters to control it. Other new animations in iOS 26 include .smooth and .snappy (some new easing curves). Possibly .spring covers our needs. We should keep animations snappy (~0.5 to 1s) so players aren’t waiting too long, but also not instant – drama is fun.

During clue phase, we don’t animate transitions between players (it just re-renders new view content). That might be fine, but perhaps adding a subtle slide transition when changing current clue giver could be nice. If desired, we could wrap ClueRoundView in a TabView or manual transition. Not critical.

Standard Component Patterns:
Liquid Glass being new means standard UIKit components got updated (like NavigationBar, TabBar automatically glassy). We used NavigationStack, which on iOS 26 likely has a glass nav bar by default (but we hid it on home and others). On summary, maybe we’d show a nav bar title that is glassy, but our design uses custom titles.

Spacing conventions: We used our LGSpacing (not explicitly defined in code above, but presumably small=4, medium=8, large=16, xlarge=24, etc.). These are fairly standard multiples that align well. We ensure consistent use (we mostly did). Buttons padding we used 12 vertical, 20 horizontal which is fine.

Touch target: All our buttons have at least 44px height (LGButton ensures at least 44 with padding). Player vote cards are 100x100 min, fine. The color circle in setup is 30x30 which is a bit small – but we allow tapping it to change color. According to guidelines, 44x44 is minimum. Perhaps we should enlarge that interactive area. We could wrap it in a 44x44 frame with transparent background for tapping. That’s an improvement to consider.

Safe areas: Our views either center content (like reveal) or use padding to avoid edges. We ensure in fullscreen devices nothing crucial is under camera cutouts or corners. We call .ignoresSafeArea() for our background gradient on Home, which is correct. For content, SwiftUI by default respects safe area, which is fine. On some screens, we manually add bottom padding where needed for safe area (like .padding(.bottom, 30) in voting for example) – might revise if environment values used instead, but okay.

Appendix B: Alternative Architecture Considered

We deliberated using The Composable Architecture (TCA) by Point-Free to structure the game logic. Pros: TCA is very testable and modular, with a clear separation of effects. Cons: It introduces complexity and an external dependency, which might be overkill for our app. Also, with SwiftUI’s new Observation, some of TCA’s advantages (like needing to use @ObservedObject) are less compelling on iOS 26. We decided to implement a simpler redux-like pattern ourselves, which is sufficient given the app scope (we have relatively few actions and straightforward state).

We also considered a classic MVVM approach with Combine (each view has a ViewModel that publishes changes). This is familiar but since Observation is the future, we opted to use @Observable single-store to simplify global state sharing (no need to prop drill or use EnvironmentObject extensively).

One could also structure as multi-scene (e.g., separate SwiftUI views for each phase, each with their own ViewModel), but since our game flows linearly through phases, a single state machine made sense.

Conclusion: The chosen unidirectional data flow with Observation gives us the benefits of predictability and Swift concurrency safety without an external library, aligning with Apple’s latest tech.

⸻

Document Revision History:
	•	v0.1 (Draft): Initial plan outline created with sections 1–17 enumerated.
	•	v0.2: Updated to set iOS 26 as minimum (not 26.2) and incorporate detailed UI design choices for Liquid Glass. Added AI word generation feature in sections 7 and 6 (RoleReveal integration).
	•	v0.3: Incorporated research citations from Apple documentation and developer articles to back design decisions. Expanded Accessibility and Localization plans.
	•	v1.0 (Final): Polished timeline, success criteria, and verified that all new features (categories, ALFM image generation) are integrated into the architecture and schedule.