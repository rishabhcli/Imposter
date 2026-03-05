# Imposter App - Improvement Plan

> 13 actionable improvements ranked by impact. Each includes the problem, solution, affected files, and effort estimate.

---

## 1. Implement Scoring Engine (Missing Core Feature)

**Problem:** The spec defines a full scoring system (`pointsForCorrectVote`, `pointsForImposterSurvival`, `pointsForImposterGuess`) but no `ScoringEngine` exists. Player scores are never updated. The `completeRound` action resets to `.setup` without recording results or awarding points.

**Solution:**
- Create `Imposter/Domain/Logic/ScoringEngine.swift` with a pure `static func calculate(roundState:players:settings:votingResult:) -> [UUID: Int]` method
- Update `GameReducer.reduce` for `.completeRound` to:
  1. Call `calculateVotingResult()`
  2. Call `ScoringEngine.calculate()` to get score deltas
  3. Update each player's `score` property
  4. Archive to `gameHistory` as a `CompletedRound`
- Add score display to RevealView after the imposter guess

**Files:** New `ScoringEngine.swift`, modify `GameReducer.swift:177-181`, `Player.swift`, `RevealView.swift`
**Effort:** Small (2-3 hours)
**Priority:** Critical - core game loop is incomplete without scoring

---

## 2. Build a Real Summary/Scoreboard Screen

**Problem:** `SummaryView.swift` is a stub that just says "Game Complete" with a "New Game" button. There's no scoreboard, no round history, no winner highlight. The `completeRound` action skips summary entirely and goes straight to `.setup`.

**Solution:**
- Route `.completeRound` through `.summary` phase instead of directly to `.setup`
- Redesign `SummaryView` with:
  - Player leaderboard sorted by score (with rank badges)
  - Round history expandable list (who was imposter, was caught, word)
  - "Play Again" (same players) and "New Game" (reset) buttons
  - Winner celebration animation for top scorer
- Use `CompletedRound` data that's already modeled but unused

**Files:** `SummaryView.swift` (rewrite), `GameReducer.swift:177-181`, `ContentView.swift`
**Effort:** Medium (4-6 hours)
**Priority:** Critical - players have no reason to play multiple rounds without a scoreboard

---

## 3. Fix `@unchecked Sendable` on GameState

**Problem:** `GameState` is marked `@unchecked Sendable` (line 16), which silences the compiler but doesn't fix the actual concurrency issue. Since `GameState` is a reference type (`class`), it can be mutated from multiple isolation domains without protection.

**Solution:**
Two options:
- **Option A (Recommended):** Make `GameState` a `struct` instead of a class. This eliminates the need for `.copy()` entirely since structs have value semantics. The reducer already treats it as a value type by copying before mutation.
- **Option B:** Keep as class but make it `@MainActor` isolated (like GameStore) and remove `@unchecked Sendable`.

If going with Option A, remove the `.copy()` methods from both `GameState` and `RoundState`, and update `GameReducer.reduce` to mutate a `var newState = state` directly.

**Files:** `GameState.swift`, `RoundState.swift`, `GameReducer.swift`, `GameStore.swift`
**Effort:** Medium (3-4 hours) - requires careful testing of all state transitions
**Priority:** High - potential race conditions in production

---

## 4. Wire Up Dependency Injection (Services Layer)

**Problem:** `GameStore` directly imports and calls `WordGenerator`, `HintGenerator`, and `ImageCreator`. Protocol abstractions (`WordServiceProtocol`, `ImageServiceProtocol`, etc.) and mock implementations exist but are completely unused. `AppEnvironment` exists but isn't wired up.

**Solution:**
- Define a `ServiceContainer` protocol (or use `AppEnvironment`) that holds all service protocols
- Inject it into `GameStore.init(state:services:)`
- Replace direct calls to `WordGenerator.generateWord(from:)` with `services.wordService.generateWord(from:)`
- Use `MockServices` in tests and previews
- This makes the entire side-effect layer testable

**Files:** `GameStore.swift`, `AppEnvironment.swift`, all service protocol files, test files
**Effort:** Medium (3-4 hours)
**Priority:** High - blocks testability of all AI features

---

## 5. Extract DiscussionView from ContentView

**Problem:** `DiscussionView` (~230 lines) lives inside `ContentView.swift` instead of `Features/Discussion/`. This breaks the project's feature-based organization and makes ContentView unnecessarily large.

