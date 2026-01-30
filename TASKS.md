# Imposter – Task Tracker

> Phase-scoped task management. Update status as work progresses.

**Legend**: 🔲 Pending | 🔄 In Progress | ✅ Complete | ⏸️ Blocked

---

## Active Tasks

_Move tasks here when actively working on them._

| Task | Phase | Status | Notes |
|------|-------|--------|-------|
| | | | |

---

## Phase 0: Foundation

> Project setup, environment configuration, initial research.

### Project Setup (Section 1.3)
- [ ] Create Xcode project targeting iOS 26.0
- [ ] Initialize Git repository with `.gitignore`
- [ ] Configure build settings:
  - Swift 6 language version
  - Strict Concurrency Checking = Complete
  - Bitcode = Disabled
- [ ] Add ImagePlayground.framework to Frameworks & Libraries
- [ ] Set up folder structure per architecture diagram (Section 2.2)
- [ ] Configure Info.plist:
  - LSApplicationCategoryType = public.app-category.games
  - UIRequiredDeviceCapabilities (no restrictions)

### Research Topics (Section 1.2 & 14)
- [ ] Research Liquid Glass APIs:
  - `.glassEffect(.regular/.clear/.identity)`
  - `.glassEffect().tint()` and `.interactive()`
  - `GlassEffectContainer` for grouping
  - `.buttonStyle(.glass)` and `.glassProminent`
- [ ] Research Observation framework:
  - `@Observable` macro vs `ObservableObject`
  - `@IgnoreObservation` for non-UI properties
  - Fine-grained view updates
- [ ] Research ImagePlayground/FoundationModels:
  - `ImageCreator` class
  - Available styles (`.illustration`, `.sketch`, `.photo`)
  - `ImagePlaygroundConcept.text()`
  - Device requirements (A12 Bionic+)
- [ ] Research Swift 6 concurrency:
  - `Sendable` conformance requirements
  - `@MainActor` isolation
  - Detached Tasks for background work
- [ ] Research SwiftUI Navigation patterns for wizard flows
- [ ] Document findings in `.claude/skills/` files

**Acceptance Criteria**:
- Project builds successfully for iOS 26 simulator
- Folder structure matches `CLAUDE.md` specification
- Research notes documented in `.claude/skills/`

---

## Phase 1: Domain Layer

> Core models, actions, state machine, and reducer logic.

### Models
- [ ] Implement `Player` struct (id, name, color, score, isEliminated)
- [ ] Implement `PlayerColor` enum with 8 distinct colors
- [ ] Implement `GamePhase` enum with `canTransition(to:)` logic
- [ ] Implement `GameSettings` struct (wordSource, categories, timers, scoring)
- [ ] Implement `RoundState` struct (secretWord, imposterID, clues, votes)
- [ ] Implement `RoundState.Clue` nested struct
- [ ] Implement `GameState` @Observable class
- [ ] Implement `CompletedRound` struct for history
- [ ] Implement `VotingResult` helper struct

### Actions
- [ ] Define `GameAction` enum with all cases:
  - Setup: addPlayer, removePlayer, updatePlayer, updateSettings, startGame
  - RoleReveal: revealRoleToPlayer, completeRoleReveal
  - ClueRound: submitClue, advanceToNextClue, completeClueRounds
  - Voting: startDiscussion, endDiscussion, startVoting, castVote, completeVoting
  - Reveal: revealImposter, imposterGuessWord, completeRound
  - Summary: startNewRound, endGame, returnToHome

### Reducer & Store
- [ ] Implement `GameReducer.reduce(state:action:)` pure function
- [ ] Implement `createNewRound()` helper
- [ ] Implement `calculateVotingResult()` helper
- [ ] Implement `applyScoring()` helper
- [ ] Implement `GameStore` @Observable @MainActor class
- [ ] Add `dispatch(_:)` method with phase validation
- [ ] Add derived properties (currentPlayer, isImposter)

### Word Selection (Section 7.1-7.2)
- [ ] Create JSON structure for word packs with difficulty field
- [ ] Implement `WordPack` and `WordEntry` Codable structs
- [ ] Implement `WordSelector.selectWord(from:)` function
- [ ] Support category filtering (selectedCategories)
- [ ] Support difficulty filtering (easy/medium/hard/mixed)
- [ ] Create word pack files (5 categories, ~100+ words each):
  - `words_animals.json`
  - `words_technology.json`
  - `words_objects.json`
  - `words_people.json`
  - `words_movies.json`

