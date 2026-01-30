# Phase 7: Polish – Agent Prompt

## Objective
Add persistence, accessibility, localization, and haptic feedback for production quality.

## Context
- Read `CLAUDE.md` for requirements
- Load `.claude/skills/accessibility/` for a11y patterns
- Reference `Implementation Plan.md` Sections 8-9

## Tasks

### 1. Persistence (`Utilities/`)

#### StorageKeys.swift
```swift
enum StorageKeys {
    static let gameSettings = "imposter.gameSettings"
    static let lastPlayers  = "imposter.lastPlayers"
    static let gamesPlayed  = "imposter.gamesPlayed"
}
```

#### SettingsStore.swift (optional)
- Load/save GameSettings to UserDefaults
- Auto-save on change

Or integrate directly into GameStore/App.

### 2. Accessibility

#### VoiceOver Labels
Add to all interactive elements:
- Buttons: `.accessibilityLabel("button name")`
- Vote cards: `.accessibilityLabel` + `.accessibilityHint`
- Scoreboard rows: combine children

#### Phase Announcements
```swift
func announcePhaseChange(_ phase: GamePhase) {
    // Post UIAccessibility announcement
}
```

Call in GameStore after phase transitions.

#### Dynamic Type
- Verify all text uses scalable fonts
- Test at `.accessibilityExtraExtraExtraLarge`
- Adjust layouts if clipping

#### Reduce Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion
// Use simpler animations when true
```

#### Reduce Transparency
- `.glassEffect` handles automatically
- Verify text remains readable

### 3. Localization

#### Create String Catalog
`Resources/Localizable.xcstrings`

Extract all user-facing strings:
- Button titles
- Labels and prompts
- Error messages
- Phase announcements

#### Provide Translations
- English (base)
- Spanish
- French
- German
- Japanese

#### Test Layouts
- Run app in each language
- Verify no truncation
- Check RTL layout (if supporting Arabic)

### 4. Haptics (`Utilities/HapticManager.swift`)

```swift
enum HapticManager {
    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
    static func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType)
    static func playSelection()
}
```

Add haptics:
- Light impact: clue submission
- Medium impact: vote selection
- Success notification: correct vote reveal
- Error notification: wrong vote reveal

### 5. Accessibility Identifiers (`Utilities/AccessibilityIDs.swift`)

Define constants for UI testing:
```swift
enum AccessibilityIDs {
    static let newGameButton = "NewGameButton"
    static let startGameButton = "StartGameButton"
    // ... etc
}
```

Apply to all key elements.

## Acceptance Criteria
- [ ] Settings persist across app launches
- [ ] VoiceOver navigates all screens correctly
- [ ] App works in all 5 languages
- [ ] Text scales with Dynamic Type
- [ ] Animations respect Reduce Motion
- [ ] Haptics provide feedback at key moments
- [ ] All key elements have accessibility identifiers

## Testing Focus
- Test full game with VoiceOver
- Test at largest Dynamic Type size
- Test each language
- Verify haptics on device

## Next Phase
After completion, proceed to **Phase 8: Testing**.

---

## Ralph Loop Checklist
- [ ] Read skill: accessibility
- [ ] Implement persistence
- [ ] Add VoiceOver labels
- [ ] Add phase announcements
- [ ] Create string catalog
- [ ] Add translations
- [ ] Implement HapticManager
- [ ] Test accessibility features
- [ ] Update `TASKS.md`
