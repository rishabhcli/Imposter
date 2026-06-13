# Enormousplans.md

## Humongous 12-Hour Codex Goal Prompt For Imposter

This file is a paste-ready, token-hungry, goal-mode prompt for turning **Imposter** into a wildly more ambitious iOS party-game platform. It is intentionally huge. It should make the next Codex run behave like a senior iOS/product/gameplay/design/tools team working in one long session: read the real repo, ship real vertical improvements, verify them, document them, and keep raising the bar.

Paste everything under **BEGIN PROMPT** into Codex from the root of this repo:

```text
/Users/m3-max/Documents/GitHub/Imposter
```

---

## BEGIN PROMPT

You are Codex operating inside:

```text
/Users/m3-max/Documents/GitHub/Imposter
```

You are taking over **Imposter**, an iOS 26+ local-only pass-and-play social deduction party game built with Swift 6, SwiftUI, Observation, Apple Liquid Glass, on-device generation services, UserDefaults persistence, XCTest, and XCUITest.

If goal mode is available, immediately create or activate a long-running goal with this exact objective:

```text
Over the next 12 hours, transform Imposter from a working local SwiftUI social deduction game into a much larger, more generative, more beautiful, more reliable, more private, more accessible, more test-proven iOS party-game platform: a Liquid Glass game stage, offline generative word-and-image engine, rule laboratory, host console, party ritual system, accessibility-first pass-and-play experience, and release-grade engineering machine. Make concrete verified improvements continuously. Do not stop at planning. Do not ship fake or aspirational UI. Every loop must leave the actual repo measurably better.
```

If the goal tool is not available, continue anyway and behave as if that goal is active.

### Prime Directive

This is not a normal ticket. This is a monster mission.

Work like a combined staff iOS engineer, game designer, design systems lead, QA automation lead, accessibility specialist, localization lead, privacy engineer, and release captain. Your north star is intentionally too large for one person to finish in a short session. That is the point. You must still make real progress. Do not turn the enormous scope into vague strategy. Convert it into a repeated delivery loop:

```text
Read truth -> choose frontier -> implement -> verify -> self-review -> document -> raise bar -> continue.
```

You must be bold, but not reckless. Big moves are welcome when they are grounded in the actual repo. Do not ask for permission before execution. Install missing tools if needed. Use plugins when helpful. Prefer XcodeBuildMCP for iOS simulator build/run/test workflows when available. Use shell when it is the fastest reliable path.

Do not end after one green build. Do not end after one screen tweak. Do not end after one test. Do not write a plan and walk away. Use this prompt as a 12-hour engine.

### Absolute Ground Rules

1. Read `AGENTS.md` and `CLAUDE.md` first.
2. Treat the **actual source tree and Xcode project** as truth.
3. The root `README.md`, `AGENTS.md`, and `CLAUDE.md` may mention `TASKS.md` and `Implementation Plan.md`; those root files may be absent or stale. Do not restore deleted planning docs unless a real current need emerges.
4. Do not trust old phase prompts as current truth. They are historical context.
5. Preserve unrelated user changes. Never revert files you did not intentionally change.
6. Keep the reducer pure. Put side effects in `GameStore`, services, or other explicit effect boundaries.
7. Use Swift 6 strict concurrency. Prefer `Sendable` value models, `@MainActor` UI ownership, and clear task cancellation.
8. Use Observation. Do not introduce `ObservableObject` or old environment-object sprawl.
9. Keep Imposter local-only and privacy-first. No remote analytics, tracking, server sync, or off-device player data.
10. Any generative/AI feature must work gracefully when FoundationModels or ImagePlayground are unavailable.
11. Do not expose fake menu items, fake settings, fake AI options, fake multiplayer, fake store surfaces, or fake release readiness.
12. Do not delete tests. Expand tests when behavior changes.
13. Use `Localizable.xcstrings` for user-facing strings unless you are intentionally adding test-only text.
14. Every UI change must respect Dynamic Type, VoiceOver privacy, Reduce Motion, Reduce Transparency, and light/dark/high-contrast reality.
15. Every meaningful loop must update `docs/FRONTIER_LEDGER.md` with proof.
16. Final claims require proof commands and exact outcomes.

### Live Repo Signals To Respect

As of this prompt, this checkout already has a real app, not just a scaffold. Expect to find:

- `Imposter.xcodeproj`
- shared schemes named `Imposter-UnitTests` and `Imposter-UITests`
- `Imposter/App/AppEnvironment.swift`
- `Imposter/ContentView.swift`
- `Imposter/Store/GameStore.swift`
- domain models under `Imposter/Domain/Models`
- reducer/actions/scoring/word selection/generation under `Imposter/Domain`
- services and mocks for words, images, hints, storage, and haptics
- SwiftUI screens for home, setup, role reveal, clue round, discussion, voting, reveal, and summary
- Liquid Glass tokens/components under `Imposter/DesignSystem/LiquidGlass`
- word packs under `Imposter/Resources/WordPacks`
- `Imposter/Resources/Localizable.xcstrings`
- unit tests under `ImposterTests`
- UI tests under `ImposterUITests`
- continuity docs under `docs/`, especially `docs/FRONTIER_LEDGER.md`
- scripts such as localization and launch metric helpers
- an older mega prompt at `plans_Imposter.md`

Earlier verified flow knowledge to re-check, not blindly assume:

- The intended phase flow is `setup -> roleReveal -> clueRound -> discussion -> voting -> reveal -> summary`.
- `clueRound -> voting` should not bypass hosted discussion.
- Stable verification previously used an iPhone 17 Pro iOS 26 simulator when iPhone 16 Pro was unavailable.
- Unit and UI schemes existed as `Imposter-UnitTests` and `Imposter-UITests`.
- The UI robot, privacy handoff tests, reduced-motion/reduced-transparency checks, launch performance lane, and localization coverage gate may already exist. Inspect before duplicating.

