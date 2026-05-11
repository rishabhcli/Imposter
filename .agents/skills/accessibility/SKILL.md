# Accessibility Skill

## When to Load
Load this skill when:
- Adding VoiceOver labels and hints
- Implementing Dynamic Type support
- Handling Reduce Motion / Reduce Transparency
- Adding localization strings
- Testing accessibility compliance

## VoiceOver Best Practices

### Labels
Every interactive element needs a clear label:
```swift
Button("Vote") { }
    .accessibilityLabel("Vote for \(player.name)")
    .accessibilityHint("Double tap to cast your vote for this player")
```

### Grouping
Combine related elements:
```swift
HStack {
    Circle().fill(color)
    Text(name)
    Text("\(score)")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(name), \(score) points")
```

### Announcements
Announce phase changes:
```swift
UIAccessibility.post(notification: .announcement, argument: "Voting phase started")
```

## Dynamic Type

### Use SwiftUI Font Styles
```swift
.font(.body)           // Scales automatically
.font(.headline)       // Scales automatically
.font(LGTypography.bodyLarge)  // If using system fonts, scales
```

### Test Large Sizes
- Run app with Accessibility Inspector
- Test `.accessibility1` through `.accessibilityExtraExtraExtraLarge`
- Ensure text doesn't clip

## Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? .none : .spring(), value: isRevealed)
```

## Reduce Transparency

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

// .glassEffect automatically falls back, but verify:
.background(reduceTransparency ? Color.systemBackground : .clear)
```

## Localization

### String Catalog Keys
```swift
Text("new_game_button")  // Key in Localizable.xcstrings
```

### Interpolation
```swift
Text("pass_device_to \(playerName)")
// In catalog: "pass_device_to %@" = "Pass device to %@"
```

## Critical Research Notes (Section 9 & 14)

### Secret Word Protection
**CRITICAL**: Ensure VoiceOver does NOT read secret word aloud to avoid spoiling!
- Use `.accessibilityHidden(true)` on secret word text OR
- Use `.accessibilityLabel("Secret word, \(word.count) letters")` instead of actual word

### Color Blindness Considerations
- Don't rely solely on color to identify players
- Always show player names alongside color indicators
- Consider adding patterns/shapes for additional differentiation

### Focus Management
```swift
@AccessibilityFocusState private var isFocused: Bool

// After phase change, move focus:
.accessibilityFocused($isFocused)
.onAppear { isFocused = true }
```

### Reduce Motion Check
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Or imperatively:
UIAccessibility.isReduceMotionEnabled
```

### Right-to-Left Layout
- SwiftUI auto-flips for RTL locales (Arabic, Hebrew)
- Our vertical/center layouts should work fine
- Test with at least one RTL locale if supporting

### Localized Word Packs
- Ideally provide word packs per language for fair play
- MVP: English words only, note as future enhancement

## Reference

See `reference.md` for code patterns.
