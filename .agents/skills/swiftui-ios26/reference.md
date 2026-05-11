# SwiftUI iOS 26 Reference Code

## Complete @Observable Store Pattern

```swift
import SwiftUI

// MARK: - State
@Observable
final class GameState: Sendable {
    var players: [Player] = []
    var currentPhase: GamePhase = .setup
    var roundState: RoundState?
    var settings: GameSettings = .default
}

// MARK: - Store
@Observable
@MainActor
final class GameStore {
    private(set) var state: GameState
    
    init(state: GameState = GameState()) {
        self.state = state
    }
    
    func dispatch(_ action: GameAction) {
        let newState = GameReducer.reduce(state: state, action: action)
        
        // Validate phase transition
        if newState.currentPhase != state.currentPhase {
            guard state.currentPhase.canTransition(to: newState.currentPhase) else {
                print("Invalid transition: \(state.currentPhase) → \(newState.currentPhase)")
                return
            }
        }
        
        state = newState
    }
}

// MARK: - Reducer (Pure)
enum GameReducer {
    static func reduce(state: GameState, action: GameAction) -> GameState {
        var newState = state
        
        switch action {
        case .addPlayer(let name, let color):
            newState.players.append(Player(name: name, color: color))
            
        case .startGame:
            guard newState.players.count >= 3 else { return state }
            newState.currentPhase = .roleReveal
            newState.roundState = createNewRound(players: newState.players)
            
        // ... other cases
        }
        
        return newState
    }
    
    private static func createNewRound(players: [Player]) -> RoundState {
        // Implementation
    }
}
```

## Phase-Based View Switching

```swift
struct GameContainerView: View {
    @Environment(GameStore.self) private var store
    
    var body: some View {
        Group {
            switch store.state.currentPhase {
            case .setup:
                PlayerSetupView()
            case .roleReveal:
                RoleRevealView()
            case .clueRound:
                ClueRoundView()
            case .discussion:
                DiscussionView()
            case .voting:
                VotingView()
            case .reveal:
                RevealView()
            case .summary:
                SummaryView()
            }
        }
        .animation(.easeInOut, value: store.state.currentPhase)
    }
}
```

## GamePhase State Machine

```swift
enum GamePhase: String, Codable, CaseIterable, Sendable {
    case setup
    case roleReveal
    case clueRound
    case discussion
    case voting
    case reveal
    case summary
    
    func canTransition(to next: GamePhase) -> Bool {
        switch (self, next) {
        case (.setup, .roleReveal),
             (.roleReveal, .clueRound),
             (.clueRound, .discussion),
             (.clueRound, .voting),
             (.discussion, .voting),
             (.voting, .reveal),
             (.reveal, .summary),
             (.summary, .roleReveal),
             (.summary, .setup):
            return true
        default:
            return false
        }
    }
}
```

## Async Side Effects Pattern

```swift
@Observable
@MainActor
final class GameStore {
    private(set) var state: GameState
    
    func dispatch(_ action: GameAction) {
        // 1. Reduce synchronously
        state = GameReducer.reduce(state: state, action: action)
        
        // 2. Handle side effects after state update
        handleSideEffects(for: action)
    }
    
    private func handleSideEffects(for action: GameAction) {
        switch action {
        case .startGame where state.settings.wordSource == .customPrompt:
            generateSecretImage()
        default:
            break
        }
    }
    
    private func generateSecretImage() {
        guard let prompt = state.roundState?.secretWord else { return }
        
        Task.detached(priority: .userInitiated) {
            do {
                let image = try await self.createImage(for: prompt)
                await MainActor.run {
                    self.state.roundState?.generatedImage = image
                }
            } catch {
                print("Image generation failed: \(error)")
            }
        }
    }
}
```

## Safe Array Access Extension

```swift
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Usage
let player = players[safe: currentIndex]
```

## Binding from Store Pattern

```swift
struct PlayerSetupView: View {
    @Environment(GameStore.self) private var store
    
    var body: some View {
        ForEach(store.state.players) { player in
            PlayerRowView(player: binding(for: player))
        }
    }
    
    private func binding(for player: Player) -> Binding<Player> {
        Binding(
            get: { player },
            set: { newValue in
                store.dispatch(.updatePlayer(
                    id: newValue.id,
                    name: newValue.name,
                    color: newValue.color
                ))
            }
        )
    }
}
```
