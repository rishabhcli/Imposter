# Game Logic Reference Code

## Complete GameAction Enum

```swift
enum GameAction: Sendable {
    // Setup Phase
    case addPlayer(name: String, color: PlayerColor)
    case removePlayer(id: UUID)
    case updatePlayer(id: UUID, name: String, color: PlayerColor)
    case updateSettings(GameSettings)
    case startGame
    
    // Role Reveal Phase
    case revealRoleToPlayer(id: UUID)
    case completeRoleReveal
    
    // Clue Round Phase
    case submitClue(playerID: UUID, text: String)
    case advanceToNextClue
    case completeClueRounds
    
    // Discussion & Voting Phase
    case startDiscussion
    case endDiscussion
    case startVoting
    case castVote(voterID: UUID, suspectID: UUID)
    case completeVoting
    
    // Reveal Phase
    case revealImposter
    case imposterGuessWord(guess: String)
    case completeRound
    
    // Summary/Reset
    case startNewRound
    case endGame
    case returnToHome
}
```

## GameReducer Implementation

```swift
enum GameReducer {
    static func reduce(state: GameState, action: GameAction) -> GameState {
        var newState = state
        
        switch action {
        // MARK: - Setup Actions
        case .addPlayer(let name, let color):
            guard newState.players.count < 10 else { return state }
            let player = Player(name: name, color: color)
            newState.players.append(player)
            
        case .removePlayer(let id):
            guard newState.players.count > 3 else { return state }
            newState.players.removeAll { $0.id == id }
            
        case .updatePlayer(let id, let name, let color):
            if let idx = newState.players.firstIndex(where: { $0.id == id }) {
                newState.players[idx].name = name
                newState.players[idx].color = color
            }
            
        case .updateSettings(let settings):
            newState.settings = settings
            
        case .startGame:
            guard newState.players.count >= 3 else { return state }
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            newState.roundState = createNewRound(
                players: newState.players,
                settings: newState.settings
            )
            
        // MARK: - Role Reveal Actions
        case .revealRoleToPlayer:
            // Track which players have seen their role if needed
            break
            
        case .completeRoleReveal:
            newState.currentPhase = .clueRound
            
        // MARK: - Clue Round Actions
        case .submitClue(let playerID, let text):
            guard var round = newState.roundState else { break }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 30 else { break }
            
            let clue = RoundState.Clue(
                id: UUID(),
                playerID: playerID,
                text: trimmed,
                timestamp: Date(),
                roundIndex: round.currentClueIndex / newState.players.count
            )
            round.clues.append(clue)
            round.currentClueIndex += 1
            newState.roundState = round
            
            // Auto-advance phase if all clues done
            let totalClues = newState.players.count * newState.settings.numberOfClueRounds
            if round.currentClueIndex >= totalClues {
                if newState.settings.discussionTimerEnabled {
                    newState.currentPhase = .discussion
                } else {
                    newState.currentPhase = .voting
                }
            }
            
        case .advanceToNextClue:
            // Manual advancement if needed
            break
            
        case .completeClueRounds:
            if newState.settings.discussionTimerEnabled {
                newState.currentPhase = .discussion
            } else {
                newState.currentPhase = .voting
            }
            
        // MARK: - Discussion & Voting Actions
        case .startDiscussion:
            newState.currentPhase = .discussion
            
        case .endDiscussion:
            newState.currentPhase = .voting
            
        case .startVoting:
            newState.currentPhase = .voting
            
        case .castVote(let voterID, let suspectID):
            guard voterID != suspectID else { return state } // Can't vote self
            newState.roundState?.votes[voterID] = suspectID
            
            // Auto-complete if all voted
            if let round = newState.roundState,
               round.votes.count == newState.players.count {
                newState.currentPhase = .reveal
            }
            
        case .completeVoting:
            newState.currentPhase = .reveal
            
        // MARK: - Reveal Actions
        case .revealImposter:
            // Animation trigger handled by UI
            break
            
        case .imposterGuessWord(let guess):
            guard let round = newState.roundState else { break }
            let correct = guess.lowercased().trimmingCharacters(in: .whitespaces) ==
                         round.secretWord.lowercased().trimmingCharacters(in: .whitespaces)
            if correct {
                // Award bonus points to imposter
                if let idx = newState.players.firstIndex(where: { $0.id == round.imposterID }) {
                    newState.players[idx].score += newState.settings.pointsForImposterGuess
                }
            }
            
        case .completeRound:
            if let round = newState.roundState {
                let result = calculateVotingResult(roundState: round)
                applyScoring(to: &newState, result: result)
                
                // Archive round
                let completed = CompletedRound(from: round, result: result)
                newState.gameHistory.append(completed)
            }
            newState.currentPhase = .summary
            
        // MARK: - Summary Actions
        case .startNewRound:
            newState.roundState?.generatedImage = nil // Free memory
            newState.roundNumber += 1
            newState.currentPhase = .roleReveal
            newState.roundState = createNewRound(
                players: newState.players,
                settings: newState.settings
            )
            
        case .endGame:
            newState.currentPhase = .summary
            
        case .returnToHome:
            newState = GameState(players: [], settings: newState.settings)
        }
        
        return newState
    }
    
    // MARK: - Helpers
    
    private static func createNewRound(players: [Player], settings: GameSettings) -> RoundState {
        let word: String
        if settings.wordSource == .customPrompt,
           let prompt = settings.customWordPrompt,
           !prompt.isEmpty {
            word = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            word = WordSelector.selectWord(from: settings)
        }
        
        let imposter = players.randomElement()!
        
        return RoundState(
            secretWord: word,
            imposterID: imposter.id,
            clues: [],
            votes: [:],
            currentClueIndex: 0
        )
    }
    
    private static func calculateVotingResult(roundState: RoundState) -> VotingResult {
        // Tally votes
        var voteCounts: [UUID: Int] = [:]
        for suspectID in roundState.votes.values {
            voteCounts[suspectID, default: 0] += 1
        }
        
        // Find most voted
        let mostVoted = voteCounts.max(by: { $0.value < $1.value })?.key
        let isCorrect = (mostVoted == roundState.imposterID)
        
        return VotingResult(
            mostVotedPlayerID: mostVoted,
            imposterID: roundState.imposterID,
            isCorrect: isCorrect
        )
    }
    
    private static func applyScoring(to state: inout GameState, result: VotingResult) {
        if result.isCorrect {
            // Non-imposters guessed correctly
            for i in state.players.indices where state.players[i].id != result.imposterID {
                state.players[i].score += state.settings.pointsForCorrectVote
            }
        } else {
            // Imposter survived
            if let idx = state.players.firstIndex(where: { $0.id == result.imposterID }) {
                state.players[idx].score += state.settings.pointsForImposterSurvival
            }
        }
    }
}
```