### First 20 Minutes: Baseline And Truth Extraction

Start with a tight, factual inventory. Do not spend the first hour merely reading. Read enough to choose the first high-impact frontier, then start shipping.

Run:

```bash
pwd
find . -maxdepth 3 -type f \( -path './.git/*' -o -name '*.xcuserstate' \) -prune -o -type f -print | sort | sed -n '1,260p'
xcodebuild -list -project Imposter.xcodeproj
xcrun simctl list devices available
```

Try git status, but if `git status` hangs in this checkout, do not get stuck. Use narrower diff commands:

```bash
GIT_OPTIONAL_LOCKS=0 git diff --name-only
GIT_OPTIONAL_LOCKS=0 git diff --cached --name-only
GIT_OPTIONAL_LOCKS=0 git ls-files --others --exclude-standard | sed -n '1,200p'
```

Read:

```text
AGENTS.md
CLAUDE.md
README.md
plans_Imposter.md
docs/FRONTIER_LEDGER.md
Imposter/App/AppEnvironment.swift
Imposter/ContentView.swift
Imposter/Store/GameStore.swift
Imposter/Domain/Actions/GameAction.swift
Imposter/Domain/Models/*.swift
Imposter/Domain/Logic/*.swift
Imposter/Services/Protocols/*.swift
Imposter/Services/Implementations/*.swift
Imposter/Services/Mocks/*.swift
Imposter/DesignSystem/LiquidGlass/**/*.swift
Imposter/Features/**/*.swift
ImposterTests/**/*.swift
ImposterUITests/**/*.swift
scripts/*.py
```

Then produce a short baseline note for yourself:

```text
Current build schemes:
Current simulator chosen:
Dirty worktree files I must preserve:
Current highest risks:
Fastest reliable test gate:
First frontier:
```

Do not stop and report this baseline to the user unless blocked. Use it to act.

### 12-Hour Operating Cadence

Run the mission in cycles. Each cycle should be long enough to ship a real improvement and short enough to avoid wandering.

Use this cadence:

```text
Cycle 0: Orientation and baseline. 20-30 minutes.
Cycle 1: Stabilize the highest-risk existing issue. 45-90 minutes.
Cycle 2: Ship a visible UI/design-system improvement. 60-120 minutes.
Cycle 3: Ship a generative/offline-AI improvement. 60-120 minutes.
Cycle 4: Expand tests/robots/simulations around the new behavior. 45-90 minutes.
Cycle 5: Ship a second vertical product slice, preferably crossing UI + rules + tests. 90-150 minutes.
Cycle 6: Accessibility/localization/privacy hardening. 60-120 minutes.
Cycle 7: Performance/release/readiness hardening. 60-120 minutes.
Cycle 8+: Continue the frontier loop until time, context, or the user stops you.
```

Every 25-40 minutes, write a compact continuity note in `docs/FRONTIER_LEDGER.md` if you have made meaningful progress or discovered an important blocker. Context can compact. The ledger is how the next run wakes up without amnesia.

### Scoreboard

At the beginning of the mission and after each major loop, score the app from 0 to 5 on these axes:

```text
Domain correctness:
Gameplay completeness:
Generative/offline AI quality:
Word/content engine:
Liquid Glass design fit:
Visual polish:
Motion/haptics:
Pass-and-play privacy:
VoiceOver/accessibility:
Dynamic Type/layout resilience:
Localization:
Persistence safety:
Testing depth:
UI automation:
Performance/memory:
Release readiness:
Repo clarity:
```

Use the score to choose work. A glamorous feature is not worth shipping if a 1/5 trust axis is blocking the product.

### The Recursive Delivery Loop

Repeat this loop for the full session:

```text
1. Observe:
   Read the current code and proof. Identify real gaps, not imaginary ones.

2. Pick:
   Choose one frontier that can produce a concrete improvement now.

3. Shape:
   Write a tiny internal execution plan: files to edit, tests to add, proof to run.

4. Implement:
   Patch code directly. Keep reducer purity and service boundaries.

5. Verify:
   Build/test the smallest relevant surface first, then widen.

6. Self-review:
   Inspect diff like a code reviewer. Fix missing a11y, localization, concurrency,
   privacy, fake UI, force unwraps, magic numbers, and test holes.

7. Harden:
   Add tests, scripts, fixtures, mocks, or docs that prevent regression.

8. Ledger:
   Update `docs/FRONTIER_LEDGER.md` with files, proof, risk, and next frontier.

9. Raise:
   If green, choose the next harder frontier. Continue.
```

Never spin without a shippable delta. If the backlog looks empty, raise the standard.

### Verification Contract

Prefer XcodeBuildMCP for simulator workflows when available. Before first XcodeBuildMCP build/run/test in this session, check session defaults. If defaults are correct, use them; otherwise discover projects/schemes/simulators.

Shell fallback fast gate:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build -project Imposter.xcodeproj -scheme Imposter-UnitTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UnitTests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Shell fallback UI gate:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

If the named simulator is unavailable, choose the best iOS 26 simulator and record the exact destination. If a test is flaky, rerun once after simulator cleanup only when evidence points to simulator flakiness. Do not hide real failures as flake.

For docs/scripts:

```bash
python3 -m py_compile scripts/*.py
python3 -m json.tool Imposter/Resources/Localizable.xcstrings >/dev/null
git diff --check
```

For UI/design work, proof must include at least one of:

- simulator launch and interaction
- XCUITest path over the changed screen
- screenshot/capture via available tools
- accessibility-tree assertion
- reduced motion/transparency UI argument proof
- localization/pseudo-localization proof
- focused view preview/build proof when runtime launch is blocked

Do not claim physical-device AI success unless you actually verified on a physical device. Simulator fallback success is not device proof.

---

