# Imposter – UI Overhaul Implementation Summary

> **Completed Changes** – All UI/UX updates implemented in this session.

---

## Overview

This document outlines all the UI/UX changes implemented to transform the Imposter app into a polished, immersive party game experience using iOS 26's Liquid Glass design system with a dark, spooky theme.

---

## 1. Visual Theme Changes

### 1.1 Scary "IMPOSTER" Title
**Files Modified:** `LGTypography.swift`, `LGColors.swift`, `HomeView.swift`

```swift
// LGTypography.swift - New scary fonts
static let scaryTitle = Font.system(size: 56, weight: .black, design: .serif)
static let scaryTitleSmall = Font.system(size: 42, weight: .black, design: .serif)

// LGColors.swift - Bloody red colors
static let bloodyRed = Color(red: 0.7, green: 0.05, blue: 0.05)
static let bloodyRedDark = Color(red: 0.5, green: 0.0, blue: 0.0)
```

The title "IMPOSTER" now displays with:
- Large, bold serif font for a dramatic, scary appearance
- Bloody red color gradient
- Shadow effects for depth

### 1.2 Dark Backgrounds (Removed Purple)
**Files Modified:** All view files, `LGColors.swift`

```swift
// LGColors.swift - Dark background tokens
static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.08)
static let darkBackgroundSecondary = Color(red: 0.08, green: 0.08, blue: 0.12)
```

**Before:** Purple gradient backgrounds throughout the app
**After:** Dark, near-black backgrounds optimized for Liquid Glass effects

All views now use `LGColors.darkBackground` as the base, creating better contrast for the glass materials.

### 1.3 Liquid Glass UI for All Buttons
**Files Modified:** All view files with buttons

All buttons throughout the app now use Liquid Glass styling:
```swift
.buttonStyle(.glass)
// or custom LGButton component with glassEffect
```

This applies to:
- Home screen buttons (Start Game, How to Play, Settings)
- Player setup actions (Add Player, Remove, Edit)
- Game flow buttons (Continue, Submit Clue, Vote, etc.)
- Navigation buttons

---

## 2. Player System Enhancements

### 2.1 Random Face Emoji for Each Player
**Files Modified:** `Player.swift`

```swift
struct Player: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var color: PlayerColor
    var emoji: String  // NEW: Random face emoji
    var score: Int
    var isEliminated: Bool

    init(id: UUID = UUID(), name: String, color: PlayerColor, emoji: String? = nil, ...) {
        self.emoji = emoji ?? Player.randomFaceEmoji()
        // ...
    }

    static let faceEmojis = [
        "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂",
        "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩",
        "😘", "😗", "😚", "😙", "🥲", "😋", "😛", "😜",
        "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐",
        "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬",
        "😮‍💨", "🤥", "😌", "😔", "😪", "🤤", "😴", "😷",
        "🤒", "🤕", "🤢", "🤮", "🤧", "🥵", "🥶", "🥴",
        "😵", "🤯", "🤠", "🥳", "🥸", "😎", "🤓", "🧐",
        "😕", "😟", "🙁", "😮", "😯", "😲", "😳", "🥺",
        "😦", "😧", "😨", "😰", "😥", "😢", "😭", "😱",
        "😖", "😣", "😞", "😓", "😩", "😫", "🥱", "😤",
        "👻", "💀", "☠️", "👽", "🤖", "🎃", "😈", "👿"
    ]

    static func randomFaceEmoji() -> String {
        faceEmojis.randomElement() ?? "😀"
    }
}
```

**Features:**
- 96+ face emojis to choose from
- Includes spooky emojis (ghost, skull, alien, devil) for theme
- Auto-assigned on player creation
- Displayed as player avatar throughout the game

### 2.2 Emoji Display in Role Reveal
**Files Modified:** `RoleRevealView.swift`

The "Pass device to Player X" screen now prominently displays the player's emoji:

```swift
private var passDevicePrompt: some View {
    VStack(spacing: LGSpacing.extraLarge) {
        // Player emoji avatar - large display
        ZStack {
            Circle()
                .fill(playerColor)
                .frame(width: 120, height: 120)

            Text(currentPlayer.emoji)
                .font(.system(size: 70))
        }
        .overlay {
            Circle()
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 3)
        }
        // ...
    }
}
```

### 2.3 Auto-Focus Text Field When Adding Player
**Files Modified:** `PlayerSetupView.swift`

```swift
@FocusState private var focusedField: UUID?

// When adding new player, auto-focus the text field
private func addPlayer() {
    let usedColors = store.players.map { $0.color }
    let color = PlayerColor.nextAvailable(excluding: usedColors)
    store.dispatch(.addPlayer(name: "", color: color))

    // Focus the new player's text field
    if let newPlayer = store.players.last {
        focusedField = newPlayer.id
    }
}
```