## VotingResult Struct

```swift
struct VotingResult: Sendable {
    let mostVotedPlayerID: UUID?
    let imposterID: UUID
    let isCorrect: Bool
}
```

## CompletedRound Struct

```swift
struct CompletedRound: Codable, Sendable {
    let roundNumber: Int
    let secretWord: String
    let imposterID: UUID
    let wasImposterCaught: Bool
    let votes: [UUID: UUID]
    
    init(from round: RoundState, result: VotingResult, roundNumber: Int = 0) {
        self.roundNumber = roundNumber
        self.secretWord = round.secretWord
        self.imposterID = round.imposterID
        self.wasImposterCaught = result.isCorrect
        self.votes = round.votes
    }
}
```

## WordSelector

```swift
enum WordSelector {
    static func selectWord(from settings: GameSettings) -> String {
        let categoryFiles: [String]
        if let selected = settings.selectedCategories, !selected.isEmpty {
            categoryFiles = selected.map { "words_\($0.lowercased())" }
        } else {
            categoryFiles = ["words_animals", "words_technology", "words_objects"]
        }
        
        var candidates: [String] = []
        for file in categoryFiles {
            if let pack = loadWordPack(named: file) {
                let filtered = pack.words.filter { entry in
                    switch settings.wordPackDifficulty {
                    case .easy: return entry.difficulty == .easy
                    case .medium: return entry.difficulty == .medium
                    case .hard: return entry.difficulty == .hard
                    case .mixed: return true
                    }
                }
                candidates.append(contentsOf: filtered.map { $0.word })
            }
        }
        
        return candidates.randomElement() ?? "UNKNOWN"
    }
    
    private static func loadWordPack(named name: String) -> WordPack? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(WordPack.self, from: data)
    }
}

struct WordPack: Codable {
    let category: String
    let words: [WordEntry]
    
    struct WordEntry: Codable {
        let word: String
        let difficulty: GameSettings.Difficulty
    }
}
```