# The Enormous Product Vision

The end state should feel like Imposter grew from a single social deduction game into a private, offline, generative party-game platform that could anchor years of product work.

Think in these terms:

```text
Imposter today: pass-and-play word game.
Imposter after this mission: a cinematic local party ritual engine.
Imposter in the 10-year fantasy: an offline social deduction operating system for phones, iPads, living rooms, classrooms, travel, families, streamers, and tabletop groups.
```

The product must remain playable after every step. Big vision, small verified slices.

## Pillar 1: Unbreakable Game Engine

The game engine should become boringly correct. No invalid phase skips. No impossible votes. No secret leaks through state. No scoring weirdness after repeated rounds. No round history corruption.

Target capabilities:

- Formalized `GameRules` layer if it exists; create or strengthen it if needed.
- Settings normalization boundary that clamps invalid settings before the reducer sees them.
- Exhaustive `GamePhase.canTransition(to:)` tests.
- Reducer coverage for every `GameAction`.
- Model-based tests generating random valid and invalid gameplay sequences.
- 3-player, 4-player, 5-player, 8-player, and 10-player fixtures.
- 1000-round tournament simulations in unit tests or a dedicated performance-safe test.
- Tests for corrupted persisted players/settings.
- Tests proving history caps remain coherent.
- Tests proving all generated/prepared rounds contain exactly one valid imposter.
- Tests proving hidden mode, classic mode, custom prompt mode, and AI-unavailable mode preserve invariants.
- Tests proving no self-vote, duplicate vote weirdness, early voting completion, or clue-order corruption.
- A small `GameInvariant` helper in tests if useful.

Do not over-abstract for its own sake. If the current reducer is clean, extend it carefully.

## Pillar 2: Generative Offline AI Engine

The generative layer should feel magical when available and invisible when unavailable. This product should never require network access.

Target capabilities:

- Clear capability detection for local word generation, hint generation, and image generation.
- A user-facing AI availability state that is honest, quiet, and not scary.
- Custom prompt -> safe secret word -> category hint -> optional imposter hint -> optional generated image.
- Local fallback word selection when generation fails, times out, is cancelled, or is unavailable.
- Generated word cleanup:
  - trim whitespace
  - reject empty output
  - reject multi-sentence rambles
  - reject unsafe/private/personal data prompts where practical
  - normalize capitalization
  - avoid exact prompt echo when the prompt is not a word
  - avoid duplicates from current round/history where practical
- Hint generation that does not unfairly reveal the word to the imposter.
- Hidden mode alternate word generation/selection with semantic distance checks where practical.
- Image generation lifecycle:
  - loading state
  - success state
  - failure state
  - cancellation when leaving round
  - memory cleanup after summary/new round
  - no generated-image persistence unless intentionally designed
- Deterministic mocks for success/delay/failure/cancellation.
- UI tests proving custom prompt flow remains playable without AI.
- Unit tests proving timeouts fall back.
- A local "Generation Lab" debug/test-only harness if useful, hidden from Release.

Possible concrete first slices:

- Add `GenerationStatus` value model and expose it in `GameStore`.
- Add a `GeneratedContentPolicy` for cleanup/fallback rules.
- Add tests for prompt cleanup and fallback.
- Add a setup-screen AI availability chip that is honest and accessible.
- Add a "Surprise me" local generator using existing packs if FoundationModels is unavailable.

Do not add cloud calls. Do not add API keys. Do not store secrets.

## Pillar 3: Liquid Glass UI Rebirth

The UI should stop feeling like a handful of screens and start feeling like a designed party stage. It should be premium, native, responsive, privacy-aware, and not a one-note neon/dark theme.

Current design signals to inspect:

- `LGColors` currently has strong dark red/burgundy accents plus some neon utilities.
- `HomeView` uses a starfield/black background and large hero treatment.
- `LGCard`, `LGButton`, `LGBadge`, `LGTextField`, `AnimatedBackground`, and gyro/parallax effects already exist.
- `ContentView` currently forces dark mode. Challenge whether that is still correct after light-mode requirements.

Target design direction:

- Build a coherent "party ritual" interface:
  - home as a host console
  - setup as a party roster table
  - role reveal as a privacy ritual
  - clue round as a spotlight stage
  - discussion as a table-talk timer
  - voting as a secret ballot booth
  - reveal as a dramatic accusation sequence
  - summary as a scoreboard and story recap
- Replace decorative clutter with purposeful stateful surfaces.
- Use native Liquid Glass APIs correctly:
  - `GlassEffectContainer` where multiple glass elements live together
  - `.glassEffect` after layout/appearance modifiers
  - `.interactive()` only for interactive elements
  - `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` where appropriate
  - iOS 26 availability/fallback if needed
- Make iPad intentional:
  - split host/players panels
  - wide summary scoreboard
  - grid voting layout
  - no stretched phone composition
- Make small iPhone intentional:
  - no clipped buttons
  - stable action bar
  - scrollable content where necessary
  - keyboard-safe setup and custom prompt input
- Make Dynamic Type intentional:
  - text wraps
  - buttons keep touch target
  - hero typography shrinks responsibly
  - secret words do not overlap cards
- Make color richer:
  - avoid one-note red/dark sameness
  - use player colors for identity
  - use semantic success/warning/error colors
  - add non-color cues for player identity
  - ensure high contrast/readability
- Make motion meaningful:
  - role reveal has a privacy-safe hold/flip/reveal rhythm
  - voting feels like committing a ballot
  - reveal has staged suspense
  - summary celebrates without nausea
  - Reduce Motion removes unnecessary choreography
- Make haptics purposeful:
  - start game
  - hold-to-reveal threshold
  - clue submit
  - vote cast
  - reveal
  - round complete

Possible concrete UI slices:

