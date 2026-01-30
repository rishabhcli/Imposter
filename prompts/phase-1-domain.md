# Phase 1: Domain Layer – Agent Prompt

## Objective
Implement all core data models, the action enum, state machine, and pure reducer logic.

## Context
- Read `CLAUDE.md` for architecture overview
- Load `.claude/skills/game-logic/` for reducer patterns
- Reference `Implementation Plan.md` Sections 2-4 for detailed specifications

## Tasks

### 1. Models (`Domain/Models/`)

#### Player.swift
```swift
struct Player: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var color: PlayerColor
    var score: Int
    var isEliminated: Bool
}

enum PlayerColor: String, Codable, CaseIterable, Sendable {
    case crimson, azure, emerald, amber, violet, coral, teal, rose
}
```

#### GamePhase.swift
- Implement enum with all 7 cases
- Add `canTransition(to:) -> Bool` method
- Mark as `Sendable`

#### GameSettings.swift
- `WordSource` enum (randomPack, customPrompt)
- `Difficulty` enum (easy, medium, hard, mixed)
- All configurable properties from spec
- `static let default` preset

#### RoundState.swift
- secretWord, imposterID, clues, votes, currentClueIndex
- Nested `Clue` struct
- Optional `generatedImage: UIImage?`

#### GameState.swift
- `@Observable` class
- players, settings, currentPhase, roundState, roundNumber, gameHistory

### 2. Actions (`Domain/Actions/`)

#### GameAction.swift
- Define all action cases per spec (setup, roleReveal, clueRound, voting, reveal, summary)
- Mark as `Sendable`

### 3. Logic (`Domain/Logic/`)

#### GameReducer.swift
- `static func reduce(state:action:) -> GameState`
- Handle all action cases
- Implement helper functions: `createNewRound`, `calculateVotingResult`, `applyScoring`

#### WordSelector.swift
- `static func selectWord(from:) -> String`
- Load JSON word packs
- Filter by category and difficulty

#### ScoringEngine.swift (optional)
- Can be inlined in reducer or extracted

### 4. Store (`Store/`)

#### GameStore.swift
- `@Observable @MainActor` class
- `dispatch(_:)` method with phase validation
- Derived properties: `currentPlayer`, `isImposter(_:)`
- Side effect handling for AI image generation

## Acceptance Criteria
- [ ] All models compile with Sendable conformance
- [ ] GamePhase.canTransition validates all valid/invalid paths
- [ ] Reducer handles every GameAction case
- [ ] No side effects inside reducer (pure function)
- [ ] GameStore correctly validates phase transitions

## Testing Focus
Write unit tests for:
- `GameReducer.reduce` with addPlayer, startGame, submitClue, castVote
- `GamePhase.canTransition` edge cases
- `WordSelector` filtering logic

## Next Phase
After completion, proceed to **Phase 2: Design System**.

---

## Ralph Loop Checklist
- [ ] Read skill: `.claude/skills/game-logic/`
- [ ] Create model files
- [ ] Implement reducer
- [ ] Verify compilation
- [ ] Write basic unit tests
- [ ] Update `TASKS.md`