**Acceptance Criteria**:
- All models compile with Sendable conformance
- GamePhase transitions validated correctly
- Reducer handles all actions without side effects
- Unit tests pass for reducer logic

---

## Phase 2: Design System

> Liquid Glass visual language implementation.

### Color System
- [ ] Implement `LGColors` enum with semantic tokens
- [ ] Add surface colors (primary, secondary, tertiary)
- [ ] Add text colors (primary, secondary, tertiary, inverse)
- [ ] Add accent colors (primary, secondary)
- [ ] Add status colors (success, warning, error)
- [ ] Add `playerColor(_:)` function for PlayerColor mapping

### Typography
- [ ] Implement `LGTypography` enum
- [ ] Define display styles (large, medium, small)
- [ ] Define headline styles (large, medium, small)
- [ ] Define body styles (large, medium, small)
- [ ] Define label styles (large, medium, small)

### Spacing & Materials
- [ ] Implement `LGSpacing` enum (small, medium, large, extraLarge)
- [ ] Implement `LGMaterials` enum
- [ ] Define elevation levels and shadow function
- [ ] Define corner radius constants

### Components
- [ ] Implement `LGCard` view with `.glassEffect`
- [ ] Implement `LGButton` view (primary, secondary, tertiary styles)
- [ ] Implement `LGBadge` view for winner indicator
- [ ] Test components in both Light and Dark mode
- [ ] Verify Reduce Transparency fallback behavior

**Acceptance Criteria**:
- Components render correctly with Liquid Glass effect
- Colors adapt properly to Light/Dark mode
- Typography scales with Dynamic Type
- Previews show all component variants

---

## Phase 3: Core Flow

> Home screen, player setup, and navigation wiring.

### Home Screen
- [ ] Implement `HomeView` with gradient background
- [ ] Add "Imposter" title with display typography
- [ ] Add "New Game" NavigationLink to PlayerSetup
- [ ] Add "How to Play" button with sheet presentation
- [ ] Add "Settings" button with sheet presentation
- [ ] Implement `HowToPlaySheet` with game rules
- [ ] Implement `SettingsSheet` for default game settings

### Player Setup
- [ ] Implement `PlayerSetupView` with ScrollView layout
- [ ] Implement `PlayerRowView` with name field and color picker
- [ ] Add "Add Player" button (max 10 players)
- [ ] Add player removal functionality (min 3 players)
- [ ] Add validation text for insufficient players
- [ ] Implement word source picker (random vs custom prompt)
- [ ] Implement category selection (NavigationLink to multi-select)
- [ ] Implement difficulty picker
- [ ] Implement custom prompt TextField (when AI mode selected)
- [ ] Add "Start Game" button with validation
- [ ] Wire up dispatch calls for player/settings actions

### Navigation
- [ ] Set up `NavigationStack` in `ImposterApp`
- [ ] Inject `GameStore` into environment
- [ ] Implement phase-based view switching OR navigation path

**Acceptance Criteria**:
- Can add 3-10 players with names and colors
- Settings persist via dispatch to GameStore
- Start Game transitions to roleReveal phase
- Navigation flows correctly between screens

---

## Phase 4: Role Reveal

> Pass-and-play secret role distribution.

- [ ] Implement `RoleRevealView` with player index tracking
- [ ] Show "Pass device to [PlayerName]" prompt
- [ ] Add "Reveal Role" button
- [ ] Implement `RoleCardView` with two variants:
  - Informed: Shows secret word (and optional AI image)
  - Imposter: Shows "You are the Imposter!" message
- [ ] Style RoleCardView with LGCard
- [ ] Add privacy overlay/blur between reveals
- [ ] Add "Tap to continue" instruction
- [ ] Track reveal progress and advance to next player
- [ ] Dispatch `.completeRoleReveal` when all players done
- [ ] Add accessibility labels for VoiceOver

**Acceptance Criteria**:
- Each player sees their role privately
- Imposter sees different content than informed players
- Transitions smoothly to ClueRound phase
- Works correctly with 3-10 players

---

## Phase 5: Gameplay Phases

> Clue giving, discussion, voting, and reveal.

