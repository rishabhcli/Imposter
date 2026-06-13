//
//  GameReducer.swift
//  Imposter
//
//  Pure state transition logic for all game actions.
//

import Foundation

// MARK: - GameReducer

/// Pure reducer that computes new GameState from current state and an action.
/// Contains no side effects - all state changes are deterministic.
enum GameReducer {
    private static let recentWordAvoidanceLimit = 12

    // MARK: - Main Reducer

    /// Processes an action and returns a new game state.
    /// - Parameters:
    ///   - state: The current game state
    ///   - action: The action to process
    /// - Returns: A new game state reflecting the action
    static func reduce(state: GameState, action: GameAction) -> GameState {
        var newState = state

        switch action {

        // MARK: Setup Actions

        case .addPlayer(let name, let color):
            guard newState.currentPhase == .setup else { return state }
            guard newState.players.count < 10 else { return state }
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return state }
            let player = Player(name: trimmedName, color: color)
            newState.players.append(player)

        case .removePlayer(let id):
            guard newState.currentPhase == .setup else { return state }
            guard newState.players.count > 0 else { return state }
            newState.players.removeAll { $0.id == id }

        case .updatePlayer(let id, let name, let color):
            guard newState.currentPhase == .setup else { return state }
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { return state }
            if let idx = newState.players.firstIndex(where: { $0.id == id }) {
                newState.players[idx].name = trimmedName
                newState.players[idx].color = color
            }

        case .updateSettings(let settings):
            guard newState.currentPhase == .setup else { return state }
            newState.settings = GameRules.normalized(settings)

        case .setGeneratedWord(let word, let imposterWord):
            // Update the secret word in the current round (used for AI-generated words)
            guard let round = newState.roundState else { return state }
            // Create new round with the generated word but keep the same imposter and categoryHint
            newState.roundState = RoundState(
                secretWord: word,
                imposterWord: imposterWord ?? round.imposterWord,
                categoryHint: round.categoryHint,
                imposterHint: round.imposterHint,
                imposterID: round.imposterID,
                clues: round.clues,
                votes: round.votes,
                currentClueIndex: round.currentClueIndex,
                revealIndex: round.revealIndex
            )

        case .setImposterHint(let hint):
            // Update the imposter hint in the current round
            guard var round = newState.roundState else { return state }
            round.imposterHint = hint
            newState.roundState = round

        case .startGame:
            guard newState.currentPhase == .setup else { return state }
            let validation = GameRules.validation(settings: newState.settings, playerCount: newState.players.count)
            guard validation.canStart else { return state }
            newState.settings = validation.settings
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            newState.roundState = createNewRound(
                players: newState.players,
                settings: newState.settings,
                avoiding: recentSecretWords(from: newState.gameHistory)
            )

        case .startGameWithPreparedRound(let roundState):
            guard newState.currentPhase == .setup else { return state }
            let validation = GameRules.validation(settings: newState.settings, playerCount: newState.players.count)
            guard validation.canStart else { return state }
            newState.settings = validation.settings
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            newState.roundState = roundState

        // MARK: Role Reveal Actions

        case .revealRoleToPlayer(_):
            guard newState.currentPhase == .roleReveal else { return state }
            guard var round = newState.roundState else { return state }
            round.revealIndex += 1
            newState.roundState = round

        case .completeRoleReveal:
            guard newState.currentPhase == .roleReveal else { return state }
            newState.currentPhase = .clueRound

        // MARK: Clue Round Actions

        case .submitClue(let playerID, let text):
            guard newState.currentPhase == .clueRound else { return state }
            guard var round = newState.roundState else { return state }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return state }

            let roundIndex = round.currentClueIndex / newState.players.count
            let clue = RoundState.Clue(
                playerID: playerID,
                text: trimmed,
                roundIndex: roundIndex
            )
            round.clues.append(clue)
            round.currentClueIndex += 1
            newState.roundState = round