- Create a reusable `PhaseChrome` or `GameStage` wrapper for phase title, progress, privacy status, and action footer.
- Refactor one screen at a time into smaller subviews with stable dimensions and accessibility IDs.
- Add a bottom "host rail" for current phase, round, active player, and next action.
- Replace in-app explanatory text with direct controls and state where possible.
- Add a polished scoreboard with player color swatches, deltas, and round history.
- Add long-name and accessibility-size UI tests for player setup and voting.

Do not just add cards inside cards. Do not make every section float in a card. Do not use decorative orbs/blobs. Do not make a landing page. The first screen should be the app.

## Pillar 4: Party Ritual And Host Experience

The product should feel like it knows how parties actually work: people fumble phones, forget whose turn it is, peek accidentally, argue, laugh, and need clear prompts.

Target capabilities:

- Host console:
  - start/resume game
  - player roster
  - quick add names
  - randomize colors/emojis
  - choose mode
  - choose word source
  - configure rounds/timers
  - see privacy status
- Setup ergonomics:
  - add 3 players quickly
  - edit names inline
  - prevent duplicate/empty names or warn gracefully
  - random party name generator
  - player color/emoji selector
  - persisted roster with safe clear
- Pass-and-play handoff:
  - clear "hand to X" screen
  - secret hidden until deliberate hold/action
  - blank/covered transition between players
  - VoiceOver-safe private labels
  - app switcher privacy shield
- Discussion:
  - optional timer
  - pause/resume
  - clue recap that does not reveal hidden information unfairly
  - "ready to vote" transition
- Voting:
  - private ballots
  - no self-vote
  - progress without revealing choices
  - vote handoff privacy
- Reveal:
  - staged reveal of voted suspect, actual imposter, secret word
  - imposter guess flow if enabled
  - clear result explanation
- Summary:
  - score deltas
  - round story
  - play again
  - return to setup
  - mode/settings recap

Possible first slices:

- Add duplicate-name validation with UI feedback and tests.
- Build a player quick-fill/test-only fixture path for UI tests only.
- Add a better summary scoreboard with score deltas and round history.
- Add a clue recap panel in discussion with privacy review.
- Add a host rail that travels across phases.

## Pillar 5: Game Modes And Rule Laboratory

Imposter should become a rule platform, but every exposed mode must be real.

Existing modes/signals to inspect:

- `GameSettings.GameMode.classic`
- `GameSettings.GameMode.hidden`
- custom prompt word source
- imposter hints
- clue/discussion/voting timer settings
- number of rounds

Potential future modes:

- Classic:
  - one imposter knows they are imposter
  - imposter receives category/hint
- Hidden Imposter:
  - imposter gets a decoy word and does not know they are imposter
  - fairness depends on alternate-word distance
- No-AI:
  - pack-only, zero generation surfaces
  - clear offline mode
- Kids:
  - safer/easier word packs
  - softer reveal copy
  - simplified scoring
- Speed Round:
  - timers on, one clue, rapid vote
- Deep Table:
  - multiple clue rounds, longer discussion, history recap
- Tournament:
  - fixed rounds, leaderboard, tiebreaks
- Teams:
  - only after rules and UI are fully designed
- Multiple Imposters:
  - only if fairness, voting, scoring, role reveal, and tests are complete
- Decoy Word:
  - informed players get secret word, imposter gets plausible decoy

Rule-system requirements:

- Normalize settings before starting a round.
- Expose only supported modes.
- Each mode must have:
  - domain invariants
  - reducer tests
  - setup UI
  - role reveal copy
  - voting/reveal behavior
  - scoring tests
  - UI path or focused proof
  - accessibility labels
  - localized strings or tracked localization debt

Possible first slices:

- Create/strengthen `GameRules` with `validate(settings:playerCount:)`.
- Add a `RuleSummary` model that produces localized-ready descriptions.
- Add tests proving hidden mode always has a distinct imposter word or graceful fallback.
- Hide any unsupported settings that do nothing.

## Pillar 6: Word Universe And Content Pipeline

The word packs should become a robust offline content engine.

Target capabilities:

- Validate all word pack JSON at test time.
- Enforce schema:
  - id
  - display text
  - category
  - difficulty
  - tags
  - localization key if localized
  - safety metadata if needed
- 5+ categories, 100+ usable entries each if feasible.
- Duplicate detection across categories.
- Case-insensitive normalization.
- Difficulty distribution checks.
- Profanity/unsafe term checks where practical.
- Tests for missing, empty, corrupt, partial, and duplicate packs.
- Localized word display strategy.
- Pack browser UI in setup, not just raw category names.
- "Surprise pack" or "balanced mix" selection.
- Custom prompt fallback into pack word when generator fails.
- Round-history-aware word avoidance.

Possible first slices:

- Add `scripts/check_word_packs.py` and wire it into docs/ledger.
- Add unit tests for word pack integrity.
- Add category metadata UI with counts/difficulty.
- Add last-N word avoidance in `WordSelector`.

## Pillar 7: Accessibility Beyond Checkbox Quality

Accessibility is central because pass-and-play secrecy is unusually sensitive.

Target capabilities:

- VoiceOver never reads a secret word except when the current player explicitly reveals their private role.
- Handoff screens hide secret content from accessibility tree.
- Role cards provide sanitized accessibility labels.
- Phase changes announce clearly.
- Buttons have labels and hints.
- Custom gestures have accessible alternatives.
- Dynamic Type up to accessibility sizes works.
- Reduce Motion disables unnecessary transitions.
- Reduce Transparency provides solid readable fallbacks.
- High contrast remains readable.
- Color is never the only player identifier.
- Minimum touch targets are preserved.
- UI tests or accessibility-tree tests cover secret surfaces.
- Manual checklist in ledger for anything automation cannot prove.

Possible first slices:

- Audit every `Button`, `TextField`, custom gesture, and secret text surface for labels/hints/privacy.
- Add `AccessibilityIDs` for every critical action and screen.
- Add UI test for accessibility-size player setup/voting.
- Add a VoiceOver privacy test path where possible.

## Pillar 8: Localization That Survives Real Text

Localization must be treated like a product surface, not a string dump.

Target capabilities:

- All user-facing strings move into `Localizable.xcstrings`.
- English, Spanish, French, German, Japanese coverage increases steadily.
- Priority strings:
  - privacy
  - role reveal
  - secret word
  - voting
  - reveal
  - errors
  - settings
  - AI unavailable/fallback
- Placeholder parity checks.
- JSON sanity checks.
- Pseudo-localization or long-string stress if practical.
- UI tests for at least home/setup/start path in two non-English locales.
- Screenshot/capture evidence for long translations where possible.

Possible first slices:

- Extend `scripts/check_localization_coverage.py` thresholds.
- Extract one whole screen to localized strings.
- Add locale launch arguments to UI tests.
- Fix layout for longest strings discovered.

## Pillar 9: Privacy And Local-Only Trust

Imposter must feel safe to use around friends.

Target capabilities:

- No network entitlements or remote endpoints.
- Privacy statement in README/docs.
- App switcher privacy shield.
- Secret surfaces marked privacy-sensitive where appropriate.
- No secret words in logs.
- No generated images persisted unexpectedly.
- No analytics.
- No clipboard use unless user-initiated.
- No prompts/data sent off-device.
- Clear AI language: on-device when available, fallback otherwise.
- UI tests for handoff screens and secret absence.
- Release checklist includes privacy manifest/app privacy answers.

Possible first slices:

- Search for `URLSession`, `http`, `analytics`, `print`, `UIPasteboard`, and secret logging.
- Add a privacy audit doc/checklist.
- Convert debug `print` in reducer error paths to structured logging outside pure reducer if appropriate.
- Add test proving privacy shield covers in-game forced mode.

## Pillar 10: Persistence, Resume, And Resilience

The game should survive normal app life without corrupting state.

Target capabilities:

- Persist safe setup data:
  - players
  - settings
  - maybe last categories
- Decide intentionally whether active round state should persist.
- Corrupt persistence fallback.
- Versioned storage keys/migrations.
- "Clear saved roster" affordance.
- No crash on removed categories or old settings.
- Tests with mock storage failures.
- UI error toast tested where practical.

Possible first slices:

- Add settings persistence if missing.
- Add decode-failure tests.
- Add storage migration version.
- Add clear roster/settings flow.

## Pillar 11: Performance And Memory Lab

The app should prove it stays smooth.

Target capabilities:

- Launch metric extracted and tracked.
- Two-round and 10-player UI runtime labs.
- Memory capture lane documented.
- Generated image memory released after round.
- No runaway timers/tasks after leaving screens.
- No repeated motion manager work when Reduce Motion is enabled.
- No expensive work in SwiftUI body.
- Stable identity in lists/grids.
- No layout thrash from dynamic text.
- Instruments/ETTrace notes if available.

Possible first slices:

- Add or strengthen launch metric parser.
- Run existing runtime UI tests and attach timing.
- Inspect `MotionManager` and gyro card lifecycle.
- Add cancellation for generation tasks.
- Add performance guard around repeated hosted rounds.

## Pillar 12: Release Machine

The repo should be able to move toward TestFlight without chaos.

Target capabilities:

- Release build passes.
- Debug/test-only UI hidden from Release.
- Schemes clear.
- README accurate to current repo.
- AGENTS/CLAUDE accurate or explicitly historical where needed.
- App icon present and sane.
- Screenshot plan.
- Privacy statement.
- Localization status.
- Accessibility checklist.
- Known physical-device-only AI checks.
- No secrets.
- CI workflow understood and repaired if failing.

Possible first slices:

- Update README to stop claiming missing files are primary workflow, if appropriate.
- Add `docs/RELEASE_CHECKLIST.md`.
- Add `docs/PRIVACY.md`.
- Verify Release configuration build.
- Verify `.github/workflows/ci.yml` matches real schemes.

## Pillar 13: Repository As A Self-Improving Machine

Future agents should have a better starting point than you did.

Target capabilities:

- `docs/FRONTIER_LEDGER.md` remains current.
- Scripts replace repeated brittle command sequences.
- Tests encode discoveries.
- UI test helper functions stay maintainable.
- Accessibility IDs are centralized.
- Design system components are documented by usage.
- Plans distinguish live truth from historical prompts.
- Each loop leaves a next frontier.

Possible first slices:

- Add `docs/CURRENT_STATE.md` if the README/CLAUDE mismatch is causing confusion.
- Update `AGENTS.md` only if it has a real harmful gap.
- Add a `scripts/verify_local.sh` if repeated commands are stable and useful.

---

# The First Frontier Menu

After baseline, choose one of these as the first implementation frontier. Pick based on actual evidence.

## Option A: UI Rebirth Slice

Goal:

```text
Create a reusable phase-stage shell that gives all gameplay phases a more polished, consistent, Liquid Glass-native structure without breaking the existing UI robot.
```

Likely work:

- Add `GameStageView` or `PhaseChrome` under `DesignSystem/LiquidGlass/LGComponents` or a sensible feature-shared location.
- Include phase title, round badge, active player, progress, privacy cue, and action footer slots.
- Adopt it in one or two screens first, not all screens blindly.
- Use existing tokens/components.
- Add accessibility labels.
- Add UI test assertions for the changed screen.
- Build and run relevant UI test.

Why this is high leverage:

- Improves visual polish.
- Reduces screen inconsistency.
- Creates a structure for future generative/status surfaces.

## Option B: Generative Reliability Slice

Goal:

```text
Make custom prompt word generation safer and more transparent by adding generated content policy, explicit generation status, deterministic fallback tests, and UI status.
```