---

## 3. Game Settings Enhancements

### 3.1 Timer Option (1-5 Minutes or No Timer)
**Files Modified:** `GameSettings.swift`, Settings UI

```swift
struct GameSettings: Codable, Sendable, Equatable {
    // Timer settings
    var clueTimerEnabled: Bool = false
    var clueTimerMinutes: Int = 2  // Default 2 minutes

    // Available timer options
    static let timerOptions = [0, 1, 2, 3, 4, 5]

    static func timerDisplayText(minutes: Int) -> String {
        if minutes == 0 {
            return "No Timer"
        }
        return "\(minutes) min"
    }
}
```

**Timer Options:**
- No Timer (default)
- 1 minute
- 2 minutes
- 3 minutes
- 4 minutes
- 5 minutes

---

## 4. Game Flow Restructure

### 4.1 Categories-First Flow
**Files Modified:** `CategorySelectionView.swift` (NEW), Navigation

**New Flow:**
```
Home → Category Selection → Player Setup → Game
```

**Old Flow:**
```
Home → Player Setup (with categories) → Game
```

### 4.2 CategorySelectionView Implementation
**New File:** `CategorySelectionView.swift`

Features:
- Word source toggle (Random Word vs Custom AI Word)
- Category grid with FlowLayout
- Apple Intelligence section for custom AI prompts
- Clear visual hierarchy

```swift
struct CategorySelectionView: View {
    @Environment(GameStore.self) private var store
    @State private var navigateToPlayerSetup = false

    var body: some View {
        // Word Source Toggle
        // Category Selection (if Random Word)
        // AI Prompt Section (if Custom AI Word)
        // Continue Button → PlayerSetupView
    }
}
```

---

## 5. On-Device AI Integration

### 5.1 Foundation Models for Word Generation (Independent Feature)
**New File:** `WordGenerator.swift`

Uses Apple's on-device Foundation Models to generate **related** words from user prompts (NOT echo the exact input):

```swift
import Foundation
import FoundationModels

@MainActor
enum WordGenerator {
    static func generateWord(from prompt: String) async throws -> String {
        let session = LanguageModelSession()

        let fullPrompt = """
        You are a word generator for a party guessing game called Imposter.
        Given a theme or topic, respond with ONLY a single word or very short phrase (2-3 words max) that is RELATED to the theme.

        IMPORTANT RULES:
        - Respond with ONLY the word, nothing else
        - Do NOT use the exact word(s) from the input
        - Choose something fun, specific, and guessable
        - Keep it appropriate for all ages
        - The word should be a concrete noun or simple concept
        - No explanations, just the word

        Theme: \(prompt)

        Related word:
        """

        let response = try await session.respond(to: fullPrompt)
        let responseText = response.content

        // Clean and validate response
        var cleanedWord = responseText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            // ... more cleaning

        return cleanedWord.capitalized
    }

    static var isAvailable: Bool {
        if #available(iOS 26, *) {
            return true
        }
        return false
    }

    enum WordGeneratorError: LocalizedError {
        case notAvailable
        case invalidResponse
        case sameAsPrompt
    }
}
```

**Key Behavior:**
- Takes user prompt (e.g., "Ocean")
- Generates RELATED word (e.g., "Dolphin", "Coral", "Whale")
- Does NOT return the exact input word
- Falls back to prompt if generation fails

### 5.2 ImagePlayground for AI Images
**Files Modified:** `GameStore.swift`

Uses Apple's ImagePlayground framework to generate illustrations for secret words:

```swift
import ImagePlayground

private nonisolated func performImageGeneration(for word: String) async {
    do {
        let creator = try await ImageCreator()

        let imagePrompt = "A colorful, fun illustration of: \(word)"
        let concepts: [ImagePlaygroundConcept] = [.text(imagePrompt)]

        let imageSequence = creator.images(
            for: concepts,
            style: .illustration,  // Friendly style for party game
            limit: 1
        )

        for try await generatedImage in imageSequence {
            let uiImage = UIImage(cgImage: generatedImage.cgImage)

            await MainActor.run {
                if var roundState = self.state.roundState {
                    roundState.generatedImage = uiImage
                    self.state.roundState = roundState
                }
                self.isGeneratingImage = false
            }
            return
        }
    } catch {
        // Graceful fallback - game continues without image
    }
}
```

### 5.3 Word + Image Generation Flow
**Files Modified:** `GameStore.swift`, `GameReducer.swift`, `GameAction.swift`

**New Action:**
```swift
case setGeneratedWord(word: String)
```