**Solution:**
- Move `DiscussionView` to `Imposter/Features/Discussion/DiscussionView.swift`
- Keep `ContentView.swift` as a pure phase-switching router (~45 lines)
- Extract timer logic into a reusable `CountdownTimer` ObservableObject if it's needed elsewhere (voting timer)

**Files:** New `Features/Discussion/DiscussionView.swift`, modify `ContentView.swift`
**Effort:** Small (30 min)
**Priority:** Medium - code organization

---

## 6. Add User-Facing Error Handling

**Problem:** All errors (word generation, image generation, storage) are silently `#if DEBUG print()`'d. Users get no feedback when AI features fail. The word shows "GENERATING..." as a placeholder that could get stuck if generation fails.

**Solution:**
- Add an `errorMessage: String?` property to `GameStore`
- Show a `.toast` or `.alert` overlay in `ContentView` when `errorMessage` is non-nil with auto-dismiss
- For word generation failure: show brief toast, game continues with fallback word
- For image generation failure: show subtle indicator that image unavailable
- For the "GENERATING..." placeholder: add a timeout (10s) that falls back to a random word pack word
- Clear error after display or after 3 seconds

**Files:** `GameStore.swift`, `ContentView.swift`, new `Components/ErrorToast.swift`
**Effort:** Small-Medium (2-3 hours)
**Priority:** High - broken UX when AI fails silently

---

## 7. Memory Management for Generated Images

**Problem:** `UIImage` objects stored in `RoundState.generatedImage` are never cleared. Each round generates a new image but old ones persist in `gameHistory` (through `CompletedRound`) and in memory. Long sessions (5+ rounds) accumulate images without bound.

**Solution:**
- Set `roundState.generatedImage = nil` when transitioning away from `.reveal` phase
- Don't store `UIImage` in `CompletedRound` at all (it's not Codable anyway)
- Add `@IgnoreObservation` to `gameHistory` in `GameState` since it doesn't drive UI updates during gameplay
- Consider a max image cache size of ~3 images if you want to show recent images in summary

**Files:** `GameReducer.swift` (clear image on phase change), `GameState.swift` (add @IgnoreObservation)
**Effort:** Small (1 hour)
**Priority:** Medium - prevents memory pressure in long sessions

---

## 8. Break Up HomeView (947 Lines)

**Problem:** `HomeView.swift` is 947 lines containing the entire setup flow: category selection, player management, settings, and the start game UI. This is hard to maintain and likely causes unnecessary SwiftUI recomputations.

**Solution:**
- Split into focused sub-views:
  - `HomeView.swift` - Container/coordinator (~100 lines)
  - `CategorySelectionView.swift` - Category grid with selection logic
  - `PlayerSetupView.swift` - Player list add/remove/edit
  - `GameSettingsView.swift` - Settings controls (or merge with existing `SettingsSheet.swift`)
  - `StartGameSection.swift` - Start button and validation display
- Pass `GameStore` via `@Environment` to each (already the pattern)
- Use `@ViewBuilder` composition in HomeView

**Files:** `HomeView.swift` (refactor), 3-4 new files in `Features/Home/`
**Effort:** Medium (3-4 hours)
**Priority:** Medium - maintainability and performance

---

## 9. Add Vote Results Display to Reveal Phase

**Problem:** The reveal phase shows who the imposter is but doesn't display how people voted. `calculateVotingResult()` exists in the reducer but is never called from the UI. Players can't see vote tallies, who voted for whom, or whether it was a close vote.

**Solution:**
- Add a "Vote Breakdown" card to `RevealView` between the imposter reveal and secret word sections
- Show each player's vote as `PlayerA -> PlayerB` with vote count bars
- Highlight the most-voted player
- Show whether the vote was unanimous, majority, or split
- Use the existing `VotingResult` struct and `calculateVotingResult()` method

**Files:** `RevealView.swift` (add vote breakdown section)
**Effort:** Small-Medium (2-3 hours)
**Priority:** Medium - players want to see who voted for whom

---

## 10. Input Validation and Edge Cases

**Problem:** Several input validation gaps:
- Player names can be empty or whitespace-only
- Custom prompts have no length limit
- `players.randomElement()` in `createNewRound` can return nil (line 261 in GameReducer)
- No duplicate player name detection
- No handling of tie votes (most-voted just picks one)