Likely work:

- Add `GeneratedContentPolicy`.
- Normalize generated words.
- Reject bad generated output.
- Add fallback selection path.
- Add status enum in `GameStore`.
- Surface AI availability/status in setup.
- Add mock service tests for success/failure/timeout.

Why this is high leverage:

- Directly answers "more generative".
- Keeps local-only trust.
- Makes AI failure non-blocking and testable.

## Option C: Rule Laboratory Slice

Goal:

```text
Create a settings validation and rule summary layer so current and future modes cannot expose invalid or fake behavior.
```

Likely work:

- Add or strengthen `GameRules`.
- Normalize settings against player count.
- Generate rule summary.
- Add tests for classic/hidden/custom prompt/timers/round counts.
- Wire setup UI to show concise rule summary.

Why this is high leverage:

- Supports years of future modes.
- Reduces reducer edge cases.
- Improves setup clarity.

## Option D: Accessibility/Privacy Deepening Slice

Goal:

```text
Prove pass-and-play secrecy across visual, accessibility, and inactive app states, then fix any leaks.
```

Likely work:

- Audit role reveal, voting, reveal, summary.
- Add/repair `.privacySensitive()`.
- Add accessibility labels that avoid secret text.
- Add UI tests for secret absence.
- Add forced privacy shield screenshot if not already present.

Why this is high leverage:

- Trust is core to this game.
- Regression tests prevent future visual polish from leaking secrets.

## Option E: Word Universe Slice

Goal:

```text
Turn word packs into validated offline content with duplicate/difficulty/category checks and visible category metadata.
```

Likely work:

- Add `scripts/check_word_packs.py`.
- Add unit test or script gate for pack integrity.
- Show category counts/difficulty in setup.
- Add fallback tests for missing/corrupt packs.

Why this is high leverage:

- Improves play variety.
- Supports generative fallback.
- Makes content scalable.

Pick one. Ship it. Verify it. Ledger it. Then pick the next.

---

# Massive Backlog: Concrete Work Items

Use this backlog as fuel. Do not blindly do it in order. Choose based on impact and proof.

## Domain And Rules

1. Audit every `GameAction` and create reducer coverage for untested paths.
2. Add a `GameInvariants` test helper.
3. Add random valid gameplay sequence tests.
4. Add random invalid action fuzz tests.
5. Add 1000-round tournament simulation.
6. Add 10-player maximum-flow domain test.
7. Add hidden-mode alternate-word tests.
8. Add custom prompt fallback tests.
9. Add settings normalization.
10. Add rule summary generation.
11. Add no-fake-mode guardrails.
12. Add score-delta model for summaries.
13. Add tie handling tests.
14. Add imposter word-guess scoring tests.
15. Add number-of-rounds tournament completion logic if missing.
16. Add clear end-game semantics.
17. Add history cap tests.
18. Add player duplicate-name policy.
19. Add player removal persistence tests.
20. Add corrupted settings migration tests.

## Generative AI And Content

21. Add generated content policy.
22. Add generation status model.
23. Add custom prompt cleanup.
24. Add generation timeout tests.
25. Add generation cancellation tests.
26. Add unavailable FoundationModels UI copy.
27. Add unavailable ImagePlayground UI copy.
28. Add deterministic fallback from word packs.
29. Add generated image lifecycle cleanup.
30. Add generated image memory release proof if practical.
31. Add safe hint rules.
32. Add hidden-mode decoy distance heuristic.
33. Add "surprise me" pack-only generator.
34. Add local generated category suggestions.
35. Add generated word duplicate avoidance.
36. Add prompt history that stores only safe local settings if desired.
37. Add AI debug lab hidden in Debug only.
38. Add mock services for slow generation.
39. Add mock services for malformed generation output.
40. Add docs for device-only AI verification.

## Word Packs

41. Add word pack integrity script.
42. Add duplicate detector.
43. Add difficulty distribution check.
44. Add category count check.
45. Add missing/corrupt/empty pack tests.
46. Add category metadata model.
47. Add category icons/symbols.
48. Add category selection UI with counts.
49. Add last-N word avoidance.
50. Add localized word strategy.
51. Add kids-safe category or label only if content is real.
52. Add pack browser UI.
53. Add balanced-mix selector.
54. Add test fixture packs.
55. Add README content status.

## UI And Design System

56. Audit `LGColors` for one-note palette and contrast.
57. Add richer semantic design tokens.
58. Add `PhaseChrome`/`GameStage`.
59. Add persistent host rail.
60. Add better player roster component.
61. Add category tiles with metadata.
62. Add improved setup validation.
63. Add polished role reveal card.
64. Add accessible hold-to-reveal alternative.
65. Add clue stage with active-player spotlight.
66. Add discussion table with clue recap.
67. Add voting booth UI.
68. Add reveal sequence.
69. Add score-delta summary.
70. Add round history timeline.
71. Add iPad split layouts.
72. Add landscape sanity.
73. Add small-phone layout fixes.
74. Add large Dynamic Type layout fixes.
75. Add reduce transparency fallbacks for every glass surface.
76. Add reduce motion alternatives for every animated transition.
77. Add high-contrast pass.
78. Remove forced dark mode if light mode is intended.
79. Add preview fixtures for every phase.
80. Add screenshot evidence for key screens.

## Party Experience

81. Add quick-add players.
82. Add player emoji selector.
83. Add random player names.
84. Add clear saved roster.
85. Add setup resume.
86. Add host settings summary.
87. Add timer UI for clue/discussion/voting if not real.
88. Add pause/resume timer.
89. Add haptic design map.
90. Add sound setting only if sound is actually implemented.
91. Add "pass device" privacy state between every private action.
92. Add private vote handoff proof.
93. Add secret-safe clue recap.
94. Add "ready check" before reveal.
95. Add new-round settings carryover.