**Flow:**
1. User enters custom prompt (e.g., "Space")
2. Game starts → Word placeholder "GENERATING..." shown
3. Foundation Models generates related word (e.g., "Astronaut")
4. Word updates via `.setGeneratedWord` action
5. ImagePlayground generates illustration for "Astronaut"
6. Image displayed under secret word

```swift
// GameStore.swift
private func generateWordAndImage(from prompt: String) {
    guard !isGeneratingWord else { return }
    isGeneratingWord = true

    Task {
        await performWordGeneration(from: prompt)
    }
}

private func performWordGeneration(from prompt: String) async {
    do {
        let generatedWord = try await WordGenerator.generateWord(from: prompt)
        dispatch(.setGeneratedWord(word: generatedWord))
        isGeneratingWord = false
        generateSecretImage(for: generatedWord)  // Chain to image generation
    } catch {
        // Fallback to using prompt itself
        dispatch(.setGeneratedWord(word: prompt.capitalized))
        isGeneratingWord = false
        generateSecretImage(for: prompt)
    }
}
```

---

## 6. State Management Updates

### 6.1 RoundState Updates
**Files Modified:** `RoundState.swift`

```swift
struct RoundState: Codable, Sendable {
    var secretWord: String
    let imposterID: UUID
    var clues: [Clue]
    var votes: [UUID: UUID]
    var currentClueIndex: Int
    var revealIndex: Int
    var generatedImage: UIImage?  // For AI-generated image
}
```

### 6.2 GameReducer Updates
**Files Modified:** `GameReducer.swift`

```swift
case .setGeneratedWord(let word):
    guard var round = newState.roundState else { return state }
    newState.roundState = RoundState(
        secretWord: word,
        imposterID: round.imposterID,
        clues: round.clues,
        votes: round.votes,
        currentClueIndex: round.currentClueIndex,
        revealIndex: round.revealIndex
    )

static func createNewRound(players: [Player], settings: GameSettings) -> RoundState {
    let word: String
    if settings.wordSource == .customPrompt {
        word = "GENERATING..."  // Placeholder - GameStore will generate
    } else {
        word = WordSelector.selectWord(from: settings)
    }
    // ...
}
```

---

## 7. Files Changed Summary

| Category | File | Changes |
|----------|------|---------|
| **Design System** | `LGColors.swift` | Added `bloodyRed`, `darkBackground` colors |
| **Design System** | `LGTypography.swift` | Added `scaryTitle`, `scaryTitleSmall` fonts |
| **Models** | `Player.swift` | Added `emoji` property, `faceEmojis` array, `randomFaceEmoji()` |
| **Models** | `GameSettings.swift` | Added `clueTimerEnabled`, `clueTimerMinutes`, timer options |
| **Actions** | `GameAction.swift` | Added `setGeneratedWord(word:)` action |
| **Logic** | `GameReducer.swift` | Added handler for `setGeneratedWord`, updated `createNewRound` |
| **Logic** | `WordGenerator.swift` | **NEW** - Foundation Models word generation |
| **Store** | `GameStore.swift` | Added word generation, image generation, chained flow |
| **Views** | `HomeView.swift` | Scary title, dark background, glass buttons |
| **Views** | `CategorySelectionView.swift` | **NEW** - Category-first selection flow |
| **Views** | `PlayerSetupView.swift` | Auto-focus text field, emoji display |
| **Views** | `RoleRevealView.swift` | Fixed emoji display in pass device prompt |
| **Views** | All Views | Dark backgrounds, glass buttons |

---

## 8. Testing Checklist

- [x] Build succeeds with no errors
- [ ] Scary title displays correctly in HomeView
- [ ] Dark backgrounds throughout app
- [ ] Glass buttons on all interactive elements
- [ ] Player emoji assigned on creation
- [ ] Emoji visible in role reveal pass-device screen
- [ ] Timer settings work (0-5 minutes)
- [ ] Category selection navigates to player setup
- [ ] AI word generation produces related (not exact) words
- [ ] AI image generation displays under secret word
- [ ] Fallback works when AI generation fails

---

## 9. Known Limitations

1. **Foundation Models Availability**: Only available on iOS 26+ devices with A12+ chip
2. **ImagePlayground Availability**: Requires compatible device hardware
3. **Generation Time**: AI generation may take 2-5 seconds; loading indicators shown
4. **Offline Requirement**: All AI features run on-device (no internet needed)

---

## 10. Build Status

```
** BUILD SUCCEEDED **
```

All changes compile and build successfully for iOS 26 target.

---

*Document Generated: January 2026*
*iOS Target: 26.0+*
*Swift Version: 6*
