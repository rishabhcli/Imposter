# Phase 3: Core Flow – Agent Prompt

## Objective
Implement HomeView, PlayerSetupView, and navigation wiring to get players into a game.

## Context
- Read `CLAUDE.md` for architecture
- Load `.claude/skills/swiftui-ios26/` for navigation patterns
- Load `.claude/skills/liquid-glass/` for UI components
- Reference `Implementation Plan.md` Section 6.1-6.2

## Tasks

### 1. App Entry (`App/ImposterApp.swift`)

```swift
@main
struct ImposterApp: App {
    @State private var store = GameStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
```

### 2. Navigation Container

Either:
- Phase-based view switching in a container view, OR
- NavigationStack with programmatic navigation

Choose based on simplicity. Phase-based switching recommended:
```swift
struct ContentView: View {
    @Environment(GameStore.self) private var store
    
    var body: some View {
        switch store.state.currentPhase {
        case .setup: NavigationStack { PlayerSetupView() }
        // ... other phases
        }
    }
}
```

### 3. HomeView (`Features/Home/HomeView.swift`)

- Gradient background (blue → purple → pink)
- "Imposter" title with displayLarge typography
- "New Game" button → navigates to PlayerSetupView
- "How to Play" button → presents sheet
- "Settings" button → presents sheet
- Use LGButton for all buttons
- Add accessibility identifiers

### 4. HowToPlaySheet (`Features/Home/HowToPlaySheet.swift`)

- Brief game rules explanation
- Scrollable content
- Dismiss button

### 5. SettingsSheet (`Features/Home/SettingsSheet.swift`)

- Default game settings (timers, scoring, etc.)
- Save to UserDefaults (or just GameStore)
- presentationDetents for proper sheet sizing

### 6. PlayerSetupView (`Features/Setup/PlayerSetupView.swift`)

- ScrollView with player list
- Add player button (max 10)
- Remove player button (min 3)
- Validation warning if <3 players
- Word source picker (random vs custom)
- Category selection (if random)
- Difficulty picker (if random)
- Custom prompt TextField (if custom)
- "Start Game" button (disabled until valid)
- Wire up dispatch calls

### 7. PlayerRowView (`Features/Setup/PlayerRowView.swift`)

- Color circle (tappable to cycle)
- Name TextField
- Delete button (if >3 players)
- Glass background styling

### 8. CategorySelectionView (optional)

- Multi-select list of categories
- Or inline toggles in PlayerSetupView

## Acceptance Criteria
- [ ] Home screen displays with gradient background
- [ ] Can navigate to PlayerSetupView
- [ ] Can add/remove players (3-10 range)
- [ ] Can edit player names and colors
- [ ] Validation prevents starting with <3 players
- [ ] "Start Game" dispatches .startGame and transitions to roleReveal
- [ ] Accessibility identifiers present on key elements

## Testing Focus
- Test player count limits
- Test name editing
- Test settings persistence
- Verify dispatch calls update state

## Next Phase
After completion, proceed to **Phase 4: Role Reveal**.

---

## Ralph Loop Checklist
- [ ] Read skills: swiftui-ios26, liquid-glass
- [ ] Implement ImposterApp with environment
- [ ] Build HomeView
- [ ] Build PlayerSetupView
- [ ] Wire navigation/phase switching
- [ ] Test full setup flow
- [ ] Update `TASKS.md`