## Accessibility

96. Audit all buttons.
97. Audit all text fields.
98. Audit all custom gestures.
99. Audit all secret text.
100. Add phase change announcement tests if practical.
101. Add VoiceOver-safe role labels.
102. Add UI test for secret word absent from accessibility tree.
103. Add large content size UI test.
104. Add reduced motion UI test.
105. Add reduced transparency UI test.
106. Add high contrast notes.
107. Add color-independent identity cues.
108. Add minimum hit target audit.
109. Add accessible timer labels.
110. Add manual a11y checklist.

## Localization

111. Extract home strings.
112. Extract setup strings.
113. Extract role reveal strings.
114. Extract clue strings.
115. Extract discussion strings.
116. Extract voting strings.
117. Extract reveal strings.
118. Extract summary strings.
119. Extract settings strings.
120. Extract AI/error strings.
121. Raise localization coverage floor.
122. Add placeholder parity checks.
123. Add long-string UI test.
124. Add Spanish launch path.
125. Add German launch path.
126. Add Japanese launch path.
127. Add pseudo-locale notes.
128. Add screenshot proof for non-English screen.

## Testing And Automation

129. Stabilize unit scheme.
130. Stabilize UI scheme.
131. Add end-to-end 3-player robot if missing.
132. Add 10-player robot.
133. Add custom prompt robot with mock generation.
134. Add hidden mode robot.
135. Add privacy shield robot.
136. Add launch performance lane.
137. Add two-round runtime lab.
138. Add memory capture lane.
139. Add result bundle parser script.
140. Add verification script if commands stabilize.
141. Add CI scheme fix if needed.
142. Add screenshot attachments for visual changes.
143. Add accessibility identifier coverage map.
144. Add deterministic seed for UI testing.
145. Add simulator cleanup notes.

## Performance And Reliability

146. Audit SwiftUI bodies for expensive work.
147. Audit async tasks for cancellation.
148. Audit timers for leaks.
149. Audit motion manager usage.
150. Audit image memory lifecycle.
151. Audit UserDefaults writes.
152. Add OSLog instead of print spam where appropriate.
153. Add launch metric tracking.
154. Add frame/runtimes notes.
155. Add memory graph notes.
156. Add release build check.
157. Add app lifecycle tests.
158. Add background/foreground privacy proof.
159. Add no-network audit.
160. Add crash/log scan.

## Release And Docs

161. Update README to match live repo.
162. Update AGENTS/CLAUDE only if needed.
163. Add `docs/CURRENT_STATE.md`.
164. Add `docs/PRIVACY.md`.
165. Add `docs/ACCESSIBILITY.md`.
166. Add `docs/RELEASE_CHECKLIST.md`.
167. Add `docs/AI_DEVICE_VERIFICATION.md`.
168. Add `docs/UI_DESIGN_DIRECTION.md`.
169. Add app screenshot plan.
170. Add TestFlight readiness checklist.
171. Verify app icon catalog.
172. Verify privacy manifest needs.
173. Verify no secrets.
174. Verify no debug-only UI in Release.
175. Keep frontier ledger current.

---

# Detailed 12-Hour Execution Blueprint

Use this as a map, not a cage. If baseline reveals a serious failure, fix that first.

## Hour 0: Ground Truth And Baseline

Deliverable:

- factual baseline in ledger
- chosen simulator
- chosen first frontier
- known dirty files
- current proof status

Commands:

```bash
pwd
xcodebuild -list -project Imposter.xcodeproj
xcrun simctl list devices available
python3 -m json.tool Imposter/Resources/Localizable.xcstrings >/dev/null
python3 -m py_compile scripts/*.py
git diff --check
```

If build/test is already red, first frontier becomes stabilization.

## Hours 1-2: Stabilization Or First Vertical Slice

If red:

- fix compile/test failures
- rerun failed command
- ledger exact error and fix

If green:

- choose UI rebirth, generative reliability, rule lab, privacy, or word universe
- make one cohesive code change
- add tests
- run focused proof

## Hours 2-4: UI Rebirth

Deliverable:

- one gameplay phase visibly upgraded
- reusable design-system primitive or screen-level pattern
- no broken UI robot
- accessibility and reduce-motion/transparency considered

Strong choices:

- `PhaseChrome`
- improved summary scoreboard
- improved setup category/player flow
- improved role reveal privacy ritual
- improved voting booth

Proof:

- build
- focused UI test
- screenshot/attachment if available
- `git diff --check`

## Hours 4-6: Generative Engine

Deliverable:

- safer custom prompt / generation flow
- explicit status/fallback
- tests for success/failure/unavailable

Strong choices:

- `GeneratedContentPolicy`
- generation status enum
- setup status chip
- fallback pack word
- cancellation cleanup

Proof:

- unit tests for services/store/policy
- UI test with mock unavailable/failed generation if practical
- no network calls

## Hours 6-7: Game Rules And Content

Deliverable:

- stronger settings/rules/content validation
- no fake mode exposure
- word pack validation or rules summary

Strong choices:

- `GameRules`
- `RuleSummary`
- word pack script
- hidden-mode fairness guard

Proof:

- unit tests
- script checks
- build

## Hours 7-8: Accessibility And Localization

Deliverable:

- one high-risk screen fully a11y/localization audited
- tests or script floor raised

Strong choices:

- role reveal
- voting
- reveal
- setup

Proof:

- UI accessibility assertion
- localization script
- JSON validation
- focused UI test

## Hours 8-10: Automation And Performance

Deliverable:

- stronger UI robot/performance/memory proof
- no hidden flaky lane

Strong choices:

- 10-player rendered flow
- custom prompt rendered flow
- hidden-mode rendered flow
- launch metric extraction
- memory capture notes

Proof:

- result bundle
- timing attachment
- metric parser
- ledger exact outcome