**Solution:**
- Add `name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty` check in `.addPlayer` reducer
- Cap custom prompt at 100 characters in the UI
- Add a guard + proper fallback for `randomElement()` returning nil
- Handle vote ties explicitly: show "Tie!" result and let players re-vote or use random tiebreaker
- Disable "Start Game" button in UI when player names are invalid (not just count < 3)

**Files:** `GameReducer.swift`, `HomeView.swift` (UI validation), `RevealView.swift` (tie handling)
**Effort:** Small (2-3 hours)
**Priority:** Medium - prevents crashes and confusing states

---

## 11. Add Multi-Round Game Flow

**Problem:** After reveal, the game goes straight back to `.setup`. There's no concept of playing multiple rounds with the same players. The `startNewRound` action exists but is gated on `.summary` phase, which is never reached. `roundNumber` increments but is never displayed.

**Solution:**
- After reveal + scoring, transition to `.summary` (not `.setup`)
- In SummaryView, offer "Next Round" (keeps players, increments round) and "End Game" (final scoreboard)
- "Next Round" dispatches `.startNewRound` which creates a new round with different imposter
- Display round counter in game UI (e.g., "Round 2 of 5" or open-ended)
- Optionally add a "number of rounds" setting to GameSettings

**Files:** `GameReducer.swift`, `SummaryView.swift`, `GameSettings.swift` (optional rounds setting)
**Effort:** Medium (3-4 hours)
**Priority:** High - multi-round play is core to the party game experience

---

## 12. Complete Localization

**Problem:** `CLAUDE.md` targets 5 languages (EN, ES, FR, DE, JA) but only English strings exist in `Localizable.xcstrings`. Many strings are hardcoded rather than using `String(localized:)`.

**Solution:**
- Audit all user-facing strings and ensure they use `String(localized:)` or SwiftUI's automatic `Text("key")` localization
- Add translations for the 4 missing languages in `Localizable.xcstrings`
- Test with `.environment(\.locale, Locale(identifier: "ja"))` in previews
- Add `.minimumScaleFactor(0.7)` to text that might overflow in longer languages (German, Japanese)
- Verify word packs work regardless of locale (they're English-only game content, which is fine)

**Files:** `Localizable.xcstrings`, all view files (string audit), word pack files
**Effort:** Large (6-8 hours including translation review)
**Priority:** Low for MVP, High for App Store release

---

## 13. Expand Test Coverage

**Problem:** Tests exist for basic reducer logic and phase transitions, but there's no coverage for:
- Side effects (word/image generation flows)
- Full game loop integration (setup -> reveal)
- Scoring calculations (once implemented)
- Edge cases (tie votes, max players, empty names)
- UI tests beyond basic launch

**Solution:**
- **Unit Tests** (immediate):
  - `ScoringEngineTests` - all scoring scenarios
  - `GameReducerTests` - add edge cases (tie votes, boundary conditions)
  - `GameStoreTests` - test dispatch + side effect handling (requires DI from improvement #4)
- **Integration Tests** (after DI):
  - Full game flow: setup -> roleReveal -> clueRound -> voting -> reveal -> summary
  - Multi-round flow with score accumulation
- **UI Tests** (later):
  - Complete game flow with mock data
  - Accessibility audit test (VoiceOver navigation)
- Target: 80%+ coverage on Domain layer

**Files:** New test files in `ImposterTests/`, `ImposterUITests/`
**Effort:** Large (8-12 hours)
**Priority:** Medium - critical before App Store submission

---

## Implementation Order

Recommended sequence based on dependencies and impact:

| Phase | Improvements | Rationale |
|-------|-------------|-----------|
| **Week 1** | #1 (Scoring), #3 (Sendable fix), #5 (Extract DiscussionView) | Foundation fixes - scoring enables everything else |
| **Week 2** | #2 (Summary screen), #11 (Multi-round flow), #9 (Vote results) | Complete the game loop end-to-end |
| **Week 3** | #4 (DI/Services), #6 (Error handling), #10 (Input validation) | Robustness and testability |
| **Week 4** | #7 (Memory), #8 (Break up HomeView), #13 (Tests) | Polish, performance, quality gates |
| **Week 5** | #12 (Localization) | Final App Store readiness |

### Quick Wins (< 1 hour each)
- #5: Move DiscussionView to its own file
- #7: Clear generated image on phase transition

### Highest Impact
- #1 + #2 + #11: Together these complete the entire game loop with scoring and multi-round play
- #3: Fixes a real concurrency safety issue
- #4: Unblocks proper testing of AI features