### Clue Round
- [ ] Implement `ClueRoundView` with round/player tracking
- [ ] Show current player prompt
- [ ] Implement `ClueInputView` with TextField
- [ ] Add 30-character limit with counter
- [ ] Add Submit button with validation
- [ ] Implement `ClueHistoryList` showing all clues
- [ ] Auto-focus TextField on player turn
- [ ] Handle multiple clue rounds (numberOfClueRounds setting)
- [ ] Add "Proceed" button after all clues given

### Discussion (Optional) (Section 6.5)
- [ ] Implement `DiscussionView` with timer
- [ ] Use `Timer.publish` or async timer for countdown
- [ ] Show countdown circle animation if discussionTimerEnabled
- [ ] Announce timer via VoiceOver if needed
- [ ] Add "Start Voting" button to skip/end early
- [ ] Auto-transition when timer reaches 0

### Voting
- [ ] Implement `VotingView` with voter index tracking
- [ ] Show voter prompt
- [ ] Implement `PlayerSelectionGrid` with adaptive layout
- [ ] Implement `PlayerVoteCard` (LGCard with name/color)
- [ ] Filter out self from vote options
- [ ] Add haptic feedback on selection
- [ ] Show "Vote recorded" confirmation
- [ ] Add "Pass device" instruction
- [ ] Dispatch `.castVote` and track completion
- [ ] Auto-advance to reveal when all votes cast

### Reveal
- [ ] Implement `RevealView` showing voting results
- [ ] Show who received most votes
- [ ] Implement `RevealAnimationView` with spring animation
- [ ] Show imposter identity with dramatic reveal
- [ ] Display outcome (correct/wrong guess)
- [ ] Add imposter word guess option if enabled
- [ ] Add "Continue" button to proceed to summary
- [ ] Dispatch scoring via `.completeRound`

### Summary
- [ ] Implement `SummaryView` with sorted scoreboard
- [ ] Implement `ScoreboardRow` with rank, color, name, score
- [ ] Highlight winner(s) with crown icon
- [ ] Add "Play Again" button (same players, new round)
- [ ] Add "Main Menu" button (return to home)
- [ ] Show round history (expandable, optional)

**Acceptance Criteria**:
- Full game flow works end-to-end
- Scoring calculated correctly
- Multiple rounds accumulate scores
- All transitions respect GamePhase state machine

---

## Phase 6: AI Integration ✅

> On-device image generation for custom words.

- [x] Import ImagePlayground framework
- [x] Implement async image generation in `GameStore`
- [x] Use `ImageCreator` with `.text()` concept
- [x] Choose appropriate style (.illustration or .sketch)
- [x] Store generated `UIImage` in `RoundState.generatedImage`
- [x] Handle generation errors gracefully
- [x] Display image in `RoleCardView` for informed players
- [x] Add loading indicator if image not ready
- [ ] Test on physical device (simulator may not support)
- [x] Verify memory management (image cleanup after round)

**Acceptance Criteria**:
- ✅ Custom prompt generates relevant image
- ✅ Image displays correctly in role reveal
- ✅ No crashes if generation fails
- ✅ Memory freed after round ends

---

## Phase 7: Polish ✅

> Persistence, accessibility, localization, haptics.

### Persistence (Section 8.1-8.2)
- [x] Implement `StorageKeys` enum:
  - `imposter.gameSettings`
  - `imposter.lastPlayers`
  - `imposter.gamesPlayed`
  - `imposter.highScore`
- [x] Save/load `GameSettings` to UserDefaults (JSON encoded)
- [x] Save last players (names/colors) for quick rematch
- [x] Implement `SettingsStore` @Observable class:
  - Auto-save on `didSet`
  - Load from UserDefaults on init
- [x] Track statistics (games played, high score)
- [ ] Show high score on summary if beaten

### Accessibility (Section 9.1)
- [x] Add `.accessibilityLabel` to all buttons
- [x] Add `.accessibilityHint` for vote cards
- [x] Add `.accessibilityElement(children: .combine)` for grouped elements
- [x] Implement `announcePhaseChange()` for VoiceOver
- [x] Ensure secret word NOT read aloud (to avoid spoiling)
- [ ] Use `.accessibilityFocused` for focus transitions
- [ ] Create `accessibilityPlayerBadge()` extension
- [x] Ensure 44x44pt minimum touch targets (color picker!)
- [ ] Test with VoiceOver enabled
- [ ] Test with Dynamic Type (AX sizes up to xxxLarge)
- [x] Use `.minimumScaleFactor` on large titles if needed
- [x] Verify color contrast on glass backgrounds
- [x] Handle Reduce Motion preference:
  - Check `UIAccessibility.isReduceMotionEnabled`
  - Simplify/shorten animations when true