## Hours 10-12: Polish, Release, And Next Frontier

Deliverable:

- docs reflect live truth
- full gate or best attainable gate
- next frontier is sharp

Strong choices:

- update README/AGENTS if misleading
- add privacy/release checklist
- run full unit/UI gates
- write continuation notes

Proof:

- exact commands
- exact pass/fail
- blockers documented with next command

---

# Coding Style And Architecture Rules

Follow local patterns first.

Swift/SwiftUI:

- Keep view bodies simple.
- Extract small subviews with clear names.
- Prefer value models.
- Prefer explicit injection for feature-local dependencies.
- Keep shared services in app environment/store patterns already present.
- Avoid `AnyView` unless there is a strong reason.
- Avoid force unwraps.
- Avoid magic numbers.
- Use named constants for repeated layout/time values.
- Keep comments sparse and useful.
- Keep accessibility modifiers close to the relevant view.
- Use `#Preview` fixtures for meaningful states where practical.

Reducer/store/services:

- Reducer stays pure.
- Reducer should not log noisy side effects.
- Store handles async side effects.
- Services handle external/local framework work.
- Mocks should make tests deterministic.
- Long-running tasks should be cancellable where ownership matters.
- Generation should not block main thread.

Design:

- Use existing `LGColors`, `LGTypography`, `LGSpacing`, `LGMaterials`, `LGCard`, `LGButton`, `LGBadge`, `LGTextField`, and `AnimatedBackground` unless they need careful improvement.
- Prefer symbols/icons in buttons where a standard icon exists.
- Do not put cards inside cards.
- Do not make text overlap.
- Do not use viewport-scaled font sizes.
- Do not force huge hero text into compact panels.
- Do not build fake landing pages.
- Do not add decorative gradient blobs/orbs.
- Do not overuse one color family.
- Stable dimensions for boards, grids, action bars, progress controls, and vote tiles.

Tests:

- Add tests proportional to risk.
- Prefer deterministic fixtures.
- Use UI test accessibility IDs rather than brittle text where possible.
- When text matters for localization/privacy, assert text intentionally.
- Separate simulator flake from real product failure with evidence.

Docs:

- Keep ledger current.
- Keep docs concise.
- Do not rewrite the whole repo docs unless needed.
- Call out simulator-only vs physical-device proof clearly.

---

# Self-Review Gate Before Every Milestone Claim

Before declaring a loop complete, answer:

```text
Did I build the changed target?
Did I run relevant tests?
Did I preserve unrelated user changes?
Did I avoid fake UI?
Did I keep local-only privacy?
Did I avoid secret leaks?
Did I consider accessibility?
Did I consider localization?
Did I consider Reduce Motion/Transparency for UI changes?
Did I update or add tests when behavior changed?
Did I update the frontier ledger?
Did I leave a sharper next frontier?
```

If any answer is no, fix it or document the exact blocker.

---

# Recovery Playbooks

## If Build Fails

1. Read exact compiler error.
2. Open the owning file.
3. Fix smallest cause.
4. Rebuild failed target.
5. If behavior changed, add a regression test.
6. Ledger only after proof.

## If Unit Tests Fail

1. Identify first failing assertion.
2. Decide whether test or product is wrong.
3. Fix product if it caught a real bug.
4. Fix test only if assumptions are stale.
5. Rerun focused test, then suite.

## If UI Tests Fail

1. Check whether app reached expected screen.
2. Check accessibility ID.
3. Check for animation/timing issue.
4. Check simulator logs if needed.
5. Prefer stable product selectors over sleeps.
6. Rerun focused UI test.
7. Rerun full UI gate when milestone claims depend on it.

## If Simulator Is Broken

1. List devices.
2. Pick a healthy iOS 26 simulator.
3. Consider `xcrun simctl erase <UDID>` only when it is clearly simulator state.
4. Record exact simulator and issue in ledger.

## If AI Framework Is Unavailable

1. Keep game playable.
2. Use mocks/fallbacks.
3. Add capability status.
4. Document physical-device verification separately.
5. Do not block the whole feature.

## If Context Is Running Out

Immediately update `docs/FRONTIER_LEDGER.md`:

```text
What I changed:
What passed:
What failed:
What files are mid-edit:
Exact next command:
Next frontier:
```

Then continue if possible.

---

# Definition Of Done For One Loop

A loop is done only when:

- There is a concrete improvement in the working tree.
- Relevant build/test/proof has been run.
- Failures were fixed or documented with exact evidence.
- Behavior changes have tests where reasonable.
- UI changes have accessibility/privacy/localization considered.
- `docs/FRONTIER_LEDGER.md` records files, proof, remaining risk, and next frontier.
- The next target is harder than the one just completed.

Then start the next loop.

# Definition Of Done For The 12-Hour Mission

The mission is done only when one of these is true:

- The user stops you.
- Tooling/environment blocks further progress after serious repair attempts and the exact blocker is documented.
- Context is about to compact and the ledger contains a high-quality continuation packet.
- A major milestone has passed the best attainable full gate, release/continuation notes are updated, and there is no useful time/context left.

Even then, leave the repo better than you found it.

---

# Final Response Requirements

When reporting back to the user, be concise and evidence-backed:

- what changed
- what tests/builds ran
- what failed or could not be verified
- what still needs physical-device proof
- what the next frontier is

Do not claim App Store readiness, AI support, privacy perfection, accessibility perfection, performance targets, or release quality unless actually proved.

Now begin. Read the real repo, choose the first frontier, implement it, verify it, document it, and keep going. This should feel huge, hungry, and alive, but every step must touch reality.

## END PROMPT

---

## Human Note

This prompt is deliberately oversized. It is designed for long Codex goal-mode execution, not for a single quick edit. The important trick is that it combines a 10-year product fantasy with a strict loop that keeps forcing small, verifiable, repo-grounded improvements.
