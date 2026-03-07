# Imposter – AI Agent Instructions

> **Single Source of Truth** for the Imposter iOS app. Read this file at the start of every session.

---

## Project Overview

**Imposter** is a local-only social deduction party game for iOS 26+ (3–10 players, pass-and-play). One player is secretly the "Imposter" who doesn't know the secret word; players give clues and vote to identify the Imposter.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Platform** | iOS 26.0+ (iPhone/iPad) |
| **Language** | Swift 6 (strict concurrency) |
| **UI Framework** | SwiftUI + Observation framework |
| **Design System** | Apple Liquid Glass |
| **AI/ML** | FoundationModels + ImagePlayground (on-device) |
| **Architecture** | Unidirectional data flow (Redux-like) |
| **Persistence** | UserDefaults |
| **Testing** | XCTest + XCUITest |

---

## Project Structure

```
Imposter/
├── App/
│   ├── ImposterApp.swift          # @main entry point
│   └── AppEnvironment.swift       # Dependency injection
├── Domain/
│   ├── Models/
│   │   ├── GameState.swift        # @Observable central state
│   │   ├── Player.swift           # Player model
│   │   ├── RoundState.swift       # Per-round state
│   │   ├── GamePhase.swift        # State machine enum
│   │   └── GameSettings.swift     # Configurable options
│   ├── Actions/
│   │   └── GameAction.swift       # All possible actions
│   └── Logic/
│       ├── GameReducer.swift      # Pure state transitions
│       ├── WordSelector.swift     # Word selection logic
│       └── ScoringEngine.swift    # Points calculation
├── Store/
│   └── GameStore.swift            # @Observable store with dispatch()
├── Features/
│   ├── Home/
│   ├── Setup/
│   ├── RoleReveal/
│   ├── ClueRound/
│   ├── Voting/
│   ├── Reveal/
│   └── Summary/
├── DesignSystem/
│   ├── LiquidGlass/
│   │   ├── LGColors.swift
│   │   ├── LGTypography.swift
│   │   ├── LGSpacing.swift
│   │   ├── LGMaterials.swift
│   │   └── LGComponents/
│   └── Extensions/
├── Resources/
│   ├── WordPacks/                 # JSON word files by category
│   └── Localizable.xcstrings      # String catalog
└── Utilities/
    ├── HapticManager.swift
    └── AccessibilityIDs.swift
```

---

## Phase Roadmap

| Phase | Name | Description | Status |
|-------|------|-------------|--------|
| 0 | **Foundation** | Xcode project setup, Git, research iOS 26 APIs | 🔲 |
| 1 | **Domain Layer** | Models, Actions, GamePhase state machine, Reducer | 🔲 |
| 2 | **Design System** | Liquid Glass colors, typography, materials, components | 🔲 |
| 3 | **Core Flow** | HomeView, PlayerSetupView, navigation wiring | 🔲 |
| 4 | **Role Reveal** | Pass-and-play role reveal with privacy handling | 🔲 |
| 5 | **Gameplay** | ClueRound, Discussion, Voting, Reveal, Summary | 🔲 |
| 6 | **AI Integration** | ImagePlayground for custom word images | 🔲 |
| 7 | **Polish** | Persistence, Accessibility, Localization, Haptics | 🔲 |
| 8 | **Testing** | Unit tests, UI tests, performance profiling | 🔲 |
| 9 | **Release** | App Store assets, submission prep | 🔲 |

---

## Environment & Commands

```bash
# Build & Run
xcodebuild -scheme Imposter -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run Tests
xcodebuild test -scheme Imposter -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# SwiftUI Previews
# Use Xcode Canvas (⌥⌘P)

# Linting (if SwiftLint installed)
swiftlint
```

### Build Settings
- **Deployment Target**: iOS 26.0
- **Swift Language Version**: Swift 6
- **Strict Concurrency**: Complete
- **Bitcode**: Disabled

---

## Key Architecture Decisions

### 1. Unidirectional Data Flow
```
User Action → dispatch(action) → Reducer → New State → SwiftUI Updates
```

### 2. State Machine for Game Phases
```swift
enum GamePhase { 
    case setup, roleReveal, clueRound, discussion, voting, reveal, summary 
}
// Only valid transitions allowed via canTransition(to:)
```

### 3. @Observable for Fine-Grained Updates
- Use `@Observable` macro on `GameStore` and `GameState`
- Avoids `ObservableObject` boilerplate
- Better SwiftUI performance with granular tracking

### 4. MainActor Isolation
- `GameStore` is `@MainActor` for thread-safe UI updates
- Side effects (like AI image generation) run in detached Tasks

---

## Skills Directory

Load skills on-demand when working on specific domains:

| Skill | When to Load |
|-------|--------------|
| `.Codex/skills/liquid-glass/` | Implementing UI with .glassEffect, LGCard, LGButton |
| `.Codex/skills/swiftui-ios26/` | Using new iOS 26 SwiftUI APIs, Observation |
| `.Codex/skills/foundation-models/` | ImagePlayground, SystemLanguageModel integration |
| `.Codex/skills/game-logic/` | Reducer patterns, state machine, scoring |
| `.Codex/skills/accessibility/` | VoiceOver, Dynamic Type, localization |

---

## Ralph Loop (Iteration Cycle)

For each task, follow this cycle:

1. **Read** – Understand the requirement from TASKS.md
2. **Analyze** – Check existing code, identify dependencies
3. **Implement** – Write code following design system patterns
4. **Verify** – Build, run previews, check for errors
5. **Test** – Write/run unit tests if applicable
6. **Document** – Update TASKS.md status

---

## Always

- ✅ Use Swift 6 strict concurrency (mark types `Sendable` where needed)
- ✅ Follow Liquid Glass design tokens from `DesignSystem/`
- ✅ Keep Reducer pure – no side effects inside
- ✅ Use semantic colors (`.primary`, `.secondary`, system colors)
- ✅ Support Dynamic Type – use SwiftUI font styles
- ✅ Add `.accessibilityLabel` to interactive elements
- ✅ Test in both Light and Dark mode
- ✅ Check `canTransition(to:)` before phase changes
- ✅ Handle optionals safely – no force unwraps

## Never

- ❌ Hardcode colors – use `LGColors` tokens
- ❌ Skip accessibility modifiers on buttons/controls
- ❌ Mutate state outside the Reducer
- ❌ Use `ObservableObject` – prefer `@Observable`
- ❌ Block main thread with AI generation
- ❌ Commit secrets or API keys
- ❌ Delete tests without explicit direction

---

## Key Files Reference

| Purpose | File |
|---------|------|
| Full implementation spec | `Implementation Plan.md` |
| Task tracker | `TASKS.md` |
| This file | `AGENTS.md` |
| Phase prompts | `prompts/phase-*.md` |
| Domain skills | `.Codex/skills/*/` |

---

## Quick Links to Implementation Plan Sections

- **Section 1**: Technical Requirements (iOS 26, Swift 6, Frameworks)
- **Section 2**: Architecture & Module Structure
- **Section 3**: Data Models (Player, GameState, RoundState, GameSettings)
- **Section 4**: State Management (GameStore, Reducer)
- **Section 5**: Liquid Glass Design System
- **Section 6**: Feature Implementation (all screens)
- **Section 7**: Word Selection & AI Integration
- **Section 8**: Persistence
- **Section 9**: Accessibility & Localization
- **Section 10**: Testing Strategy
- **Section 11**: Performance
- **Section 12**: Build & Deployment
- **Section 13**: Implementation Timeline (6-week schedule)
- **Section 14**: Critical Research Checklist
- **Section 15**: Code Quality Standards
- **Section 16**: References & Documentation
- **Section 17**: Success Criteria
- **Appendix A**: Liquid Glass Research Notes
- **Appendix B**: Alternative Architecture Considered

---

## Success Criteria (Section 17)

### MVP Completion
- ✅ Support 3-10 players in local pass-and-play gameplay
- ✅ Full game loop: setup → roleReveal → clueRound → discussion → voting → reveal → summary
- ✅ UI fully adopts Liquid Glass design (feels native iOS 26)
- ✅ 3+ word categories with 100+ words each
- ✅ AI-generated image mode on A12+ devices
- ✅ Basic accessibility (VoiceOver navigable, Dynamic Type)
- ✅ No data sent off-device (fully offline)

### Performance Targets
- App launch: < 2 seconds
- Frame rate: Steady 60fps during gameplay
- Memory: < 100MB (excluding system AI model)
- Stability: No crashes/leaks in extended play (5+ rounds)

### Polish Goals
- Smooth spring animations
- Haptic feedback on key actions
- Full VoiceOver support
- Localization in 5 languages (EN, ES, FR, DE, JA)

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| ImagePlayground unavailable on older devices | Check capability, hide/disable AI feature gracefully |
| AI generation fails | Graceful fallback – game continues without image |
| Word pack JSON missing/corrupt | Hardcode backup word list, return "UNKNOWN" |
| Observation framework gotchas | Research iOS 26.2 improvements, test thoroughly |
| Glass effect invisible with Reduce Transparency | Verify solid fallback colors maintain readability |
| Long translations break layout | Test all languages, use `.minimumScaleFactor` |
| Secret word read aloud by VoiceOver | Mark word text to avoid automatic reading |

---

## 6-Week Timeline (Section 13)

| Week | Focus |
|------|-------|
| 1 | Project setup, research, data models, basic reducer |
| 2 | Liquid Glass design system, LGCard, LGButton |
| 3 | Core gameplay: Home, Setup, word selection, navigation |
| 4 | Gameplay phases: RoleReveal, Clue, Discussion, Voting, Reveal, Summary |
| 5 | Polish: Haptics, AI integration, accessibility, localization |
| 6 | Testing, performance tuning, App Store prep, submission |

---

## Code Quality (Section 15)

### Swift Style
- Follow Apple Swift API Design Guidelines
- camelCase for properties, UpperCamelCase for types
- Document complex logic with comments
- Use MARK comments to separate sections
- No magic numbers – use constants
- No force unwrapping – use guard/if let

### SwiftUI Best Practices
- Keep view bodies simple
- Use computed vars for complex calculations
- Minimal @State in views (prefer GameState)
- Use environment for global state injection
- Keep accessibility modifiers near views they describe

### Error Handling
```swift
enum ImposterError: LocalizedError {
    case invalidPlayerCount
    case wordPackLoadingFailed
    case invalidGameState
}
```
- Disable buttons for invalid states
- Log errors but never crash