- [x] Handle Reduce Transparency fallback:
  - Verify text readable on solid backgrounds

### Localization
- [x] Create `Localizable.xcstrings` string catalog
- [x] Extract all user-facing strings with keys
- [x] Provide English translations (base)
- [x] Add Spanish translations
- [x] Add French translations
- [x] Add German translations
- [x] Add Japanese translations
- [ ] Test layout with longer translations

### Haptics
- [x] Implement `HapticManager` wrapper
- [x] Add light haptic on clue submit
- [x] Add medium haptic on vote selection
- [x] Add success/failure haptic on reveal

**Acceptance Criteria**:
- ✅ Settings persist across app launches
- ✅ VoiceOver navigates all screens correctly
- ✅ App works in all 5 languages
- ✅ Haptics provide tactile feedback

---

## Phase 8: Testing ✅

> Unit tests, UI tests, performance verification.

### Unit Tests
- [x] `GameReducerTests`: addPlayer, removePlayer, updatePlayer
- [x] `GameReducerTests`: startGame initializes round
- [x] `GameReducerTests`: submitClue advances index
- [x] `GameReducerTests`: castVote records correctly
- [x] `GameReducerTests`: voting outcome scoring (correct/incorrect)
- [x] `GamePhaseTests`: valid transitions allowed
- [x] `GamePhaseTests`: invalid transitions blocked
- [x] `WordSelectorTests`: category filtering
- [x] `WordSelectorTests`: difficulty filtering
- [ ] Achieve 80%+ coverage on Domain layer

### UI Tests
- [x] `ImposterUITests`: launch and see home screen
- [x] `ImposterUITests`: add players flow
- [x] `ImposterUITests`: complete game flow (simplified)
- [ ] Test localization switching
- [ ] Test accessibility identifiers

### Performance (Section 11.1-11.3)
- [ ] Profile with Time Profiler during gameplay
- [ ] Profile memory during AI generation
- [x] Verify no main thread blocking
- [x] Check for retain cycles in Tasks
- [ ] Add `@IgnoreObservation` to `gameHistory` if not needed for UI
- [x] Pre-compute vote tallies in reducer (not view body)
- [ ] Consider `.equatable()` on frequently re-rendered views
- [x] Ensure image generation uses local scope (no retained ImageCreator)
- [x] Clear `generatedImage` after round to free memory
- [ ] Target: <2s launch, steady 60fps, <100MB memory

**Acceptance Criteria**:
- ✅ All unit tests pass (50+ tests)
- ✅ UI tests created
- ✅ No memory leaks detected
- ✅ Consistent 60fps during gameplay

---

## Phase 9: Release

> App Store preparation and submission.

### Build Configuration (Section 12.1)
- [ ] Configure Debug build:
  - Enable all compiler warnings (-Wall)
  - Keep strict concurrency in debug
  - Add #if DEBUG for preview data
- [ ] Configure Release build:
  - Optimization: -Osize or -O
  - Symbol stripping enabled
  - Remove debug logging
  - Remove placeholder text

