# Game Logic Skill

## When to Load
Load this skill when:
- Implementing or modifying the GameReducer
- Working with game state transitions
- Implementing scoring logic
- Handling voting outcomes

## Core Principles

### 1. Reducer is Pure
- No side effects (network, I/O, random outside of helpers)
- Takes state + action → returns new state
- Deterministic for same inputs

### 2. State Machine Enforced
- All phase transitions go through `canTransition(to:)`
- Invalid transitions are rejected
- Ensures game flow integrity

### 3. Single Source of Truth
- `GameState` holds ALL game data
- Views read from state, never modify directly
- Actions are the only way to change state

## Game Flow

```
setup → roleReveal → clueRound → [discussion] → voting → reveal → summary
                                                                    ↓
                                                              roleReveal (new round)
                                                                    OR
                                                                  setup (new game)
```

## Scoring Rules

| Scenario | Points |
|----------|--------|
| Non-imposter votes correctly | `pointsForCorrectVote` (default: 1) |
| Imposter survives (not voted out) | `pointsForImposterSurvival` (default: 2) |
| Imposter guesses word correctly | `pointsForImposterGuess` (default: 3) |

## Key Validation Points

1. **Start Game**: Require 3+ players
2. **Submit Clue**: Non-empty, max 30 chars
3. **Cast Vote**: Can't vote for self
4. **Phase Transitions**: Only valid paths allowed

## Reference

See `reference.md` for complete reducer implementation patterns.