            // Check if all clues have been given.
            let totalCluesNeeded = newState.players.count * newState.settings.numberOfClueRounds
            if round.currentClueIndex >= totalCluesNeeded {
                newState.currentPhase = .discussion
            }

        case .advanceToNextClue:
            // This action is handled implicitly in submitClue
            break

        case .completeClueRounds:
            guard newState.currentPhase == .clueRound else { return state }
            newState.currentPhase = .discussion

        // MARK: Discussion & Voting Actions

        case .startDiscussion:
            guard newState.currentPhase.canTransition(to: .discussion) else { return state }
            newState.currentPhase = .discussion

        case .endDiscussion:
            guard newState.currentPhase == .discussion else { return state }
            newState.currentPhase = .voting

        case .startVoting:
            guard newState.currentPhase.canTransition(to: .voting) else { return state }
            newState.currentPhase = .voting

        case .castVote(let voterID, let suspectID):
            guard newState.currentPhase == .voting else { return state }
            guard var round = newState.roundState else { return state }
            // Verify voter and suspect are valid players
            guard newState.players.contains(where: { $0.id == voterID }) else { return state }
            guard newState.players.contains(where: { $0.id == suspectID }) else { return state }
            guard voterID != suspectID else { return state }

            round.votes[voterID] = suspectID
            newState.roundState = round

            // Auto-complete voting if everyone has voted
            if round.votes.count >= newState.players.count {
                newState.currentPhase = .reveal
            }

        case .completeVoting:
            guard newState.currentPhase == .voting else { return state }
            guard let round = newState.roundState else { return state }
            guard round.votes.count >= newState.players.count else { return state }
            newState.currentPhase = .reveal

        // MARK: Reveal Actions

        case .revealImposter:
            guard newState.currentPhase == .reveal else { return state }
            // UI handles the reveal animation

        case .imposterGuessWord(_):
            guard newState.currentPhase == .reveal else { return state }
            // Handled in completeRound

        case .completeRound(let imposterGuessedCorrectly):
            guard newState.currentPhase == .reveal else { return state }
            guard let roundState = newState.roundState else { return state }

            // Calculate and apply scores
            let scores = ScoringEngine.calculate(
                roundState: roundState,
                players: newState.players,
                settings: newState.settings,
                imposterGuessedCorrectly: imposterGuessedCorrectly
            )
            newState.players = ScoringEngine.applyScores(scores, to: newState.players)

            // Archive the completed round
            var votingResult = Self.calculateVotingResult(roundState: roundState)
            votingResult.imposterGuessedCorrectly = imposterGuessedCorrectly
            let imposterName = newState.players.first { $0.id == roundState.imposterID }?.name ?? "Unknown"
            let completedRound = CompletedRound(
                from: roundState,
                result: votingResult,
                roundNumber: newState.roundNumber,
                imposterName: imposterName
            )
            newState.gameHistory.append(completedRound)

            // Clear round state and move to summary
            newState.roundState = nil
            newState.currentPhase = .summary

        // MARK: Summary/Reset Actions

        case .startNewRound:
            guard newState.currentPhase == .summary else { return state }
            // Clear any lingering image from previous round
            newState.roundState?.generatedImage = nil
            newState.settings = GameRules.normalized(newState.settings)
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            newState.roundState = createNewRound(
                players: newState.players,
                settings: newState.settings,
                avoiding: recentSecretWords(from: newState.gameHistory)
            )

        case .startNewRoundWithPreparedRound(let roundState):
            guard newState.currentPhase == .summary else { return state }
            newState.settings = GameRules.normalized(newState.settings)
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            newState.roundState = roundState

        case .endGame:
            guard newState.currentPhase == .summary else { return state }
            // Stay in summary but mark game as ended

        case .returnToHome:
            // Reset to initial state but keep settings
            let settings = newState.settings
            return GameState(settings: settings)

        case .resetGame:
            return GameState()
            
        case .wordGenerationFailed(let error):
            // Word generation failed - log error and stay in current state
            // GameStore will handle showing the error to the user
            #if DEBUG
            print("[GameReducer] Word generation failed: \(error.message)")
            #endif
            return state