### App Store Assets (Section 12.2)
- [ ] Design app icon 1024x1024 (glassy question mark theme)
- [ ] Create launch screen (simple title, gradient background)
- [ ] Take screenshots for all device sizes:
  - iPhone 16 Pro Max (6.9")
  - iPhone 16 Pro (6.3")
  - iPad Pro 13" (if supporting)
- [ ] Screenshot ideas: Home, Setup, Role Reveal (with AI image), Clue, Vote, Summary

### App Store Metadata
- [ ] App Name: Imposter
- [ ] Subtitle: Party Game for Friends
- [ ] Write App Store description (highlight Liquid Glass, AI, offline)
- [ ] Keywords: party game, social deduction, multiplayer, imposter, word game
- [ ] Set category: Games > Party
- [ ] Set age rating: 4+
- [ ] Complete App Privacy: No data collected

### Submission
- [ ] Archive Release build
- [ ] Test on multiple physical devices (older A12+ and newer)
- [ ] Verify AI feature disabled gracefully on unsupported devices
- [ ] Upload to TestFlight
- [ ] Internal testing
- [ ] Submit to App Store Connect
- [ ] Monitor review status
- [ ] Respond to any issues

**Acceptance Criteria**:
- App approved and live on App Store

---

## Completed Tasks

_Move tasks here when done._

| Task | Phase | Completed Date |
|------|-------|----------------|
| Scary bloody red "IMPOSTER" title font | UI Overhaul | Jan 2026 |
| Dark backgrounds (removed purple gradients) | UI Overhaul | Jan 2026 |
| Liquid Glass buttons throughout app | UI Overhaul | Jan 2026 |
| Player emoji system (96+ face emojis) | UI Overhaul | Jan 2026 |
| Auto-focus text field when adding player | UI Overhaul | Jan 2026 |
| Timer option (0-5 minutes) in settings | UI Overhaul | Jan 2026 |
| Categories-first game flow | UI Overhaul | Jan 2026 |
| CategorySelectionView implementation | UI Overhaul | Jan 2026 |
| Foundation Models word generation | AI Integration | Jan 2026 |
| WordGenerator.swift implementation | AI Integration | Jan 2026 |
| ImagePlayground image generation | AI Integration | Jan 2026 |
| Word + Image chained generation flow | AI Integration | Jan 2026 |
| setGeneratedWord action implementation | AI Integration | Jan 2026 |
| Emoji display in RoleRevealView | UI Overhaul | Jan 2026 |

---

## Backlog / Future Enhancements

- [ ] Sound effects (drum roll on reveal, etc.) using AVFoundation
- [ ] Localized word packs per language (Spanish, French, etc.)
- [ ] Game Center leaderboards (would require networking)
- [ ] Custom themes beyond Liquid Glass
- [ ] iPad split-view optimization
- [ ] watchOS companion for secret reveal
- [ ] Siri Shortcuts integration
- [ ] Confetti animation for winner
- [ ] Points breakdown display after each round
- [ ] Round history detail view (expandable CompletedRound list)
- [ ] CI/CD pipeline setup
- [ ] SwiftLint integration

---

## Success Criteria (Section 17)

### MVP Completion
- [ ] Support 3-10 players local gameplay
- [ ] Full game loop works without crashes:
  - setup → roleReveal → clueRound → discussion → voting → reveal → summary
- [ ] UI adopts Liquid Glass design (feels native iOS 26)
- [ ] 3+ categories with 100+ words each
- [ ] AI-generated image mode works on A12+ devices
- [ ] Basic accessibility: VoiceOver navigable, Dynamic Type supported
- [ ] No data sent off-device

### Performance Targets
- [ ] App launch < 2s
- [ ] Steady 60fps during interactions
- [ ] Memory usage < 100MB (excluding system AI model)
- [ ] No crashes or leaks in 5+ round sessions

### Polish Goals
- [ ] Smooth animations with spring physics
- [ ] Haptic feedback on key actions
- [ ] Full VoiceOver support
- [ ] Localization in 5 languages

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| ImagePlayground unavailable on older devices | Check device capability, hide feature if unsupported |
| AI generation fails | Graceful fallback - game continues without image |
| Word pack JSON missing/corrupt | Hardcode backup word list, return "UNKNOWN" |
| Observation framework gotchas | Research iOS 26.2 improvements, test thoroughly |
| Glass effect invisible in Reduce Transparency | Verify solid fallback colors maintain readability |
| Long German translations break layout | Test all languages, use `.minimumScaleFactor` or multiline |

---

## Code Quality Standards (Section 15)

### Swift Style
- [ ] Follow Apple Swift API Design Guidelines
- [ ] Use camelCase for properties, UpperCamelCase for types
- [ ] Document complex logic with comments
- [ ] Use MARK comments to separate sections
- [ ] No magic numbers - use constants
- [ ] No force unwrapping - use guard/if let

### SwiftUI Best Practices
- [ ] Keep view bodies simple
- [ ] Use computed vars for complex calculations
- [ ] Minimal @State in views (prefer GameState)
- [ ] Use environment for global state
- [ ] Keep accessibility modifiers near views

### Error Handling
- [ ] Implement `ImposterError` enum:
  - `.invalidPlayerCount`
  - `.wordPackLoadingFailed`
  - `.invalidGameState`
- [ ] Disable buttons for invalid states (don't rely on reducer guards)
- [ ] Log errors but never crash