        case .imageGenerationFailed(let error):
            // Image generation failed - log error and stay in current state
            // GameStore will handle showing the error to the user
            #if DEBUG
            print("[GameReducer] Image generation failed: \(error.message)")
            #endif
            return state

        case .storageFailed(let error):
            // Storage operation failed - log error and stay in current state
            // GameStore will handle showing the error to the user
            #if DEBUG
            print("[GameReducer] Storage operation failed: \(error.message)")
            #endif
            return state

        case .setGeneratedImage(let image):
            // Set the generated image for the current round
            guard var round = newState.roundState else { return state }
            round.generatedImage = image
            newState.roundState = round
        }

        return newState
    }

    // MARK: - Helper Functions

    /// Creates a new round state with a random word and random imposter
    /// Note: When using custom prompt, sets a placeholder - GameStore will generate the actual word
    static func createNewRound(
        players: [Player],
        settings: GameSettings,
        avoiding avoidedWords: Set<String> = []
    ) -> RoundState {
        let settings = GameRules.normalized(settings)
        let word: String
        let categoryHint: String

        if settings.wordSource == .customPrompt {
            // Use placeholder - GameStore will generate the actual word using Foundation Models
            word = "GENERATING..."
            // The hint for the imposter is the user's theme/prompt
            categoryHint = settings.customWordPrompt ?? "Custom"
        } else {
            word = WordSelector.selectWord(from: settings, avoiding: avoidedWords)
            // The hint for the imposter is the category name(s)
            if let categories = settings.selectedCategories, !categories.isEmpty {
                categoryHint = categories.joined(separator: ", ")
            } else {
                categoryHint = "Mixed"
            }
        }

        // Select random imposter
        guard let imposter = players.randomElement() else {
            // Fallback - should never happen with valid player count
            return RoundState(secretWord: word, categoryHint: categoryHint, imposterID: UUID(), firstPlayerIndex: 0)
        }

        // Select random first player who is NOT the imposter
        let nonImposterIndices = players.indices.filter { players[$0].id != imposter.id }
        let firstPlayerIndex = nonImposterIndices.randomElement() ?? 0

        // In hidden mode, select a different word for the imposter
        let imposterWord: String?
        if settings.gameMode == .hidden && settings.wordSource != .customPrompt {
            imposterWord = WordSelector.selectAlternateWord(
                matching: word,
                from: settings,
                avoiding: avoidedWords
            )
        } else {
            imposterWord = nil
        }

        return RoundState(
            secretWord: word,
            imposterWord: imposterWord,
            categoryHint: categoryHint,
            imposterID: imposter.id,
            firstPlayerIndex: firstPlayerIndex
        )
    }

    static func recentSecretWords(
        from history: [CompletedRound],
        limit: Int = recentWordAvoidanceLimit
    ) -> Set<String> {
        Set(history.suffix(limit).map(\.secretWord))
    }

    /// Calculates the voting result from the current round state
    static func calculateVotingResult(roundState: RoundState) -> VotingResult {
        // Tally votes
        var voteCounts: [UUID: Int] = [:]
        for suspectID in roundState.votes.values {
            voteCounts[suspectID, default: 0] += 1
        }

        // Find the player(s) with the most votes
        let maxVotes = voteCounts.values.max() ?? 0
        let playersWithMaxVotes = voteCounts.filter { $0.value == maxVotes }.map { $0.key }
        let isTie = playersWithMaxVotes.count > 1

        // In a tie, no single player is "most voted"
        let mostVoted: UUID? = isTie ? nil : playersWithMaxVotes.first
        let isCorrect = !isTie && mostVoted == roundState.imposterID

        return VotingResult(
            mostVotedPlayerID: mostVoted,
            imposterID: roundState.imposterID,
            isCorrect: isCorrect,
            voteCounts: voteCounts,
            isTie: isTie
        )
    }

}
