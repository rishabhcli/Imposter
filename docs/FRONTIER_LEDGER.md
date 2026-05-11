# Frontier Ledger

## 2026-05-10 22:38 PDT - Hosted phase and voting invariants

### Baseline Issue Or Opportunity
- `plans_Imposter.md` calls for each loop to ship a concrete, verified improvement and record proof here.
- The current checkout allowed `clueRound -> voting` and `clueRound -> reveal`, and `completeVoting` could reveal results before every player voted.
- `ClueRoundView` used a "Slide to Vote" control that dispatched `completeVoting`, which could skip the hosted discussion phase entirely.
- Pre-existing worktree state included deleted historical planning docs plus untracked `.agents/` and `plans_Imposter.md`; this loop did not restore or revert those unrelated changes.

### Files Changed
- `Imposter/Domain/Models/GamePhase.swift`
- `Imposter/Domain/Logic/GameReducer.swift`
- `Imposter/Features/ClueRound/ClueRoundView.swift`
- `Imposter/Resources/Localizable.xcstrings`
- `ImposterTests/GamePhaseTests.swift`
- `ImposterTests/GameReducerTests.swift`
- `ImposterTests/GameFlowIntegrationTests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added reducer coverage that the final submitted clue enters `discussion`.
- Added reducer coverage that `completeClueRounds` enters `discussion`.
- Added reducer coverage that `startVoting` and `completeVoting` are ignored during `clueRound`.
- Added reducer coverage that self-votes are rejected.
- Added reducer coverage that `completeVoting` requires all players to vote.
- Updated phase and integration tests so the only normal flow is `setup -> roleReveal -> clueRound -> discussion -> voting -> reveal -> summary`.

### Verification Commands And Exact Outcome
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -list -project Imposter.xcodeproj`
  - Passed. Shared schemes: `Imposter-UnitTests`, `Imposter-UITests`.
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 26.233s.
  - Warning remained: `ImageService.swift:441` has `no 'async' operations occur within 'await' expression`.
- XcodeBuildMCP `build_sim` after updating `Localizable.xcstrings`
  - Passed in 9.511s.
  - Same `ImageService.swift:441` warning remained.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - MCP wrapper timed out, but the result bundle completed.
  - `xcresulttool get test-results summary` reported `result: Passed`, `passedTests: 160`, `failedTests: 0`, `skippedTests: 0`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -skip-testing:ImposterUITests/ImposterUITests/testLaunchPerformance -resultBundlePath /tmp/imposter-ui-tests.xcresult`
  - App UI tests passed: `testCompleteGameFlowBasic`, `testLaunchShowsHomeScreen`, and `testNewGameFlowReachesPlayerSetup`.
  - The later generated `ImposterUITestsLaunchTests` localized launch block hung and was killed to avoid leaving a stuck runner. Final interrupted error included `NSMachErrorDomain Code=-308 "(ipc/mig) server died"`.
- Focused app UI rerun after `simctl erase A113E399-3127-41CE-AB7E-B529DB41B3B6`
  - Stuck before producing a readable result bundle and was killed. Treat UI scheme stability as an open frontier, not green.
- `git diff --check`
  - Passed with no whitespace errors.

### Remaining Risk
- Full `Imposter-UITests` scheme stability is not green because the launch-test block can hang on this simulator after the app UI tests pass.
- The app UI tests still stop early at role reveal; they do not yet robot through clue, discussion, voting, reveal, summary, and second-round start.

### Next Frontier
- Build a deterministic end-to-end UI robot for the hosted flow and separate or repair the launch/screenshot tests so the UI gate is repeatable.
- Keep the green unit suite warning-clean as new test fixtures and AI service code evolve.

## 2026-05-10 22:42 PDT - Warning-clean build and unit suite

### Baseline Issue Or Opportunity
- The first loop left a green unit suite but with Swift warnings from `ImageService.swift` and `TestFixtures.swift`.
- A green test run is easier to trust when it is not padded with concurrency and unnecessary-await warnings.

### Files Changed
- `Imposter/Services/Implementations/ImageService.swift`
- `ImposterTests/Helpers/TestFixtures.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No behavioral tests were added; this loop only removed warning causes in implementation and test fixtures.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 4.143s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 45.821s.
  - Counts: `passed: 160`, `failed: 0`, `skipped: 0`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.

### Remaining Risk
- Full `Imposter-UITests` scheme remains unstable because of the launch-test hang documented in the previous entry.
- The warning cleanup did not expand UI coverage or physical-device AI verification.

### Score Snapshot
- Domain correctness: 4/5
- Gameplay completeness: 3/5
- Privacy: 2.5/5
- Accessibility: 2.5/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3/5
- Test depth: 3.5/5
- UI automation: 1.5/5
- Performance: 1.5/5
- Release readiness: 1.5/5
- Repo clarity: 3/5

### Next Frontier
- Repair/split the launch-test scheme and add a deterministic end-to-end UI robot for clue, discussion, voting, reveal, summary, and a second round.

## 2026-05-10 23:13 PDT - Deterministic hosted-flow UI robot

### Baseline Issue Or Opportunity
- The prior frontier left UI automation at role reveal and treated the full UI scheme as unstable because generated launch tests could hang.
- The app needed stable automation IDs that did not mask child controls in SwiftUI accessibility hierarchies.
- The role reveal hold control was a custom gesture surface that XCTest and accessibility activation could not reliably operate.

### Files Changed
- `Imposter/App/ImposterApp.swift`
- `Imposter/Utilities/AccessibilityIDs.swift`
- `Imposter/Features/Home/HomeView.swift`
- `Imposter/Features/RoleReveal/RoleRevealView.swift`
- `Imposter/Features/ClueRound/ClueRoundView.swift`
- `Imposter/Features/Discussion/DiscussionView.swift`
- `Imposter/Features/Voting/VotingView.swift`
- `Imposter/Features/Voting/PlayerSelectionGrid.swift`
- `Imposter/Features/Reveal/RevealView.swift`
- `Imposter/Features/Summary/SummaryView.swift`
- `ImposterUITests/ImposterUITests.swift`
- `ImposterUITests/ImposterUITestsLaunchTests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testHostedGameFlowReachesSummaryAndStartsSecondRound`.
- UI robot now configures a three-player game, reveals all roles, advances clue round to discussion, starts voting, casts all votes, reaches reveal, continues to summary, and starts a second round.
- Existing basic UI flow now waits for the role-reveal screen and reveal control with the same deterministic UI-testing launch path.
- Launch tests now run a single UI configuration with `-ui-testing` and wait for `homeTitle`.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 3.237s.
  - Diagnostics: `warnings: []`, `errors: []`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -only-testing:ImposterUITests/ImposterUITests/testHostedGameFlowReachesSummaryAndStartsSecondRound -resultBundlePath /tmp/imposter-ui-robot.xcresult -quiet`
  - Passed.
  - Xcode reported `78.659 elapsed -- Testing started completed`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -skip-testing:ImposterUITests/ImposterUITests/testLaunchPerformance -resultBundlePath /tmp/imposter-ui-full.xcresult -quiet`
  - Passed.
  - Xcode reported `122.847 elapsed -- Testing started completed`.
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 2.426s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 28.775s.
  - Counts: `passed: 160`, `failed: 0`, `skipped: 0`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.

### Remaining Risk
- `testLaunchPerformance` was intentionally skipped in the full UI gate; performance measurement stability still needs its own pass.
- UI testing uses `AppEnvironment.test()` for deterministic mock word/image/storage services, so live on-device FoundationModels and ImagePlayground behavior remains separate verification.
- The UI robot proves the hosted pass-and-play path on the iPhone 17 Pro simulator, not a physical device.

### Score Snapshot
- Domain correctness: 4/5
- Gameplay completeness: 3.5/5
- Privacy: 2.5/5
- Accessibility: 3/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3/5
- Test depth: 4/5
- UI automation: 3.5/5
- Performance: 1.5/5
- Release readiness: 2/5
- Repo clarity: 3.5/5

### Next Frontier
- Give `testLaunchPerformance` its own reliable measurement lane and add performance evidence for launch, role reveal, and summary navigation.
- Expand accessibility verification around pass-and-play privacy, especially VoiceOver handling of the secret word and reveal handoff screens.

## 2026-05-10 23:23 PDT - Pass-and-play privacy shield and handoff proof

### Baseline Issue Or Opportunity
- The hosted UI robot proved the happy path, but privacy proof still relied mostly on intent.
- Secret-word displays were visually private during role reveal, but not marked as system-sensitive content for snapshots.
- The app had no root privacy curtain for inactive/backgrounded in-game phases.
- Handoff screens did not have a targeted UI test proving the deterministic secret word stays absent between players.

### Files Changed
- `Imposter/ContentView.swift`
- `Imposter/Utilities/AccessibilityIDs.swift`
- `Imposter/Features/RoleReveal/RoleRevealView.swift`
- `Imposter/Features/RoleReveal/RoleCardView.swift`
- `Imposter/Features/Voting/VotingView.swift`
- `Imposter/Features/Reveal/RevealView.swift`
- `Imposter/Features/Summary/SummaryView.swift`
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testPassAndPlayHandoffsDoNotExposeSecretWord`.
- The new UI test starts a deterministic three-player game, verifies the role handoff before reveal, reveals one role, verifies the next role handoff, drives the game to voting, casts one vote, and verifies the vote handoff.
- The test asserts the deterministic mock word `Elephant` and `secretWordDisplay` are absent on handoff screens, and that vote choices disappear on the vote handoff.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 8.038s.
  - Diagnostics: `warnings: []`, `errors: []`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -only-testing:ImposterUITests/ImposterUITests/testPassAndPlayHandoffsDoNotExposeSecretWord -resultBundlePath /tmp/imposter-ui-privacy.xcresult -quiet`
  - Passed.
  - Xcode reported `61.657 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 1`, `failedTests: 0`, `result: Passed`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -skip-testing:ImposterUITests/ImposterUITests/testLaunchPerformance -resultBundlePath /tmp/imposter-ui-full.xcresult -quiet`
  - Passed.
  - Xcode reported `163.605 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 6`, `failedTests: 0`, `result: Passed`.
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 1.879s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 37.745s.
  - Counts: `passed: 160`, `failed: 0`, `skipped: 0`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.

### Remaining Risk
- The inactive/background privacy curtain compiles and is wired to `scenePhase`, but this loop did not capture an app-switcher screenshot proving the system snapshot is shielded.
- `.privacySensitive()` coverage now marks secret-word surfaces, but VoiceOver behavior still needs a dedicated accessibility run or simulator assistive-tech proof.
- `testLaunchPerformance` remains outside the full UI gate and needs its own stable performance lane.

### Score Snapshot
- Domain correctness: 4/5
- Gameplay completeness: 3.5/5
- Privacy: 3/5
- Accessibility: 3.25/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3/5
- Test depth: 4/5
- UI automation: 3.75/5
- Performance: 1.5/5
- Release readiness: 2/5
- Repo clarity: 3.5/5

### Next Frontier
- Prove the privacy curtain with an inactive/background simulator snapshot path or document the exact simulator limitation.
- Build a stable performance lane for `testLaunchPerformance`, then collect launch and hosted-flow timing evidence.

## 2026-05-10 23:30 PDT - Stable launch-performance lane

### Baseline Issue Or Opportunity
- The full UI gate had been skipping `testLaunchPerformance` because the measurement lane was not yet proven stable.
- The performance test launched a fresh `XCUIApplication` without the deterministic `-ui-testing` argument used by the rest of the UI harness.
- The product target is launch under 2 seconds, but the ledger did not yet include extracted launch metric evidence from the current test run.

### Files Changed
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Updated `testLaunchPerformance` to terminate the setup-launched app and measure launches with `-ui-testing`.
- The full UI scheme now runs all UI tests, including launch performance, without `-skip-testing`.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 3.244s.
  - Diagnostics: `warnings: []`, `errors: []`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -only-testing:ImposterUITests/ImposterUITests/testLaunchPerformance -resultBundlePath /tmp/imposter-ui-launchperf.xcresult -quiet`
  - Passed.
  - Xcode reported `53.514 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 1`, `failedTests: 0`, `result: Passed`.
  - Exported metric CSV reported average launch duration `1.340086183 s` with iterations `[1.333624042, 1.452733333, 1.3250350830000002, 1.3061791660000002, 1.282859291]`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-ui-full-with-perf.xcresult -quiet`
  - Passed without skipped tests.
  - Xcode reported `225.221 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 7`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`.
  - Exported metric CSV reported average launch duration `1.263459084 s` with iterations `[1.239712125, 1.2194286250000002, 1.2464105, 1.303167709, 1.3085764590000002]`.
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 2.292s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 29.131s.
  - Counts: `passed: 160`, `failed: 0`, `skipped: 0`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.

### Remaining Risk
- Launch performance is now measured on simulator with deterministic test services, not on a physical device.
- Hosted-flow runtime performance, memory growth across many rounds, and app-switcher privacy screenshots are still unmeasured.
- Xcode still emits `IDELaunchParametersSnapshot` debugger-version noise during UI tests, but the runs complete and result bundles are green.

### Score Snapshot
- Domain correctness: 4/5
- Gameplay completeness: 3.5/5
- Privacy: 3/5
- Accessibility: 3.25/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3/5
- Test depth: 4/5
- UI automation: 4/5
- Performance: 2.25/5
- Release readiness: 2.25/5
- Repo clarity: 3.5/5

### Next Frontier
- Add a repeatable hosted-flow performance or stability lab: several rounds in a row with timing/log evidence and memory-risk notes.
- Prove the inactive/background privacy curtain with a simulator snapshot or document exactly why the toolchain cannot capture it.

## 2026-05-10 23:46 PDT - Privacy curtain screenshot harness

### Baseline Issue Or Opportunity
- The app had a `scenePhase` privacy curtain, but there was no repeatable screenshot artifact proving the curtain UI itself.
- Simulator `simctl io screenshot` can capture the visible display, but the available toolchain does not expose an app-switcher snapshot of a backgrounded app.
- A first forced-shield UI assertion showed the curtain existed and secret text was absent, but XCTest could still enumerate an underlying non-secret reveal control; the proof needed to be scoped to what the simulator can actually validate.

### Files Changed
- `Imposter/ContentView.swift`
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testForcedPrivacyShieldCoversInGameState`.
- Added `-ui-testing-force-privacy-shield` as a UI-only launch argument that forces the curtain after setup starts a private game.
- The new test verifies the curtain appears, attaches a simulator screenshot, and asserts the deterministic secret word and `secretWordDisplay` are absent while the curtain is shown.
- The phase content is now wrapped in a concrete `ZStack` with `.accessibilityHidden(shouldShowPrivacyShield)` rather than a transparent `Group`.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 2.794s.
  - Diagnostics: `warnings: []`, `errors: []`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -only-testing:ImposterUITests/ImposterUITests/testForcedPrivacyShieldCoversInGameState -resultBundlePath /tmp/imposter-ui-forced-shield.xcresult -quiet`
  - Passed.
  - Xcode reported `42.162 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 1`, `failedTests: 0`, `result: Passed`.
  - Exported screenshot attachment: `/tmp/imposter-forced-shield-attachments/1E3A9DF7-C17D-4AA3-B55A-9298651D96FF.png`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-ui-full-with-perf.xcresult -quiet`
  - Passed without skipped tests.
  - Xcode reported `206.588 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 8`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`.
  - Exported launch metric CSV reported average launch duration `1.232450792 s` with iterations `[1.2412507080000001, 1.232087458, 1.2243620000000002, 1.228302459, 1.236251333]`.
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 3.837s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4`
  - Passed in 105.482s.
  - Counts: `passed: 160`, `failed: 0`, `skipped: 0`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.

### Remaining Risk
- This loop proves the curtain rendering through a deterministic UI-test force flag, not a real iOS app-switcher background snapshot.
- XCTest still enumerated an underlying non-secret reveal control in the first forced-shield attempt, so VoiceOver/app-switcher privacy should get physical-device or lower-level accessibility verification before claiming perfection.
- Multi-round memory growth and hosted-flow runtime performance are still unmeasured.

### Score Snapshot
- Domain correctness: 4/5
- Gameplay completeness: 3.5/5
- Privacy: 3.25/5
- Accessibility: 3.25/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3/5
- Test depth: 4.1/5
- UI automation: 4.1/5
- Performance: 2.25/5
- Release readiness: 2.25/5
- Repo clarity: 3.5/5

### Next Frontier
- Add a repeatable multi-round stability lab that exercises several full games in one test or domain simulation and records memory/performance risk notes.
- Add a VoiceOver-focused privacy pass for role cards and the privacy curtain, ideally with a physical-device caveat kept separate from simulator proof.

## 2026-05-11 00:00 PDT - Maximum-player tournament stability lab

### Baseline Issue Or Opportunity
- The app had single-round and two-round reducer coverage, plus a slow UI robot, but no fast repeatable lab for many consecutive full rounds.
- Multi-round risk was still mostly implicit: score accumulation, archived history, vote/clue cleanup, active `roundState` lifetime, and repeated `summary -> roleReveal` transitions could regress without a focused test.
- While building the lab, `completeRound(imposterGuessedCorrectly:)` was found to apply the imposter guess to scoring but not to the archived `CompletedRound.imposterGuessedWord`.

### Files Changed
- `Imposter/Domain/Logic/GameReducer.swift`
- `ImposterTests/TournamentSimulationTests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `TournamentSimulationTests.testMaximumPlayerTournamentMaintainsInvariantsAcrossManyRounds`.
- The new unit lab simulates 100 deterministic rounds with the maximum 10-player table.
- Each round uses a prepared round so the imposter rotates through every player without depending on random word/imposter selection.
- The test drives the real reducer path: `setup/summary -> roleReveal -> clueRound -> discussion -> voting -> reveal -> summary`.
- Per-round invariants verify role reveal index progression, current clue giver rotation, 2 clue rounds per player, no premature voting completion, self-vote rejection, all valid votes before reveal, nonnegative and increasing scores, no active `roundState` after summary, bounded history growth, archived clue/vote counts, and archived imposter-guess coherence.
- Fixed `GameReducer.completeRound` so `CompletedRound.imposterGuessedWord` records the reducer action's `imposterGuessedCorrectly` value.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - Passed in 10.045s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP `test_sim` with `scheme=Imposter-UnitTests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`, `-only-testing:ImposterTests/TournamentSimulationTests/testMaximumPlayerTournamentMaintainsInvariantsAcrossManyRounds`
  - Passed in 53.614s wall time.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
  - Test case body duration: `69ms`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.
- XcodeBuildMCP full `test_sim` with `scheme=Imposter-UnitTests`
  - MCP wrapper timed out after 120s.
  - The launched `xcodebuild` process was still alive after 4m33s and had only logged the result bundle path, so it was terminated as a stranded wrapper run.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UnitTests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-unit-full-tournament.xcresult -quiet`
  - Passed.
  - Xcode reported `60.417 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 161`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 161`.
  - `TournamentSimulationTests.testMaximumPlayerTournamentMaintainsInvariantsAcrossManyRounds` body duration in the full run: `0.048 seconds`.

### Remaining Risk
- The stability lab exercises domain/reducer behavior, not rendered SwiftUI memory growth during repeated hosted play.
- The full UI scheme was not rerun in this loop because only reducer logic and unit tests changed; the prior UI gate remains the latest rendered-flow proof.
- VoiceOver privacy for secret role cards and the privacy curtain still needs a dedicated accessibility pass.
- Real app-switcher snapshot behavior and FoundationModels/ImagePlayground behavior remain simulator-limited or physical-device verification items.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.75/5
- Privacy: 3.25/5
- Accessibility: 3.25/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.25/5
- UI automation: 4.1/5
- Performance: 2.5/5
- Release readiness: 2.35/5
- Repo clarity: 3.75/5

### Next Frontier
- Add a VoiceOver-focused privacy pass for role cards, secret-word text, and the forced privacy curtain, keeping simulator accessibility proof separate from physical-device/app-switcher claims.
- Add a rendered hosted-flow runtime pass that records timing and memory behavior across repeated UI rounds, or document the exact simulator/tooling limitation if it cannot be captured repeatably.

## 2026-05-11 00:25 PDT - VoiceOver privacy tree hardening

### Baseline Issue Or Opportunity
- The previous privacy pass proved handoff screens and the forced curtain, but role cards still relied on `.privacySensitive()` and parent labels.
- A focused UI test initially caught raw role text (`IMPOSTER`) and then raw secret text (`Elephant`) in XCTest's accessibility export while the visual role card was shown.
- The forced privacy shield also exposed multiple `privacyShield` matches because SwiftUI propagated the identifier to child image/text nodes.

### Files Changed
- `Imposter/ContentView.swift`
- `Imposter/Features/RoleReveal/RoleCardView.swift`
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testRoleCardsHideSensitiveTextFromAccessibilityTree`.
- The new UI test reveals all three deterministic role cards and asserts the exposed role-card element uses only a sanitized privacy label.
- The same test rejects raw sensitive accessibility labels for `Elephant`, `THE SECRET WORD`, `INFORMED`, `IMPOSTER`, `HINT`, and `Animals`, and asserts the role-card secret-word identifier is not exposed.
- Updated `testForcedPrivacyShieldCoversInGameState` to assert the single sanitized shield label instead of relying on visible shield text as an accessibility proxy.

### Implementation Notes
- `RoleCardView` now hides the visual role-card subtree from accessibility and overlays a frame-matched clear element with `AccessibilityIDs.roleCard`.
- Sensitive visual role labels, secret words, and imposter hints now carry non-secret accessibility labels as a defensive fallback if SwiftUI exports a child element anyway.
- Role-card secret word text no longer uses `AccessibilityIDs.secretWordDisplay`; that identifier remains for non-private reveal surfaces.
- `PrivacyShieldView` now follows the same split: visual shield content is hidden from accessibility, while a single clear element carries the privacy shield identifier, label, hint, sort priority, and accessibility focus.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - Passed in 8.127s before the first focused test.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP focused `test_sim` for `testRoleCardsHideSensitiveTextFromAccessibilityTree`
  - First run failed as intended with `Sensitive role text 'IMPOSTER' appeared in the accessibility tree`.
  - Second run failed with `Sensitive role text 'Elephant' appeared in the accessibility tree` after the parent-only hiding attempt.
  - Final run passed in 71.825s after direct sensitive-text fallback labels and removing the role-card word identifier.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
- XcodeBuildMCP focused `test_sim` for `testForcedPrivacyShieldCoversInGameState`
  - First rerun failed because multiple descendants matched `privacyShield`.
  - Final run passed in 101.986s after the shield was split into hidden visual content plus a single clear accessibility element.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-ui-full-voiceover-privacy.xcresult -quiet`
  - Passed.
  - Xcode reported `257.043 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 9`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 9`.
  - Full UI case durations included `testRoleCardsHideSensitiveTextFromAccessibilityTree()` at `38.226986s`, `testForcedPrivacyShieldCoversInGameState()` at `21.579885s`, and `testHostedGameFlowReachesSummaryAndStartsSecondRound()` at `62.627378s`.
  - Exported launch metric CSV reported average launch duration `1.271573583 s` with iterations `[1.4117365830000002, 1.246998583, 1.232403708, 1.232429333, 1.234299708]`.

### Remaining Risk
- This is simulator UI-accessibility proof, not a physical-device VoiceOver audio recording.
- The role card intentionally keeps the word visible on screen for sighted pass-and-play; the proof is that raw sensitive strings are no longer exported as spoken accessibility labels in the UI harness.
- Summary and reveal surfaces still intentionally expose the final word after the group reveal; this loop only hardened private role-card and curtain states.
- Real app-switcher snapshot behavior remains a physical-device or lower-level simulator limitation.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.75/5
- Privacy: 3.6/5
- Accessibility: 3.6/5
- Localization: 2/5
- Liquid Glass fit: 3/5
- Animation/haptics: 3/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.35/5
- UI automation: 4.25/5
- Performance: 2.55/5
- Release readiness: 2.45/5
- Repo clarity: 3.8/5

### Next Frontier
- Add a rendered hosted-flow runtime pass that records timing and memory behavior across repeated UI rounds, keeping simulator measurements separate from physical-device claims.
- Add reduce-motion/reduce-transparency accessibility proof for the private handoff, role card, and privacy curtain surfaces.

## 2026-05-11 00:42 PDT - Reduced motion and transparency private-surface proof

### Baseline Issue Or Opportunity
- The prior loop hardened VoiceOver privacy, but there was no proof that private handoff, role-card, or curtain surfaces stayed usable under Reduce Motion and Reduce Transparency.
- `AnimatedBackground`, role reveal transitions, pulsing continue hints, and hold-to-reveal surfaces assumed animation/glass by default.
- SwiftUI's built-in `accessibilityReduceMotion` and `accessibilityReduceTransparency` environment values are read-only in this SDK, so UI tests needed an app-owned preference layer instead of direct test-time writes.

### Files Changed
- `Imposter/App/ImposterApp.swift`
- `Imposter/ContentView.swift`
- `Imposter/DesignSystem/LiquidGlass/LGComponents/AnimatedBackground.swift`
- `Imposter/Features/RoleReveal/RoleCardView.swift`
- `Imposter/Features/RoleReveal/RoleRevealView.swift`
- `Imposter/Features/Voting/VotingView.swift`
- `Imposter/Utilities/AccessibilityIDs.swift`
- `Imposter/Utilities/AccessibilityPreferences.swift`
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testReducedMotionAndTransparencyKeepPrivateSurfacesUsable`.
- The new UI test launches with `-ui-testing-reduce-motion` and `-ui-testing-reduce-transparency`, verifies the app-owned accessibility preference marker, starts a game, proves the role handoff does not expose the deterministic secret, reveals a private role card, reuses the sanitized role-card accessibility assertions, advances to the next handoff, and confirms the secret remains hidden.
- The same test relaunches with the reduced settings plus `-ui-testing-force-privacy-shield`, then verifies the forced curtain still exposes a single sanitized shield label and no secret.

### Implementation Notes
- Added `AccessibilityPreferences` as an app-owned environment value layered on top of the real system Reduce Motion / Reduce Transparency values.
- `ImposterApp` sets that environment only from UI-test launch flags; production still reads the real system accessibility values.
- `AnimatedBackground` now stops ambient animation when motion is reduced and removes mesh/particle/noise/transparency layers when transparency is reduced.
- `RoleRevealView`, `RoleRevealProgressBar`, `HoldToRevealButton`, and `PulsingOpacityModifier` now suppress spring/pulse/repeating animation when effective Reduce Motion is on.
- `RoleRevealView`, `RoleCardView`, `HoldToRevealButton`, and error toast glass surfaces now use solid fills when effective Reduce Transparency is on.
- Added a test-only `accessibilityPreferencesStatus` marker so UI tests prove the forced accessibility environment was actually active before relying on the private-surface assertions.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - First build failed because direct `.environment(\.accessibilityReduceMotion, true)` and `.environment(\.accessibilityReduceTransparency, true)` writes are rejected as read-only key paths.
  - Final build passed in 10.080s after switching to the app-owned `AccessibilityPreferences` environment.
  - Diagnostics on final build: `warnings: []`, `errors: []`.
- XcodeBuildMCP focused `test_sim` for `testReducedMotionAndTransparencyKeepPrivateSurfacesUsable`
  - Passed in 82.521s.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
  - Diagnostics: `warnings: []`, `errors: []`, `testFailures: []`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-ui-full-reduced-accessibility.xcresult -quiet`
  - Passed.
  - Xcode reported `351.713 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 10`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 10`.
  - Full UI case durations included `testReducedMotionAndTransparencyKeepPrivateSurfacesUsable()` at `52.018242s`, `testRoleCardsHideSensitiveTextFromAccessibilityTree()` at `53.606246s`, `testForcedPrivacyShieldCoversInGameState()` at `22.916776s`, and `testHostedGameFlowReachesSummaryAndStartsSecondRound()` at `62.731792s`.
  - Exported launch metric CSV reported average launch duration `1.375303475 s` with iterations `[1.36643675, 1.350173542, 1.3468138330000001, 1.448052542, 1.365040708]`.

### Remaining Risk
- This proves reduced accessibility settings through deterministic app-owned UI-test flags layered over system values, not through changing the simulator's Settings app or recording physical-device assistive-tech behavior.
- The reduced-transparency proof is scoped to private handoff, role card, curtain, background, and immediate glass controls touched by the test; the whole app still needs a broader visual audit.
- Unit tests were not rerun in this loop because only SwiftUI/app accessibility behavior and UI automation changed; the UI scheme compiled the app target and exercised the affected surfaces.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.75/5
- Privacy: 3.65/5
- Accessibility: 3.85/5
- Localization: 2/5
- Liquid Glass fit: 3.1/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.4/5
- UI automation: 4.35/5
- Performance: 2.6/5
- Release readiness: 2.55/5
- Repo clarity: 3.85/5

### Next Frontier
- Add a rendered hosted-flow runtime pass that records timing and memory behavior across repeated UI rounds, keeping simulator measurements separate from physical-device claims.
- Add a broader reduced-transparency visual audit across setup, voting, reveal, and summary surfaces so the fallback is not limited to private pass-and-play screens.

## 2026-05-11 01:00 PDT - Rendered hosted-flow runtime pass

### Baseline Issue Or Opportunity
- The hosted flow had deterministic UI coverage and the domain had a 100-round tournament simulation, but no rendered multi-round runtime lab that exercised repeated rounds through SwiftUI, animation, scrolling, and XCUITest hit-testing.
- Launch performance was measured, but the longer hosted round loop still relied on single-flow UI proof rather than per-round timing evidence.
- The previous frontier also named memory behavior; this loop adds rendered wall-clock proof while leaving lower-level process memory sampling as a separate, still-open performance frontier.

### Files Changed
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds`.
- Extracted `playCurrentRoundToSummary(playerCount:)` so the original hosted-flow test and the new runtime lab share the same rendered game robot.
- The new runtime lab starts a hosted 3-player game, plays two full rendered rounds through role reveal, clue round, discussion, voting, reveal, and summary, records per-round durations, attaches the timing summary to the result bundle, and asserts each round and the full loop stay below simulator responsiveness ceilings.

### Implementation Notes
- `testHostedGameFlowReachesSummaryAndStartsSecondRound()` now uses the shared `playCurrentRoundToSummary(playerCount:)` helper, keeping the existing behavioral coverage while reducing duplicated robot steps.
- The runtime lab stores round durations with `Date`, keeps an always-retained `XCTAttachment`, and records the simulator device name in the artifact.
- This is intentionally an XCUITest-level runtime proof. It detects rendered-flow stalls and regressions visible to the UI harness, but it does not claim heap, RSS, ETTrace, or Instruments memory coverage.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - Passed in 5.839s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP focused `test_sim` for `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds`
  - The MCP wrapper timed out after 120s, but the underlying `xcodebuild` continued and produced a passed result bundle at `/Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/result-bundles/test_sim_2026-05-11T07-44-59-735Z_pid15951_321842fb.xcresult`.
  - `xcresulttool` summary reported `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 1`.
  - `xcresulttool` test details reported `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` duration `113.910183s`.
  - Xcode reported `150.927 elapsed -- Testing started completed`.
  - Exported attachment reported: `Rounds: 2`, `Round durations: 42.380, 46.324 seconds`, `Total duration: 93.118 seconds`, `Device: iPhone 17 Pro`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-ui-full-rendered-runtime.xcresult -quiet`
  - Passed.
  - Xcode reported `454.300 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 11`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 11`.
  - Full UI case durations included `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` at `119.398324s`, `testHostedGameFlowReachesSummaryAndStartsSecondRound()` at `68.378153s`, `testReducedMotionAndTransparencyKeepPrivateSurfacesUsable()` at `54.550049s`, `testRoleCardsHideSensitiveTextFromAccessibilityTree()` at `42.763825s`, and `testForcedPrivacyShieldCoversInGameState()` at `21.830842s`.
  - Exported launch metric CSV reported average launch duration `1.298075608 s` with iterations `[1.296862458, 1.3327896670000001, 1.3021096250000002, 1.2803630000000001, 1.2782532910000002]`.
  - Exported runtime attachment reported: `Rounds: 2`, `Round durations: 41.611, 49.922 seconds`, `Total duration: 96.200 seconds`, `Device: iPhone 17 Pro`.

### Remaining Risk
- This proves a repeated rendered hosted flow on the iOS simulator, not physical-device thermal, frame pacing, or memory behavior.
- Memory process sampling is still not captured by XCTest. A future lower-level ETTrace, Instruments, memgraph, or RSS sampler should cover the memory target directly.
- The lab currently uses the deterministic minimum hosted player count. Maximum-player rendered runtime remains a separate UI stress path even though the domain reducer has a 10-player tournament simulation.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.8/5
- Privacy: 3.65/5
- Accessibility: 3.85/5
- Localization: 2/5
- Liquid Glass fit: 3.1/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.5/5
- UI automation: 4.45/5
- Performance: 2.8/5
- Release readiness: 2.65/5
- Repo clarity: 3.9/5

### Next Frontier
- Add lower-level runtime memory evidence for repeated rounds, using an ETTrace/Instruments/RSS sampler or memgraph workflow instead of relying on XCUITest timing attachments alone.
- Add a maximum-player rendered hosted UI stress pass so the 10-player domain tournament proof also has rendered SwiftUI coverage.
- Add a broader reduced-transparency visual audit across setup, voting, reveal, and summary surfaces so the fallback is not limited to private pass-and-play screens.

## 2026-05-11 01:28 PDT - Maximum-player rendered UI stress pass

### Baseline Issue Or Opportunity
- The domain layer had a 10-player tournament simulation, but the rendered UI lab still covered only the deterministic 3-player hosted flow.
- Setup automation inferred player count from start-button state and taps, which was enough for minimum-player tests but too weak for a max-player rendered stress path.
- Voting and pass-and-play privacy had focused UI coverage, but there was no full SwiftUI/XCUITest proof that 10 players can be added through setup and played through a rendered round to summary.

### Files Changed
- `Imposter/Features/Home/HomeView.swift`
- `Imposter/Utilities/AccessibilityIDs.swift`
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testMaximumPlayerRenderedFlowCompletesRound`.
- Added a stable `setupSubtitle` accessibility identifier so UI tests can verify the actual setup subtitle/player count.
- Reworked `addMinimumPlayersIfNeeded()` to use `addPlayersIfNeeded(targetCount:)`, with player-count parsing, count waits, scroll-aware add-player tapping, and keyboard dismissal for long setup lists.
- The new max-player test adds 10 players through the rendered setup UI, starts a game, plays one full rendered round through role reveal, clue round, discussion, voting, reveal, and summary, then retains a timing attachment.

### Implementation Notes
- `HomeView` now exposes the compact subtitle through `AccessibilityIDs.setupSubtitle`; during player setup its label is the live player count, such as `10 Players`.
- The UI robot no longer treats an enabled Start button as enough evidence for setup size. It waits for each player count before proceeding.
- The max-player lab uses the shared `playCurrentRoundToSummary(playerCount:)` helper, so it exercises the same rendered phase path as the hosted-flow tests at the upper player limit.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - Passed in 15.143s.
  - Diagnostics: `warnings: []`, `errors: []`.
- XcodeBuildMCP focused `test_sim` for `testMaximumPlayerRenderedFlowCompletesRound`
  - The MCP wrapper timed out after 120s, but the underlying `xcodebuild` continued and produced a passed result bundle at `/Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/result-bundles/test_sim_2026-05-11T08-05-40-538Z_pid15951_d695cf20.xcresult`.
  - `xcresulttool` summary reported `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 1`.
  - `xcresulttool` test details reported `testMaximumPlayerRenderedFlowCompletesRound()` duration `198.542959s`.
  - Exported attachment reported: `Players: 10`, `Round duration: 116.794 seconds`, `Device: iPhone 17 Pro`.
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -resultBundlePath /tmp/imposter-ui-full-max-player.xcresult -quiet`
  - Passed.
  - Xcode reported `805.788 elapsed -- Testing started completed`.
  - `xcresulttool` summary reported `passedTests: 12`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 12`.
  - Full UI case durations included `testMaximumPlayerRenderedFlowCompletesRound()` at `189.044832s`, `testHostedGameFlowReachesSummaryAndStartsSecondRound()` at `130.995740s`, `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` at `120.361439s`, `testReducedMotionAndTransparencyKeepPrivateSurfacesUsable()` at `71.594432s`, and `testRoleCardsHideSensitiveTextFromAccessibilityTree()` at `50.511472s`.
  - Exported max-player attachment reported: `Players: 10`, `Round duration: 118.491 seconds`, `Device: iPhone 17 Pro`.
  - Exported two-round runtime attachment still reported: `Rounds: 2`, `Round durations: 45.196, 42.187 seconds`, `Total duration: 92.333 seconds`, `Device: iPhone 17 Pro`.
  - Full-suite launch metric CSV reported average launch duration `2.313739409 s` with iterations `[1.9234610840000002, 1.3759530830000002, 5.583501625, 1.374493959, 1.311287292]`.
- XcodeBuildMCP focused `test_sim` for `testLaunchPerformance`
  - The MCP wrapper timed out after 120s, but the underlying `xcodebuild` continued and produced a passed result bundle at `/Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/result-bundles/test_sim_2026-05-11T08-25-09-882Z_pid15951_8e321ad0.xcresult`.
  - `xcresulttool` summary reported `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 1`.
  - `xcresulttool` test details reported `testLaunchPerformance()` duration `36.794270s`.
  - Exported focused launch metric CSV reported average launch duration `1.474835316 s` with iterations `[1.461628334, 1.7755648750000002, 1.442802041, 1.3513336660000002, 1.3428476660000002]`.

### Remaining Risk
- The full-suite launch metric exceeded the 2s target because one post-stress iteration took `5.583501625s`; the focused launch rerun returned to `1.474835316s`, so this is likely simulator-load noise but still deserves follow-up.
- This max-player proof covers one rendered 10-player round, not repeated max-player rounds or physical-device party usage.
- The test captures wall-clock flow completion, not frame pacing, memory growth, or thermal behavior.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.9/5
- Privacy: 3.7/5
- Accessibility: 3.9/5
- Localization: 2/5
- Liquid Glass fit: 3.1/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.6/5
- UI automation: 4.6/5
- Performance: 2.85/5
- Release readiness: 2.7/5
- Repo clarity: 3.95/5

### Next Frontier
- Add lower-level runtime memory evidence for repeated rounds, using an ETTrace/Instruments/RSS sampler or memgraph workflow instead of relying on XCUITest timing attachments alone.
- Investigate the full-suite launch metric outlier and decide whether the launch test needs simulator preconditioning, stricter assertions, or a separate stable performance lane.
- Add a broader reduced-transparency visual audit across setup, voting, reveal, and summary surfaces so the fallback is not limited to private pass-and-play screens.

## 2026-05-11 01:39 PDT - Isolated launch-performance lane

### Baseline Issue Or Opportunity
- The full UI suite previously passed but reported a launch metric average of `2.313739409s` because one post-stress iteration took `5.583501625s`.
- The focused launch rerun returned to `1.474835316s`, suggesting simulator load noise, but the launch test itself still prelaunched the app in `setUpWithError()` before terminating and measuring launches.
- The launch lane had no retained in-test readiness evidence, so exported `XCTApplicationLaunchMetric` CSVs were the only timing artifact.

### Files Changed
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Updated `testLaunchPerformance()` so performance tests skip the normal app prelaunch in `setUpWithError()`.
- Added an explicit `XCTMeasureOptions` iteration count of 5 for the launch metric.
- Added a retained `Launch performance UI-readiness envelope` attachment with per-iteration XCUITest readiness durations, average, median, max, and readiness outlier count.
- Added readiness assertions that keep the home-screen UI responsive without confusing XCUITest element-readiness time with the Xcode `XCTApplicationLaunchMetric` app-launch duration.
- Added a shared `launchApp(arguments:)` helper and kept normal tests launching through setup.

### Implementation Notes
- `shouldLaunchAppInSetUp` skips setup launch only when the XCTest name contains `testLaunchPerformance`; all regular UI tests still launch the app in setup.
- The first hardened assertion intentionally failed because the manual wall-clock envelope measured about `4.58s` median while the exported Xcode AppLaunch metric was `1.311469866s`. This proved the manual envelope includes XCUITest home-screen readiness overhead, not pure app launch.
- The final assertions use the manual envelope only as a UI-readiness guard. The Xcode metric CSV remains the launch-duration source of truth.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - First build after the patch passed in 18.973s.
  - Final build after assertion calibration passed in 4.264s.
  - Diagnostics on both builds: `warnings: []`, `errors: []`.
- XcodeBuildMCP focused `test_sim` for `testLaunchPerformance` with the initial too-strict wall-clock assertion
  - Failed as intended in 70.625s.
  - Failure: `XCTAssertLessThan failed: ("4.581896291667363") is not less than ("2.5")`.
  - Exported AppLaunch metric CSV still reported average launch duration `1.311469866 s` with iterations `[1.3278694160000002, 1.3492898750000002, 1.34869725, 1.271260958, 1.260231833]`.
  - Exported readiness attachment reported `Iterations: 6`, durations `4.493, 4.658, 4.667, 4.582, 4.510, 4.571 seconds`, average `4.580s`, median `4.582s`, max `4.667s`, and `Launches over 4s: 6`.
- XcodeBuildMCP focused `test_sim` for final `testLaunchPerformance`
  - Passed in 67.838s.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
  - `xcresulttool` test details reported `testLaunchPerformance()` duration `33.344737s`.
  - Exported AppLaunch metric CSV reported average launch duration `1.37679995 s` with iterations `[1.3561651250000002, 1.351466666, 1.328388458, 1.421048208, 1.426931291]`.
  - Exported readiness attachment reported `Iterations: 6`, durations `4.401, 4.676, 4.676, 4.665, 4.809, 4.792 seconds`, average `4.670s`, median `4.676s`, max `4.809s`, and `UI-readiness launches over 8s: 0`.
- XcodeBuildMCP focused `test_sim` for `testLaunchShowsHomeScreen`
  - Passed in 74.081s.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
  - Test duration: `8.062s`.

### Remaining Risk
- The AppLaunch metric still requires exported CSV parsing outside the test to read the exact average; XCTest's metric API records the launch duration but does not expose the metric values directly to assertions here.
- The UI-readiness envelope is intentionally looser and measures XCUITest observability of the home screen, not pure app launch.
- The full UI suite was not rerun in this loop because the change is scoped to launch setup and the targeted home-screen test proved normal setup still launches; the prior full suite remains the latest complete 12-test UI sweep.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.9/5
- Privacy: 3.7/5
- Accessibility: 3.9/5
- Localization: 2/5
- Liquid Glass fit: 3.1/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.6/5
- UI automation: 4.6/5
- Performance: 3.0/5
- Release readiness: 2.75/5
- Repo clarity: 3.95/5

### Next Frontier
- Add lower-level runtime memory evidence for repeated rounds, using an ETTrace/Instruments/RSS sampler or memgraph workflow instead of relying on XCUITest timing attachments alone.
- Add a broader reduced-transparency visual audit across setup, voting, reveal, and summary surfaces so the fallback is not limited to private pass-and-play screens.
- Consider a small post-processing script for `xcresulttool` launch CSVs so the launch-duration threshold can be enforced outside XCTest when exact metric values are available.

## 2026-05-11 01:42 PDT - Launch metric xcresult gate

### Baseline Issue Or Opportunity
- The isolated launch-performance lane produced trustworthy `XCTApplicationLaunchMetric` CSVs, but the exact metric values still had to be read manually after export.
- XCTest did not expose the launch metric average directly to the test assertion, so launch-duration enforcement needed a post-processing gate that reads the `.xcresult`.
- The prior loop explicitly named this as a remaining risk and next frontier.

### Files Changed
- `scripts/check_launch_metric.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added an executable stdlib Python verifier for `XCTApplicationLaunchMetric` rows exported from an `.xcresult`.
- The verifier exports metrics with `xcrun xcresulttool export metrics`, parses AppLaunch average and per-iteration CSV values, prints the measured envelope, and exits nonzero if the average or optional max iteration exceeds configured thresholds.
- Verified both pass and fail behavior against the latest focused launch-performance result bundle.

### Implementation Notes
- The script intentionally gates the Xcode AppLaunch CSV, not the looser XCUITest UI-readiness attachment.
- It returns exit code `2` when no launch metric rows are found, keeping "missing evidence" distinct from "metric exceeded threshold."
- Thresholds are command-line arguments so local strict gates and future CI gates can use different ceilings without code edits.

### Verification Commands And Exact Outcome
- `scripts/check_launch_metric.py --xcresult /Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/result-bundles/test_sim_2026-05-11T08-35-36-834Z_pid15951_f191899b.xcresult --max-average 2.0 --max-iteration 2.5`
  - Passed with exit code `0`.
  - Output: `average=1.377s`, `max_iteration=1.427s`, `iterations=[1.356, 1.351, 1.328, 1.421, 1.427]`.
- `if scripts/check_launch_metric.py --xcresult /Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/result-bundles/test_sim_2026-05-11T08-35-36-834Z_pid15951_f191899b.xcresult --max-average 1.0; then echo 'unexpected pass'; exit 1; else exit_code=$?; echo "expected failure exit=$exit_code"; test "$exit_code" -eq 1; fi`
  - Passed the harness check by failing the verifier with exit code `1`.
  - Output included `FAIL: average 1.377s exceeded 1.000s` and `expected failure exit=1`.
- `python3 -m py_compile scripts/check_launch_metric.py`
  - Passed.
- `scripts/check_launch_metric.py --help`
  - Passed and documented `--xcresult`, `--max-average`, and `--max-iteration`.

### Remaining Risk
- The gate is not wired into GitHub Actions yet. That is deliberate for now because launch metrics can be runner-sensitive; CI thresholds should be chosen separately if this becomes a required check.
- The script gates launch-duration CSV rows only. It does not inspect UI-readiness attachments, memory growth, frame pacing, or thermal behavior.
- It depends on `xcrun xcresulttool export metrics`, so it remains an Apple-toolchain verifier rather than a pure offline parser.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.9/5
- Privacy: 3.7/5
- Accessibility: 3.9/5
- Localization: 2/5
- Liquid Glass fit: 3.1/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.65/5
- UI automation: 4.6/5
- Performance: 3.1/5
- Release readiness: 2.8/5
- Repo clarity: 4.0/5

### Next Frontier
- Add lower-level runtime memory evidence for repeated rounds, using an ETTrace/Instruments/RSS sampler or memgraph workflow instead of relying on XCUITest timing attachments alone.
- Add a broader reduced-transparency visual audit across setup, voting, reveal, and summary surfaces so the fallback is not limited to private pass-and-play screens.
- Decide whether to add a CI launch metric job with runner-appropriate thresholds after one more local launch baseline on a clean simulator.

## 2026-05-11 01:50 PDT - Broader reduced-transparency gameplay audit

### Baseline Issue Or Opportunity
- Reduced Motion and Reduce Transparency were already proven on private handoff, role-card, and forced privacy-curtain surfaces.
- Setup, voting, reveal, and summary still lacked rendered reduced-transparency screenshot evidence.
- The previous proof did not show the normal gameplay path reaching summary with Reduce Transparency enabled and Reduce Motion disabled.

### Files Changed
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testReducedTransparencyGameplaySurfacesReachSummary`.
- Added shared `captureScreenshot(named:)` UI-test helper for retained visual audit artifacts.
- The new test launches with `-ui-testing-reduce-transparency`, verifies the app-owned accessibility preference marker, adds the minimum players, captures setup, plays a full round through voting and reveal, captures voting/reveal/summary, and confirms the reduced-transparency preference marker is still active at summary.

### Implementation Notes
- This broad audit intentionally keeps Reduce Motion disabled so the test proves reduced-transparency rendering independently of the reduced-motion private-surface path.
- The setup screenshot capture dismisses the keyboard before attaching the image. The first focused run passed but caught the keyboard over the lower setup controls, so the capture point was tightened and rerun.
- Reveal and summary screenshots intentionally occur after group reveal, when the secret word is public.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - First build after the test passed in 5.318s.
  - Final build after keyboard-free setup capture passed in 1.975s.
  - Diagnostics on both builds: `warnings: []`, `errors: []`.
- XcodeBuildMCP focused `test_sim` for initial `testReducedTransparencyGameplaySurfacesReachSummary`
  - Passed in 106.303s.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
  - `xcresulttool` test details reported duration `77.277078s`.
  - Exported 4 screenshots, but the setup artifact included the software keyboard.
- XcodeBuildMCP focused `test_sim` for final `testReducedTransparencyGameplaySurfacesReachSummary`
  - Passed in 105.938s.
  - Counts: `passed: 1`, `failed: 0`, `skipped: 0`.
  - Test duration from MCP: `79.668s`.
  - Exported 4 retained screenshots: `Reduced transparency player setup`, `Reduced transparency voting`, `Reduced transparency reveal`, and `Reduced transparency summary`.
  - `sips` verified all exported screenshots at `1206x2622`.
  - Manual visual inspection confirmed the final setup screenshot was keyboard-free and the voting/reveal/summary surfaces rendered without obvious overlap or blank content.

### Remaining Risk
- This is screenshot-retained visual evidence plus UI flow assertions, not pixel-diff snapshot testing.
- The focused test proves a 3-player reduced-transparency round, not the max-player stress path under reduced transparency.
- The full UI suite was not rerun in this loop because only a new UI test/helper was added and the focused path compiled and passed twice.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.7/5
- UI automation: 4.65/5
- Performance: 3.1/5
- Release readiness: 2.85/5
- Repo clarity: 4.0/5

### Next Frontier
- Add lower-level runtime memory evidence for repeated rounds, using an ETTrace/Instruments/RSS sampler or memgraph workflow instead of relying on XCUITest timing attachments alone.
- Add a clean-simulator launch metric baseline and decide whether the launch CSV gate should become a CI job with runner-appropriate thresholds.
- Consider lightweight visual assertions over screenshot dimensions or named attachment manifests so reduced-transparency screenshot capture cannot silently disappear.

## 2026-05-11 02:03 PDT - Rendered-flow RSS memory probe

### Baseline Issue Or Opportunity
- Repeated rendered hosted-flow tests recorded wall-clock timings but still had no lower-level process memory evidence.
- The launch metric gate covered startup timing only; it did not sample memory growth, peak RSS, or app process identity while gameplay was running.
- The latest frontier explicitly called for lower-level runtime memory evidence before claiming stronger performance coverage.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added an executable stdlib Python probe that runs a focused UI test with `xcodebuild`, samples the simulator app process RSS from host `ps`, writes a CSV, prints a summary, preserves the `.xcresult`, and optionally fails when peak RSS exceeds `--max-rss-mb`.
- The default focused target is `ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds`, so the probe covers the existing two-round rendered hosted-flow lab.
- The probe identifies the app process by the simulator bundle fragment `/Imposter.app/Imposter`, excluding UI test runner processes.

### Implementation Notes
- This is host RSS sampling of the simulator app process, not an Instruments trace, heap graph, or leak root-cause report.
- The first real run used a provisional `300 MB` ceiling and failed the gate while the underlying UI test passed. That kept the high Debug-simulator memory peak visible instead of hiding it.
- The second run used a `450 MB` Debug-simulator ceiling and passed, giving a repeatable baseline while preserving the observed peak.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and documented `--result-bundle`, `--output-csv`, `--interval`, `--max-rss-mb`, and `--verbose-xcodebuild`.
- `scripts/probe_ui_memory.py --replace --result-bundle /tmp/imposter-ui-memory-probe.xcresult --output-csv /tmp/imposter-ui-memory-probe.csv --interval 1.0 --max-rss-mb 300`
  - Failed the memory gate with exit code `1` because peak RSS exceeded the provisional ceiling.
  - The wrapped UI test still passed: `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` duration `115.464505s`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - Probe summary: `Samples: 104`, `First RSS: 105.797 MB`, `Last RSS: 328.844 MB`, `Min RSS: 105.797 MB`, `Peak RSS: 380.031 MB`, `Last-minus-first RSS: 223.047 MB`, `Peak-minus-first RSS: 274.234 MB`.
- `scripts/probe_ui_memory.py --replace --result-bundle /tmp/imposter-ui-memory-probe-pass.xcresult --output-csv /tmp/imposter-ui-memory-probe-pass.csv --interval 1.0 --max-rss-mb 450`
  - Passed with exit code `0`.
  - The wrapped UI test passed: `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`, `result: Passed`, `totalTestCount: 1`.
  - `xcresulttool` test details reported `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` duration `115.212523s`.
  - Exported timing attachment reported `Rounds: 2`, `Round durations: 40.454, 41.527 seconds`, `Total duration: 86.601 seconds`, `Device: iPhone 17 Pro`.
  - Probe summary: `Samples: 102`, `First RSS: 107.625 MB`, `Last RSS: 335.500 MB`, `Min RSS: 107.625 MB`, `Peak RSS: 375.406 MB`, `Last-minus-first RSS: 227.875 MB`, `Peak-minus-first RSS: 267.781 MB`.
  - CSV `/tmp/imposter-ui-memory-probe-pass.csv` contained `103` lines including the header.

### Remaining Risk
- The measured Debug-simulator peak is far above the product target of `< 100 MB`; this is not yet a release-build or physical-device memory claim.
- Host RSS includes simulator/debug/runtime overhead and does not identify retained object types. A memgraph or Instruments trace is still needed to determine whether the observed growth is app-owned leak pressure, SwiftUI/runtime allocation churn, or simulator overhead.
- The probe currently samples one repeated 3-player rendered hosted lab. It does not cover max-player repeated rounds, image-generation mode, or long party sessions.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.75/5
- UI automation: 4.65/5
- Performance: 3.25/5
- Release readiness: 2.9/5
- Repo clarity: 4.05/5

### Next Frontier
- Capture a simulator memgraph after the repeated rendered flow and summarize app-owned leak groups so the high RSS peak has object-level evidence.
- Add a clean-simulator launch metric baseline and decide whether the launch CSV gate should become a CI job with runner-appropriate thresholds.
- Consider lightweight visual assertions over screenshot dimensions or named attachment manifests so reduced-transparency screenshot capture cannot silently disappear.

## 2026-05-11 02:19 PDT - Rendered-flow memgraph leak capture

### Baseline Issue Or Opportunity
- The RSS probe established a repeatable Debug-simulator peak around `375-380 MB`, but it could not identify whether that memory was app-owned retained objects, SwiftUI/runtime churn, or simulator/debug overhead.
- The latest frontier specifically called for a simulator memgraph after the repeated rendered flow so the high RSS number had object-level evidence.
- A first pause attempt using `xcodebuild` environment variables was not reliable: the focused rendered-flow test completed normally in `152.546s` and no ready marker appeared.

### Files Changed
- `ImposterUITests/ImposterUITests.swift`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `testRenderedHostedFlowPausesAtSummaryForMemoryGraphCapture`.
- The test reuses the rendered hosted-flow robot, plays two 3-player rounds through summary, writes a ready marker, and pauses so an external `simctl spawn ... leaks --outputGraph` workflow can capture the live app process.
- The helper is gated by `/tmp/imposter-memory-capture-control` and skips by default, so normal UI-test runs do not stall for manual capture.

### Implementation Notes
- The control file accepts `ready_file` and `pause_seconds` key/value lines. This avoids relying on test-runner environment propagation through `xcodebuild`.
- The default skip message is explicit: create `/tmp/imposter-memory-capture-control` only when running the external memgraph helper.
- Temporary control and marker files were removed after capture so the focused test returned to the skip-by-default behavior.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `build_sim` with `scheme=Imposter-UITests`, `simulator=iPhone 17 Pro`, `iOS 26.4.1`
  - Passed in `1.789s`.
  - Diagnostics: `warnings: []`, `errors: []`.
- Control-file capture run:
  - Command shape: `xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -destination 'platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6' -only-testing:ImposterUITests/ImposterUITests/testRenderedHostedFlowPausesAtSummaryForMemoryGraphCapture -resultBundlePath /tmp/imposter-ui-memgraph-capture.xcresult -quiet`.
  - Ready marker appeared at `/tmp/imposter-memory-capture-ready` with `test=-[ImposterUITests testRenderedHostedFlowPausesAtSummaryForMemoryGraphCapture]`.
  - Xcode output reported `256.884 elapsed -- Testing started completed`.
  - `xcresulttool` summary: `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `xcresulttool` test details: `testRenderedHostedFlowPausesAtSummaryForMemoryGraphCapture()` passed in `237.107193s`.
- Memgraph capture:
  - Capture script: `ios-memgraph-leaks/scripts/capture_sim_memgraph.sh --udid A113E399-3127-41CE-AB7E-B529DB41B3B6 --bundle-id com.rishabh.Imposter --out-dir /tmp/imposter-memgraph-capture`.
  - Memgraph: `/tmp/imposter-memgraph-capture/com.rishabh.Imposter-2044-20260511-021443.memgraph`.
  - Leaks output: `/tmp/imposter-memgraph-capture/com.rishabh.Imposter-2044-20260511-021443.leaks.txt`.
  - Metadata: `/tmp/imposter-memgraph-capture/com.rishabh.Imposter-2044-20260511-021443.metadata.txt`.
  - Metadata identified `UIKitApplication:com.rishabh.Imposter[c92d][rb-legacy]`, pid `2044`, `leaks_exit_status: 0`.
  - `ls -lh` showed the memgraph at `3.6M`; `leaks` also reported a `3.55 MB` graph.
- Leak summary:
  - Summary script: `ios-memgraph-leaks/scripts/summarize_memgraph_leaks.py ... --trace-limit 3 --trace-lines 80 --out /tmp/imposter-memgraph-capture/leak-summary.md`.
  - Result: `Total: 0 leaks / 0 bytes`, `Parsed leak entries: 0`.
- Default skip proof after cleanup:
  - Removed `/tmp/imposter-memory-capture-control` and `/tmp/imposter-memory-capture-ready`.
  - Focused `xcodebuild test` completed with exit code `0` and Xcode elapsed `24.838s`.
  - `xcresulttool` summary: `result: Skipped`, `totalTestCount: 1`, `passedTests: 0`, `failedTests: 0`, `skippedTests: 1`.
  - `xcresulttool` test details: `testRenderedHostedFlowPausesAtSummaryForMemoryGraphCapture()` skipped in `3.574627s` with the expected control-file skip message.

### Remaining Risk
- The memgraph leak summary shows no `leaks`-visible retain cycles in this capture, so the RSS peak is not explained as a simple app-owned leak.
- This is still Debug-simulator evidence. It does not prove the `< 100 MB` product target on a release build or physical device.
- The capture covers a two-round 3-player rendered hosted flow only, not max-player repeated sessions, image generation, or very long party runs.
- A stale `/tmp/imposter-memory-capture-control` file would intentionally re-enable the pause helper; cleanup is part of the workflow.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.7/5
- Performance: 3.35/5
- Release readiness: 2.95/5
- Repo clarity: 4.1/5

### Next Frontier
- Add an allocation-oriented Instruments trace or ETTrace pass for the repeated rendered flow so the high RSS baseline can be attributed to concrete allocation families rather than only `leaks` output.
- Run the memory probe against a clean simulator and release-like build configuration to separate app behavior from Debug-simulator overhead.
- Extend the memory evidence to max-player repeated rounds and image-generation fallback paths.

## 2026-05-11 02:41 PDT - Release-configuration rendered-flow memory baseline

### Baseline Issue Or Opportunity
- The Debug-simulator RSS probe peaked around `375-380 MB`, and the memgraph capture found `0 leaks / 0 bytes`.
- The remaining memory question was whether the high RSS was partly Debug configuration overhead, so the next useful step was a release-like Xcode test configuration baseline.
- An attempted Instruments `Allocations` path was not reliable enough to keep: host-PID attach failed with `Cannot find process for provided pid`, simulator-device attach to `Imposter` produced only a `56K` incomplete trace, and `xctrace export` failed with `Document Missing Template Error`.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Extended `scripts/probe_ui_memory.py` with `--configuration`, which passes `-configuration <value>` into the wrapped `xcodebuild test` command.
- The probe now prints the selected configuration and writes the exact xcodebuild command at the top of the `.xcodebuild.log` artifact.

### Implementation Notes
- The abandoned `xctrace` wrapper was removed rather than leaving a failing profiling script in the repo.
- `xctrace record --template Allocations --device A113E399-3127-41CE-AB7E-B529DB41B3B6 --attach Imposter` did start a recorder, but it did not finalize a valid trace even when interrupted while the app was still paused.
- The Release RSS run uses the same focused rendered hosted-flow UI lab as the Debug probe, keeping the comparison narrow: `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds`.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now includes `--configuration CONFIGURATION`.
- Failed/discarded Instruments smoke:
  - `xctrace` host PID attach failed with `Cannot find process for provided pid: 19407`.
  - `xctrace` simulator-device attach by app name found the simulator target but hung until terminated; output trace remained `56K`.
  - `xctrace export --toc` on that bundle failed with `Document Missing Template Error`.
  - The paired capture UI test still passed, so the failure was isolated to Instruments trace finalization rather than the app flow.
- Release memory probe:
  - Command: `scripts/probe_ui_memory.py --replace --configuration Release --result-bundle /tmp/imposter-ui-memory-probe-release.xcresult --output-csv /tmp/imposter-ui-memory-probe-release.csv --interval 1.0`.
  - Exit code `0`.
  - Wrapped command recorded in `/tmp/imposter-ui-memory-probe-release.xcodebuild.log`: `xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -configuration Release -destination platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6 -resultBundlePath /tmp/imposter-ui-memory-probe-release.xcresult -only-testing:ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds -quiet`.
  - Xcode output reported `124.938 elapsed -- Testing started completed`.
  - `xcresulttool` summary: `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `xcresulttool` test details: `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` passed in `121.983194s`.
  - Probe summary: `Samples: 103`, `PIDs: 69718`, `First RSS: 130.219 MB`, `Last RSS: 315.609 MB`, `Min RSS: 130.219 MB`, `Peak RSS: 343.203 MB`, `Last-minus-first RSS: 185.391 MB`, `Peak-minus-first RSS: 212.984 MB`.
  - CSV `/tmp/imposter-ui-memory-probe-release.csv` contained `104` lines including the header.

### Remaining Risk
- Release-configuration simulator RSS improved from the Debug peak but is still far above the product target of `< 100 MB`; this remains a memory-performance risk.
- This is still a simulator test build, not an App Store-style archive on physical hardware.
- RSS still cannot attribute allocation families. The local `xctrace` Allocations path is currently unreliable, so the next attribution attempt should use either manual Instruments export, an ETTrace app-target patch, or a different supported trace template.
- The Release baseline covers two 3-player rendered rounds only.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.7/5
- Performance: 3.4/5
- Release readiness: 3.0/5
- Repo clarity: 4.1/5

### Next Frontier
- Capture allocation-family evidence with a path that finalizes cleanly: manual Instruments export, temporary ETTrace target wiring, or a different xctrace template that supports simulator app attach without corrupting the trace.
- Run the release memory probe on a freshly erased simulator to separate app growth from simulator/process reuse noise.
- Extend the memory baseline to the maximum-player rendered flow.

## 2026-05-11 02:47 PDT - Maximum-player Release memory baseline

### Baseline Issue Or Opportunity
- The Release memory baseline covered two repeated 3-player rounds only.
- The ledger still lacked memory evidence for the heavier rendered path with all 10 players, where role reveal, clue entry, voting, reveal, summary, scrolling, and layout pressure are materially higher.
- The existing `testMaximumPlayerRenderedFlowCompletesRound` already drove the right product path, so this loop reused that app evidence instead of adding a new UI robot.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No new test target was added.
- Cleaned the probe command-construction indentation while preserving the new `--configuration` support.
- Reused `testMaximumPlayerRenderedFlowCompletesRound` as the focused UI lab for max-player Release RSS sampling.

### Implementation Notes
- The first few RSS samples caught the app process before it had fully loaded (`1.109 MB`, `1.109 MB`, `0.859 MB`, then `105.688 MB`), so the exaggerated `Peak-minus-first` number should not be treated as steady-state growth.
- Peak RSS and last RSS are the useful comparison points for this run.
- This probe still samples host-visible simulator RSS; it does not attribute allocation families or claim physical-device memory behavior.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed before the max-player run.
- Release max-player memory probe:
  - Command: `scripts/probe_ui_memory.py --replace --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-release-max.xcresult --output-csv /tmp/imposter-ui-memory-probe-release-max.csv --interval 1.0`.
  - Exit code `0`.
  - Wrapped command recorded in `/tmp/imposter-ui-memory-probe-release-max.xcodebuild.log`: `xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -configuration Release -destination platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6 -resultBundlePath /tmp/imposter-ui-memory-probe-release-max.xcresult -only-testing:ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound -quiet`.
  - Xcode output reported `204.276 elapsed -- Testing started completed`.
  - `xcresulttool` summary: `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `xcresulttool` test details: `testMaximumPlayerRenderedFlowCompletesRound()` passed in `198.554307s`.
  - Probe summary: `Samples: 168`, `PIDs: 84049`, `First RSS: 1.109 MB`, `Last RSS: 350.844 MB`, `Min RSS: 0.859 MB`, `Peak RSS: 366.047 MB`, `Last-minus-first RSS: 349.734 MB`, `Peak-minus-first RSS: 364.938 MB`.
  - CSV `/tmp/imposter-ui-memory-probe-release-max.csv` contained `169` lines including the header.
  - Last steady samples were clustered around `362.6 MB`, peak `366.047 MB`, then final `350.844 MB`.

### Remaining Risk
- The 10-player Release simulator path still peaks above the 3-player Release run (`366.047 MB` vs `343.203 MB`) and remains far above the product target of `< 100 MB`.
- Since the first samples catch process startup, the current probe should grow a warm-start summary mode before using growth deltas as a gate.
- This is one max-player round, not repeated max-player rounds or image generation.
- Allocation-family attribution remains unresolved because the local `xctrace Allocations` path did not finalize cleanly in the prior loop.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.45/5
- Release readiness: 3.05/5
- Repo clarity: 4.1/5

### Next Frontier
- Add a warm-start RSS summary mode to `scripts/probe_ui_memory.py` so growth deltas ignore startup samples below a configurable floor.
- Run the Release memory probe after erasing or freshly booting the simulator to reduce process reuse noise.
- Continue seeking allocation attribution through a trace path that exports cleanly or by adding targeted app-side memory instrumentation.

## 2026-05-11 02:51 PDT - Warm-start RSS summary mode

### Baseline Issue Or Opportunity
- The max-player Release RSS probe caught the app process before it fully loaded, with early samples around `1 MB`.
- That made `Last-minus-first RSS` and `Peak-minus-first RSS` misleading for growth analysis even though peak and final RSS were still useful.
- The latest frontier called for a warm-start summary mode so startup samples below a configurable floor can be ignored when calculating growth deltas.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--warm-rss-floor-mb` to print an additional summary starting at the first sample whose RSS meets or exceeds the configured floor.
- Added `--analyze-csv` so existing probe artifacts can be re-summarized without rerunning long UI tests.
- The normal probe path still writes CSV and xcodebuild logs, but now uses the shared summary code for raw and warm-start output.

### Implementation Notes
- Warm-start mode keeps the original raw summary intact, then adds a second section with the floor, the first warm sample index, warm sample count, elapsed range, RSS min/peak/last, and adjusted growth deltas.
- The warm-start slice begins at the first sample meeting the floor and keeps all later samples. It does not filter individual later samples out of the timeline.
- `--result-bundle` and `--output-csv` are now optional at argument-parse time so `--analyze-csv` can run standalone; the live probe path still rejects missing output arguments with exit code `2`.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--analyze-csv` plus `--warm-rss-floor-mb`.
- `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-max.csv --warm-rss-floor-mb 100`
  - Exit code `0`.
  - Raw summary: `Samples: 168`, `First RSS: 1.109 MB`, `Last RSS: 350.844 MB`, `Min RSS: 0.859 MB`, `Peak RSS: 366.047 MB`, `Last-minus-first RSS: 349.735 MB`, `Peak-minus-first RSS: 364.938 MB`.
  - Warm-start summary with `100.000 MB` floor: `Warm-start sample index: 4 of 168`, `Samples: 165`, `First RSS: 105.688 MB`, `Last RSS: 350.844 MB`, `Peak RSS: 366.047 MB`, `Last-minus-first RSS: 245.156 MB`, `Peak-minus-first RSS: 260.359 MB`.
- `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release.csv --warm-rss-floor-mb 100`
  - Exit code `0`.
  - The 3-player Release run already started warm: `Warm-start sample index: 1 of 103`.
  - Warm summary matched the raw summary: `First RSS: 130.219 MB`, `Last RSS: 315.609 MB`, `Peak RSS: 343.203 MB`, `Last-minus-first RSS: 185.390 MB`, `Peak-minus-first RSS: 212.984 MB`.
- `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-max.csv --warm-rss-floor-mb 1000`
  - Exit code `0`.
  - Printed `No samples met or exceeded the warm-start RSS floor.`
- `scripts/probe_ui_memory.py --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen`
  - Exit code `2`.
  - Printed `--result-bundle is required unless --analyze-csv is used`, proving the live probe path still rejects missing output arguments.

### Remaining Risk
- Warm-start RSS makes growth deltas less misleading, but it still does not attribute allocation families or separate app memory from simulator/runtime overhead.
- The current floor is caller-selected; future gates need a documented default threshold per environment before they can be enforced in CI.
- This loop re-analyzed existing real probe CSVs instead of running another long UI test, because the change was in summarization math and argument handling.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.5/5
- Release readiness: 3.05/5
- Repo clarity: 4.15/5

### Next Frontier
- Use warm-start mode during a fresh Release memory probe after erasing or freshly booting the simulator.
- Add an optional warm-start RSS gate once the floor and threshold have enough repeated-run evidence.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 02:59 PDT - Fresh-simulator Release warm-start memory probe

### Baseline Issue Or Opportunity
- Prior Release RSS baselines ran on an already-used simulator, leaving some uncertainty around process reuse and simulator state.
- Warm-start summary mode was available but had only re-analyzed existing CSVs, not a new live probe run.
- The next frontier called for a Release memory probe after erasing or freshly booting the simulator.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No test or harness code changed in this loop.
- Reused `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds` as the 3-player repeated rendered-flow Release memory lab.

### Implementation Notes
- Used XcodeBuildMCP `session_show_defaults` first; active profile was `imposter-ui` with project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6` (`iPhone 17 Pro`).
- Verified no Imposter `xcodebuild`/`xctest`/`xctrace` processes were running before the reset.
- Ran `xcrun simctl shutdown A113E399-3127-41CE-AB7E-B529DB41B3B6 || true` and `xcrun simctl erase A113E399-3127-41CE-AB7E-B529DB41B3B6`.
- The simulator was `Shutdown` after erase. The probe's `xcodebuild test` booted it as part of the run.
- The first app RSS sample arrived late at `196.782s` because fresh simulator boot/install dominated the early part of the command.

### Verification Commands And Exact Outcome
- Simulator reset:
  - Before reset: `iPhone 17 Pro (A113E399-3127-41CE-AB7E-B529DB41B3B6) (Booted)`.
  - After shutdown/erase: `iPhone 17 Pro (A113E399-3127-41CE-AB7E-B529DB41B3B6) (Shutdown)`.
- Fresh Release warm-start memory probe:
  - Command: `scripts/probe_ui_memory.py --replace --configuration Release --result-bundle /tmp/imposter-ui-memory-probe-release-fresh.xcresult --output-csv /tmp/imposter-ui-memory-probe-release-fresh.csv --interval 1.0 --warm-rss-floor-mb 100`.
  - Exit code `0`.
  - Wrapped command recorded in `/tmp/imposter-ui-memory-probe-release-fresh.xcodebuild.log`: `xcodebuild test -project Imposter.xcodeproj -scheme Imposter-UITests -configuration Release -destination platform=iOS Simulator,id=A113E399-3127-41CE-AB7E-B529DB41B3B6 -resultBundlePath /tmp/imposter-ui-memory-probe-release-fresh.xcresult -only-testing:ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds -quiet`.
  - Xcode output reported `318.210 elapsed -- Testing started completed`.
  - `xcresulttool` summary: `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `xcresulttool` test details: `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` passed in `130.031756s`.
  - Probe summary: `Samples: 90`, `PIDs: 18663`, `First elapsed: 196.782 seconds`, `Last elapsed: 323.866 seconds`, `First RSS: 288.484 MB`, `Last RSS: 268.797 MB`, `Min RSS: 260.938 MB`, `Peak RSS: 353.344 MB`, `Last-minus-first RSS: -19.688 MB`, `Peak-minus-first RSS: 64.859 MB`.
  - Warm-start summary with `100.000 MB` floor started at sample `1 of 90`, matching the raw summary because the first app sample was already warm.
  - CSV `/tmp/imposter-ui-memory-probe-release-fresh.csv` contained `91` lines including the header.

### Remaining Risk
- Fresh-simulator Release peak (`353.344 MB`) was higher than the prior 3-player Release peak (`343.203 MB`) by `10.141 MB`, but last RSS was lower (`268.797 MB` vs `315.609 MB`). More repeated runs are needed before setting a gate.
- The first sample appears after substantial boot/install delay, so this probe is not a launch-memory measurement.
- The run is still simulator-only and does not attribute allocation families.
- Erasing the simulator is useful for freshness but expensive: total xcodebuild elapsed `318.210s` versus test duration `130.031756s`.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.55/5
- Release readiness: 3.1/5
- Repo clarity: 4.15/5

### Next Frontier
- Repeat the fresh-simulator Release probe or run a warm-simulator repeat immediately afterward to measure variance before setting a warm-start RSS gate.
- Add optional probe metadata for simulator reset state and first-app-sample delay.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:03 PDT - Memory probe metadata artifacts

### Baseline Issue Or Opportunity
- The fresh-simulator probe was useful, but key context lived across stdout, xcodebuild logs, simulator commands, and manual notes.
- The next frontier called for optional metadata so reset state and first-app-sample delay are preserved with the probe output.
- Without a summary artifact, future RSS comparisons would be too easy to misread after the terminal scrollback is gone.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--run-label` for naming a probe run.
- Added `--simulator-state` for notes like `erased-before-run`, `warm-booted`, or `warm-shutdown-before-run`.
- Added `--summary-output` for explicit summary artifact paths.
- Live probe mode now defaults to writing `<output-csv>.summary.txt`.
- Summaries now include a `Probe metadata` block with run label, simulator note, configuration, destination, focused test, command when available, result bundle, CSV path, and `First app sample delay`.

### Implementation Notes
- `--analyze-csv` uses the same metadata formatter as live probe mode, so old CSV artifacts can receive comparable summary files.
- Live probe mode still rejects missing `--result-bundle` or `--output-csv`, preserving the earlier guardrail.
- The metadata smoke used a launch-only UI test to verify the live artifact path without burning another full gameplay run.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--run-label`, `--simulator-state`, and `--summary-output`.
- CSV reanalysis with metadata:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-fresh.csv --warm-rss-floor-mb 100 --run-label fresh-release-reanalysis --simulator-state erased-before-original-run --summary-output /tmp/imposter-memory-summary-metadata.txt`.
  - Exit code `0`.
  - Summary artifact `/tmp/imposter-memory-summary-metadata.txt` contained `33` lines.
  - Metadata included `Run label: fresh-release-reanalysis`, `Simulator state: erased-before-original-run`, CSV path, and `First app sample delay: 196.782 seconds`.
  - Warm-start summary kept `Warm-start sample index: 1 of 90`, `Peak RSS: 353.344 MB`, `Last RSS: 268.797 MB`.
- Guardrail check:
  - Command: `scripts/probe_ui_memory.py --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen`.
  - Exit code `2`.
  - Printed `--result-bundle is required unless --analyze-csv is used`.
- Live metadata smoke:
  - Command: `scripts/probe_ui_memory.py --replace --configuration Release --run-label metadata-smoke-launch --simulator-state warm-shutdown-before-run --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-metadata-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-metadata-smoke.csv --interval 0.5 --warm-rss-floor-mb 100`.
  - Exit code `0`.
  - `xcresulttool` summary: `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `xcresulttool` test details: `testLaunchShowsHomeScreen()` passed in `6.458005s`.
  - Xcode output reported `47.236 elapsed -- Testing started completed`.
  - Summary artifact `/tmp/imposter-ui-memory-probe-metadata-smoke.summary.txt` contained `36` lines.
  - CSV `/tmp/imposter-ui-memory-probe-metadata-smoke.csv` contained `7` lines including the header.
  - Probe metadata recorded `Run label: metadata-smoke-launch`, `Simulator state: warm-shutdown-before-run`, the full xcodebuild command, result bundle path, CSV path, and `First app sample delay: 52.481 seconds`.
  - Raw smoke RSS summary: `Samples: 6`, `First RSS: 93.922 MB`, `Last RSS: 288.984 MB`, `Peak RSS: 288.984 MB`.
  - Warm-start smoke summary with `100.000 MB` floor: `Warm-start sample index: 2 of 6`, `Samples: 5`, `First RSS: 204.203 MB`, `Last RSS: 288.984 MB`, `Peak RSS: 288.984 MB`, `Last-minus-first RSS: 84.781 MB`.

### Remaining Risk
- Metadata improves comparability but does not by itself make the memory numbers pass the product target.
- The live smoke proves the artifact path with a launch-only test, not a full gameplay probe.
- First-app-sample delay is host-probe timing; it is not a replacement for app launch metric measurements or Instruments timelines.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.6/5
- Release readiness: 3.1/5
- Repo clarity: 4.2/5

### Next Frontier
- Run a warm-simulator full gameplay repeat with metadata to compare against the erased-simulator Release baseline.
- Add an optional warm-start RSS gate once at least two comparable full-flow runs establish variance.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:08 PDT - Warm-simulator Release repeat with metadata

### Baseline Issue Or Opportunity
- The erased-simulator Release run proved the full repeated rendered flow after reset, but a single run was not enough to understand variance.
- The metadata smoke proved the new summary artifact path, but only against `testLaunchShowsHomeScreen`.
- The next useful comparison was a warm, non-erased full gameplay repeat with the metadata fields attached to the RSS summary.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No app or probe code changed in this loop.
- Reused `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds` as the two-round 3-player Release gameplay lab.

### Implementation Notes
- XcodeBuildMCP `session_show_defaults` confirmed the `imposter-ui` profile: project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
- Simulator state before the run was `Shutdown`, but not erased after the metadata smoke, so the label used was `warm-shutdown-no-erase-after-smoke`.
- This run is directly comparable to the erased-simulator Release probe at the test-flow level, while preserving the difference in simulator state through metadata.

### Verification Commands And Exact Outcome
- Warm Release repeat command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label warm-release-repeat-after-metadata-smoke --simulator-state warm-shutdown-no-erase-after-smoke --result-bundle /tmp/imposter-ui-memory-probe-release-warm-repeat.xcresult --output-csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --interval 1.0 --warm-rss-floor-mb 100`.
  - Exit code `0`.
  - Probe metadata recorded the run label, simulator state, full xcodebuild command, result bundle, CSV path, and `First app sample delay: 25.054 seconds`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-release-warm-repeat.summary.txt`, `36` lines.
  - CSV: `/tmp/imposter-ui-memory-probe-release-warm-repeat.csv`, `105` lines including the header.
- `xcresulttool` summary:
  - `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
- `xcresulttool` test details:
  - `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` passed in `115.966406s`.
- Xcode output:
  - `135.925 elapsed -- Testing started completed`.
- Probe summary:
  - `Samples: 104`, `PIDs: 27482`, `First elapsed: 25.054 seconds`, `Last elapsed: 137.241 seconds`.
  - `First RSS: 130.688 MB`, `Last RSS: 331.047 MB`, `Min RSS: 130.688 MB`, `Peak RSS: 372.156 MB`.
  - `Last-minus-first RSS: 200.359 MB`, `Peak-minus-first RSS: 241.469 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 104`, so raw and warm-start summaries matched.

### Comparison Against Fresh-Simulator Release Run
- Fresh erased run: first app sample delay `196.782s`, Xcode elapsed `318.210s`, test duration `130.031756s`, peak RSS `353.344 MB`, final RSS `268.797 MB`.
- Warm non-erased repeat: first app sample delay `25.054s`, Xcode elapsed `135.925s`, test duration `115.966406s`, peak RSS `372.156 MB`, final RSS `331.047 MB`.
- Warm repeat was much faster to first app sample and total completion, but peak RSS was `18.812 MB` higher and final RSS was `62.250 MB` higher.

### Remaining Risk
- Two comparable full-flow runs are still too few for a stable gate.
- The variance goes in opposite directions: erased run was slower but ended lower; warm run was faster but retained more RSS by the final sample.
- This remains simulator RSS evidence, not allocation attribution or physical-device memory proof.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.65/5
- Release readiness: 3.1/5
- Repo clarity: 4.2/5

### Next Frontier
- Add an optional warm-start RSS gate to the probe with separate peak and final RSS thresholds, then first run it in non-failing/report-only mode against the existing CSVs.
- Run another warm repeat or max-player repeat before enforcing any threshold.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:10 PDT - Report-only warm-start RSS gates

### Baseline Issue Or Opportunity
- The RSS probe had enough comparable full-flow evidence to begin experimenting with thresholds, but not enough to enforce a CI-style gate.
- The latest frontier called for separate warm-start peak and final RSS gates, first in non-failing/report-only mode against existing CSVs.
- The probe already supported raw peak gating, warm-start summaries, and metadata; the missing piece was threshold evaluation over warm-start samples.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--max-warm-peak-rss-mb`.
- Added `--max-warm-final-rss-mb`.
- Added `--rss-gate-mode {fail,report}`. The default is `fail`, while `report` prints `REPORT-FAIL` without returning a failing exit code.
- Warm-start gates require `--warm-rss-floor-mb`, preventing ambiguous threshold checks over raw samples.

### Implementation Notes
- Gate summaries are appended to the same summary body used by live probes and `--analyze-csv`.
- Warm-start gates use the same first-sample-at-or-above-floor slice as warm-start summaries.
- Existing `--max-rss-mb` raw peak behavior is now included in the shared gate summary.
- Verification exposed a bug where `--analyze-csv` printed failing gates but still exited `0` in default fail mode. That path now returns `1` for failed gates, while `--rss-gate-mode report` remains non-failing.
- If a warm-start gate is configured but no samples meet the floor, report mode records the skipped gate and exits `0`; fail mode exits `1`.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--max-warm-peak-rss-mb`, `--max-warm-final-rss-mb`, and `--rss-gate-mode {fail,report}`.
- Report-only warm gate failure against warm repeat:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 360 --max-warm-final-rss-mb 320 --rss-gate-mode report --run-label warm-repeat-report-gates --simulator-state existing-artifact`.
  - Exit code `0`.
  - Gate summary: `Warm-start peak RSS: REPORT-FAIL (372.156 MB <= 360.000 MB)` and `Warm-start final RSS: REPORT-FAIL (331.047 MB <= 320.000 MB)`.
- Strict warm gate failure against warm repeat:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 360 --max-warm-final-rss-mb 320 --run-label warm-repeat-failing-gates --simulator-state existing-artifact`.
  - Exit code `1`.
  - Printed the same two `FAIL` lines plus `FAIL: one or more RSS gates failed`.
- Strict warm gate pass against fresh Release run:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-fresh.csv --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --run-label fresh-release-strict-pass-gates --simulator-state existing-artifact --summary-output /tmp/imposter-report-gates-summary.txt`.
  - Exit code `0`.
  - Gate summary: `Warm-start peak RSS: PASS (353.344 MB <= 380.000 MB)` and `Warm-start final RSS: PASS (268.797 MB <= 340.000 MB)`.
  - Summary artifact `/tmp/imposter-report-gates-summary.txt` contained `39` lines.
- Missing floor guard:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-fresh.csv --max-warm-peak-rss-mb 360`.
  - Exit code `2`.
  - Printed `--warm-rss-floor-mb is required when using warm RSS gates`.
- No warm samples behavior:
  - Report mode with `--warm-rss-floor-mb 1000 --max-warm-peak-rss-mb 360` exited `0` and printed `Warm-start gates skipped: no samples met the RSS floor.`
  - Fail mode with the same threshold exited `1` and printed `FAIL: one or more RSS gates failed`.
- Raw peak report gate:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --warm-rss-floor-mb 100 --max-rss-mb 360 --rss-gate-mode report`.
  - Exit code `0`.
  - Gate summary: `Raw peak RSS: REPORT-FAIL (372.156 MB <= 360.000 MB)`.

### Remaining Risk
- Thresholds are still experimental. The warm repeat failed a `360/320 MB` peak/final threshold, while the erased run passed a looser `380/340 MB` threshold.
- No gate should be enforced in CI until there are more repeated Release runs and a clear simulator/device policy.
- RSS gates still do not explain allocation families.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.7/5
- Release readiness: 3.15/5
- Repo clarity: 4.25/5

### Next Frontier
- Run a max-player Release memory probe with metadata and report-only gates to see whether the heavier path needs a separate threshold class.
- Add a small CSV comparison helper for multiple probe artifacts so variance tables no longer need to be hand-written in the ledger.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:17 PDT - Max-player Release report-gate probe

### Baseline Issue Or Opportunity
- The 3-player Release flow had erased and warm-repeat evidence plus report-only gates.
- The 10-player path had an older Release RSS baseline, but it predated the metadata and gate output.
- The latest frontier called for a max-player Release probe with metadata and report-only gates to see whether the heavier path needs its own threshold class.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No app or probe code changed in this loop.
- Reused `testMaximumPlayerRenderedFlowCompletesRound` as the max-player rendered Release memory lab.

### Implementation Notes
- Used the same tentative `380 MB` warm-start peak and `340 MB` warm-start final thresholds that passed the fresh 3-player Release artifact.
- Ran the max-player thresholds in `--rss-gate-mode report`, so the probe could document gate status without failing the run.
- The simulator started as `Shutdown`, but it was not erased after the prior warm-repeat work.

### Verification Commands And Exact Outcome
- XcodeBuildMCP `session_show_defaults`
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
- Max-player Release report-gate command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label max-release-report-gates-after-warm-repeat --simulator-state warm-shutdown-no-erase-after-warm-repeat --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-release-max-report.xcresult --output-csv /tmp/imposter-ui-memory-probe-release-max-report.csv --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Probe metadata recorded the run label, simulator state, full xcodebuild command, result bundle, CSV path, and `First app sample delay: 56.015 seconds`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-release-max-report.summary.txt`, `42` lines.
  - CSV: `/tmp/imposter-ui-memory-probe-release-max-report.csv`, `154` lines including the header.
- `xcresulttool` summary:
  - `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
- `xcresulttool` test details:
  - `testMaximumPlayerRenderedFlowCompletesRound()` passed in `189.063666s`.
- Xcode output:
  - `232.876 elapsed -- Testing started completed`.
- Probe summary:
  - `Samples: 153`, `PIDs: 33824`, `First elapsed: 56.015 seconds`, `Last elapsed: 241.550 seconds`.
  - Raw RSS: `First RSS: 13.578 MB`, `Last RSS: 296.656 MB`, `Min RSS: 13.578 MB`, `Peak RSS: 318.203 MB`.
  - Warm-start floor `100.000 MB` began at sample `2 of 153`.
  - Warm-start RSS: `Samples: 152`, `First RSS: 130.062 MB`, `Last RSS: 296.656 MB`, `Peak RSS: 318.203 MB`, `Last-minus-first RSS: 166.594 MB`, `Peak-minus-first RSS: 188.141 MB`.
- RSS gate summary:
  - `Mode: report`.
  - `Warm-start peak RSS: PASS (318.203 MB <= 380.000 MB)`.
  - `Warm-start final RSS: PASS (296.656 MB <= 340.000 MB)`.

### Comparison Against Older Max-Player Release Baseline
- Earlier max-player Release baseline: test duration `198.554307s`, Xcode elapsed `204.276s`, peak RSS `366.047 MB`, final RSS `350.844 MB`.
- New max-player report-gate run: test duration `189.063666s`, Xcode elapsed `232.876s`, peak RSS `318.203 MB`, final RSS `296.656 MB`.
- The new run was lower by `47.844 MB` peak RSS and `54.188 MB` final RSS, despite longer total Xcode elapsed.
- Unlike the older max-player run, the new run passed the tentative `380/340 MB` report thresholds.

### Remaining Risk
- Max-player RSS variance is large enough that a separate threshold class is not yet proven unnecessary.
- This was still a single max-player run, not a repeated max-player series.
- Passing report-only gates is evidence for threshold exploration, not a release-quality memory guarantee.
- RSS still does not attribute allocation families or prove physical-device memory behavior.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.72/5
- Release readiness: 3.15/5
- Repo clarity: 4.25/5

### Next Frontier
- Add a small CSV comparison helper for multiple probe artifacts so variance tables can be generated from artifacts rather than hand-written.
- Run another max-player report-gate probe before deciding whether `380/340 MB` is a useful tentative threshold.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:20 PDT - Probe CSV comparison helper

### Baseline Issue Or Opportunity
- Release memory probe evidence was split across several CSVs and ledger summaries.
- Comparing fresh, warm, max-player, and older max-player runs still required hand-built tables, which made memory-threshold discussion more error-prone than the probe itself.
- The latest frontier called for a small comparison helper that can generate variance tables directly from probe artifacts.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--compare-csv` for two or more existing RSS CSV artifacts.
- Added repeatable `--compare-label` values so table rows can use scenario names instead of long temp filenames.
- Reused `--warm-rss-floor-mb`, warm-start gate thresholds, `--rss-gate-mode`, and `--summary-output` in comparison mode.

### Implementation Notes
- The script now computes shared sample stats through `SampleStats`, so single-run summaries and multi-run comparisons use the same first/final/peak/growth math.
- Comparison mode prints a raw RSS table, an optional warm-start RSS table, and an optional per-artifact gate table.
- The first CSV is the baseline; peak and final deltas are rendered relative to that artifact.
- Report mode keeps comparison runs non-failing while still surfacing `REPORT-FAIL` rows for tentative thresholds.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--compare-csv` and `--compare-label`.
- Release artifact comparison:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label fresh-3p --compare-label warm-3p --compare-label max-10p-report --compare-label max-10p-older --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label release-memory-artifact-variance --summary-output /tmp/imposter-release-memory-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-release-memory-comparison.txt`, `32` lines.
  - Raw comparison: `warm-3p` peak was `+18.812 MB` and final was `+62.250 MB` versus `fresh-3p`; `max-10p-report` peak was `-35.141 MB` and final was `+27.859 MB`; `max-10p-older` peak was `+12.703 MB` and final was `+82.047 MB`.
  - Warm-start comparison: `max-10p-report` began warm samples at `2 of 153` and had `318.203 MB` peak / `296.656 MB` final; `max-10p-older` began at `4 of 168` and had `366.047 MB` peak / `350.844 MB` final.
  - Gate comparison: every artifact passed the tentative `380 MB` warm peak gate; only `max-10p-older` reported `REPORT-FAIL` for the `340 MB` warm final gate with `350.844 MB`.
- Compare guard, one CSV:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv`.
  - Exit code `2`.
  - Printed `--compare-csv requires at least two CSV paths`.
- Compare guard, mismatched labels:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --compare-label only-one-label`.
  - Exit code `2`.
  - Printed `--compare-label count must match --compare-csv count`.
- Strict comparison gate failure:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label fresh-3p --compare-label max-10p-older --warm-rss-floor-mb 100 --max-warm-final-rss-mb 340`.
  - Exit code `1`.
  - Printed `FAIL: one or more RSS gates failed`; the gate table showed `max-10p-older` final RSS `FAIL (350.844 MB <= 340.000 MB)`.
- `git diff --check`
  - Passed.

### Remaining Risk
- Comparison mode still compares CSV RSS samples only; it does not parse `xcresult` durations or prove allocation families.
- The artifacts are simulator measurements and remain sensitive to simulator state.
- The tentative `380/340 MB` gate is still exploratory because the older max-player artifact misses the final threshold while the newer max-player artifact passes it.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.8/5
- UI automation: 4.75/5
- Performance: 3.74/5
- Release readiness: 3.17/5
- Repo clarity: 4.3/5

### Next Frontier
- Extend the comparison helper to optionally ingest `xcresult` summaries so runtime, Xcode elapsed time, and RSS variance can sit in one artifact table.
- Run another max-player Release report-gate probe before considering separate 3-player and 10-player tentative thresholds.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:23 PDT - RSS comparison with XCTest result ingestion

### Baseline Issue Or Opportunity
- The new CSV comparison helper made memory variance repeatable, but runtime/pass-fail evidence still lived in separate `xcresulttool` commands and xcodebuild logs.
- The latest frontier called for one artifact table that combines RSS, gate status, focused test duration, result-bundle duration, and xcodebuild elapsed time.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added optional `--compare-xcresult`, repeated once per compared CSV.
- Added `--infer-xcresult`, which looks for sibling `.xcresult` bundles and `.xcodebuild.log` files next to each compared CSV.
- Added an `XCTest result comparison` table to comparison mode when result bundles are available.

### Implementation Notes
- `xcresulttool get test-results summary --format json` provides result, total/pass/fail/skip counts, device metadata, and bundle start/finish timestamps.
- `xcresulttool get test-results tests --format json` provides focused test case durations.
- The existing probe log format provides `IDETestOperationsObserverDebug: <seconds> elapsed -- Testing started completed`, now parsed as `Xcode elapsed s`.
- Explicit result bundles and inferred result bundles are mutually exclusive to keep row alignment unambiguous.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--compare-xcresult` and `--infer-xcresult`.
- Combined Release artifact comparison with inferred result bundles:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label fresh-3p --compare-label warm-3p --compare-label max-10p-report --compare-label max-10p-older --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label release-memory-xctest-artifact-variance --summary-output /tmp/imposter-release-memory-xctest-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-release-memory-xctest-comparison.txt`.
  - RSS and gate rows matched the prior comparison: `max-10p-older` still reported `REPORT-FAIL` for final warm RSS `350.844 MB <= 340.000 MB`; the other compared warm gates passed.
  - XCTest comparison showed all four artifacts `Passed`, `Total 1`, `Failed 0`, on `iPhone 17 Pro`.
  - Focused test case durations: `fresh-3p 130.032s`, `warm-3p 115.966s`, `max-10p-report 189.064s`, `max-10p-older 198.554s`.
  - Xcode elapsed times: `fresh-3p 318.210s`, `warm-3p 135.925s`, `max-10p-report 232.876s`, `max-10p-older 204.276s`.
- Explicit result-bundle smoke:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --compare-label fresh-3p --compare-label warm-3p --compare-xcresult /tmp/imposter-ui-memory-probe-release-fresh.xcresult --compare-xcresult /tmp/imposter-ui-memory-probe-release-warm-repeat.xcresult --warm-rss-floor-mb 100 --run-label explicit-xcresult-smoke --summary-output /tmp/imposter-explicit-xcresult-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-explicit-xcresult-comparison.txt`.
  - XCTest comparison included `fresh-3p` and `warm-3p` as passed one-test artifacts with case durations `130.032s` and `115.966s`.
- Explicit result-bundle count guard:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --compare-xcresult /tmp/imposter-ui-memory-probe-release-fresh.xcresult`.
  - Exit code `2`.
  - Printed `--compare-xcresult count must match --compare-csv count`.
- Explicit/inferred conflict guard:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-fresh.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --compare-xcresult /tmp/imposter-ui-memory-probe-release-fresh.xcresult --compare-xcresult /tmp/imposter-ui-memory-probe-release-warm-repeat.xcresult --infer-xcresult`.
  - Exit code `2`.
  - Printed `--compare-xcresult and --infer-xcresult cannot be used together`.

### Remaining Risk
- The comparison helper now centralizes artifact evidence, but it still does not explain allocation families.
- `xcresulttool` JSON shape is verified against the current Xcode on this machine; if Apple changes the format, this script will need an update.
- Simulator-state labels still come from the command caller; the tool does not infer erased/warm state by itself.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.82/5
- UI automation: 4.75/5
- Performance: 3.78/5
- Release readiness: 3.18/5
- Repo clarity: 4.35/5

### Next Frontier
- Run another max-player Release report-gate probe and immediately compare it with `--infer-xcresult` to see whether the newer lower RSS max-player run repeats.
- Add optional comparison metadata columns for caller-provided simulator state and run labels, so artifact tables do not lose context when copied out of the ledger.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:28 PDT - Repeated max-player Release report-gate probe

### Baseline Issue Or Opportunity
- The newer max-player Release probe passed the tentative `380/340 MB` warm-start report gates, while the older max-player artifact missed the final RSS threshold.
- The latest frontier called for another max-player Release run, followed immediately by the new `--infer-xcresult` comparison mode, to see whether the lower max-player memory profile repeats.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No app or probe code changed in this loop.
- Reused `testMaximumPlayerRenderedFlowCompletesRound` as the max-player rendered Release memory lab.

### Implementation Notes
- XcodeBuildMCP `session_show_defaults` confirmed the `imposter-ui` profile before running another simulator test: project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
- Simulator state before the run was `Shutdown`; it was not erased after the comparison-helper work, so the label used was `warm-shutdown-no-erase-after-xctest-comparison`.
- The repeat used the same tentative `380 MB` warm-start peak and `340 MB` warm-start final thresholds in `--rss-gate-mode report`.

### Verification Commands And Exact Outcome
- Simulator/default checks:
  - `mcp__xcodebuildmcp__.session_show_defaults`
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`
  - Confirmed `iPhone 17 Pro (A113E399-3127-41CE-AB7E-B529DB41B3B6) (Shutdown)`.
- Max-player repeat command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label max-release-repeat-after-xctest-comparison --simulator-state warm-shutdown-no-erase-after-xctest-comparison --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-release-max-repeat.xcresult --output-csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Probe metadata recorded `First app sample delay: 24.450 seconds`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-release-max-repeat.summary.txt`.
  - CSV: `/tmp/imposter-ui-memory-probe-release-max-repeat.csv`, `166` lines including the header.
  - xcodebuild log: `/tmp/imposter-ui-memory-probe-release-max-repeat.xcodebuild.log`.
- Probe summary:
  - `Samples: 165`, `PIDs: 46730`, `First elapsed: 24.450 seconds`, `Last elapsed: 212.338 seconds`.
  - Raw RSS: `First RSS: 204.188 MB`, `Last RSS: 320.750 MB`, `Min RSS: 204.188 MB`, `Peak RSS: 350.859 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 165`, so raw and warm-start summaries matched.
- RSS gate summary:
  - `Mode: report`.
  - `Warm-start peak RSS: PASS (350.859 MB <= 380.000 MB)`.
  - `Warm-start final RSS: PASS (320.750 MB <= 340.000 MB)`.
- Direct result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-release-max-repeat.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-release-max-repeat.xcresult --format json`.
  - Exit code `0`; `testMaximumPlayerRenderedFlowCompletesRound()` passed in `191.548918s`.
  - xcodebuild log showed `212.082 elapsed -- Testing started completed`.
- Max-player comparison command:
  - `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label max-10p-report --compare-label max-10p-repeat --compare-label max-10p-older --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label max-release-repeat-variance --summary-output /tmp/imposter-max-release-repeat-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-max-release-repeat-comparison.txt`.
  - Compared with `max-10p-report`, the repeat was `+32.656 MB` peak RSS and `+24.094 MB` final RSS, but still passed both tentative gates.
  - Compared with the older max-player artifact, the repeat was `15.188 MB` lower peak RSS and `30.094 MB` lower final RSS.
  - XCTest comparison: all three artifacts passed one focused test on `iPhone 17 Pro`.
  - Focused test durations: `max-10p-report 189.064s`, `max-10p-repeat 191.549s`, `max-10p-older 198.554s`.
  - Xcode elapsed times: `max-10p-report 232.876s`, `max-10p-repeat 212.082s`, `max-10p-older 204.276s`.

### Remaining Risk
- The repeat supports the tentative `380/340 MB` report gate for max-player Release runs, but there are still only two newer max-player artifacts and one older miss.
- Simulator state remains a major confounder: first app sample RSS varied from `13.578 MB` to `204.188 MB` across the two newer max-player runs.
- RSS still does not attribute allocation families or prove physical-device behavior.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.82/5
- UI automation: 4.76/5
- Performance: 3.82/5
- Release readiness: 3.19/5
- Repo clarity: 4.35/5

### Next Frontier
- Add optional comparison metadata columns for caller-provided simulator state and run labels, so artifact tables preserve context outside the ledger.
- Decide whether to keep `380/340 MB` as a report-only max-player threshold after one more future run, not as a strict gate yet.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:31 PDT - Comparison metadata columns

### Baseline Issue Or Opportunity
- The comparison helper could now combine RSS, gate status, XCTest result, focused test duration, and xcodebuild elapsed time.
- However, copied comparison tables still lost the scenario context that explains simulator variance: per-artifact run label and simulator state.
- The latest frontier called for optional caller-provided metadata columns so comparison artifacts remain self-describing outside the ledger.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--compare-run-label`, repeated once per compared CSV.
- Added `--compare-simulator-state`, repeated once per compared CSV.
- Metadata columns are emitted only when their matching option is provided.

### Implementation Notes
- Added `ComparisonMetadata` to keep per-artifact metadata aligned by CSV order.
- Raw RSS, warm-start RSS, RSS gate, and XCTest result comparison tables now include `Run label` and/or `Simulator state` columns when requested.
- Count guards reject partially supplied metadata instead of guessing or shifting rows.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--compare-run-label` and `--compare-simulator-state`.
- Max-player comparison with both metadata columns:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label max-10p-report --compare-label max-10p-repeat --compare-label max-10p-older --compare-run-label max-release-report-gates-after-warm-repeat --compare-run-label max-release-repeat-after-xctest-comparison --compare-run-label legacy-max-release-baseline --compare-simulator-state warm-shutdown-no-erase-after-warm-repeat --compare-simulator-state warm-shutdown-no-erase-after-xctest-comparison --compare-simulator-state pre-metadata-artifact --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label max-release-repeat-variance-with-metadata --summary-output /tmp/imposter-max-release-repeat-comparison-metadata.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-max-release-repeat-comparison-metadata.txt`.
  - Raw, warm-start, RSS gate, and XCTest tables all included `Run label` and `Simulator state` columns.
  - The table still showed `max-10p-repeat` passing both warm gates at `350.859 MB` peak and `320.750 MB` final.
  - The table still showed `max-10p-older` as `REPORT-FAIL` for final warm RSS at `350.844 MB <= 340.000 MB`.
- Run-label count guard:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv --compare-run-label only-one-run-label`.
  - Exit code `2`.
  - Printed `--compare-run-label count must match --compare-csv count`.
- Simulator-state count guard:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv --compare-simulator-state only-one-state`.
  - Exit code `2`.
  - Printed `--compare-simulator-state count must match --compare-csv count`.
- Run-label-only smoke:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv --compare-label max-10p-report --compare-label max-10p-repeat --compare-run-label max-release-report-gates-after-warm-repeat --compare-run-label max-release-repeat-after-xctest-comparison --warm-rss-floor-mb 100 --summary-output /tmp/imposter-max-release-run-label-only-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-max-release-run-label-only-comparison.txt`.
  - Raw and warm-start tables included `Run label` without adding a `Simulator state` column.

### Remaining Risk
- Metadata values are still caller-supplied; older artifacts may need honest placeholders like `pre-metadata-artifact`.
- The comparison helper still compares RSS samples and XCTest artifacts, not allocation families.
- The tentative `380/340 MB` max-player threshold remains report-only.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.82/5
- UI automation: 4.76/5
- Performance: 3.84/5
- Release readiness: 3.2/5
- Repo clarity: 4.4/5

### Next Frontier
- Add an artifact manifest option that records CSV, summary, xcresult, xcodebuild log, run label, simulator state, focused test, and threshold policy as structured JSON for later comparison runs.
- Decide whether to keep `380/340 MB` as a report-only max-player threshold after one more future run, not as a strict gate yet.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:33 PDT - Probe artifact manifests

### Baseline Issue Or Opportunity
- Comparison tables could now preserve metadata, but callers still had to retype CSV paths, result bundle paths, run labels, simulator state, focused test names, and threshold policy.
- The latest frontier called for structured probe manifests so future comparison runs can start from artifact metadata rather than reconstructed command lines.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--manifest-output` for live probes and `--analyze-csv` summaries.
- Added `--compare-manifest` for comparing two or more JSON manifests.

### Implementation Notes
- Manifest schema: `imposter.ui_memory_probe_manifest`, `schema_version: 1`.
- Each manifest records artifact paths for CSV, summary, result bundle, and xcodebuild log when available.
- Each manifest records run metadata: label, simulator state, configuration, destination, focused test, and scheme.
- Each manifest records threshold policy: raw peak RSS threshold, warm floor, warm peak/final thresholds, and RSS gate mode.
- `--compare-manifest` expands manifests into comparison CSVs, run labels, simulator states, and explicit result bundles, then reuses the existing comparison path.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--manifest-output` and `--compare-manifest`.
- Manifest generation from prior max-player report artifact:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-max-report.csv --result-bundle /tmp/imposter-ui-memory-probe-release-max-report.xcresult --summary-output /tmp/imposter-ui-memory-probe-release-max-report.manifest-summary.txt --manifest-output /tmp/imposter-ui-memory-probe-release-max-report.manifest.json --run-label max-release-report-gates-after-warm-repeat --simulator-state warm-shutdown-no-erase-after-warm-repeat --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-release-max-report.manifest-summary.txt`.
  - Manifest artifact: `/tmp/imposter-ui-memory-probe-release-max-report.manifest.json`.
- Manifest generation from repeated max-player artifact:
  - Command: `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv --result-bundle /tmp/imposter-ui-memory-probe-release-max-repeat.xcresult --summary-output /tmp/imposter-ui-memory-probe-release-max-repeat.manifest-summary.txt --manifest-output /tmp/imposter-ui-memory-probe-release-max-repeat.manifest.json --run-label max-release-repeat-after-xctest-comparison --simulator-state warm-shutdown-no-erase-after-xctest-comparison --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-release-max-repeat.manifest-summary.txt`.
  - Manifest artifact: `/tmp/imposter-ui-memory-probe-release-max-repeat.manifest.json`.
- Manifest JSON inspection:
  - Command: `sed -n '1,220p' /tmp/imposter-ui-memory-probe-release-max-report.manifest.json`.
  - Exit code `0`.
  - Confirmed the manifest includes CSV, summary, result bundle, xcodebuild log, `Release` configuration, `ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound`, run label, simulator state, and `380/340 MB` report-threshold policy.
- Manifest comparison:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-release-max-report.manifest.json /tmp/imposter-ui-memory-probe-release-max-repeat.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label manifest-max-release-comparison --summary-output /tmp/imposter-manifest-max-release-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-manifest-max-release-comparison.txt`.
  - Output included metadata columns from the manifests, RSS gate comparison, and XCTest comparison.
  - Both max-player artifacts passed the `380/340 MB` report gates in this two-manifest comparison.
  - XCTest rows showed both artifacts `Passed`, `Total 1`, `Failed 0`; case durations were `189.064s` and `191.549s`.
- Conflict guard:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-release-max-report.manifest.json /tmp/imposter-ui-memory-probe-release-max-repeat.manifest.json --compare-csv /tmp/imposter-ui-memory-probe-release-max-report.csv`.
  - Exit code `2`.
  - Printed `--compare-manifest and --compare-csv cannot be used together`.

### Remaining Risk
- Existing manifests were generated from `--analyze-csv` rather than a fresh live probe; live-probe manifest writing is implemented but should be exercised on the next real probe.
- Manifests record caller-provided simulator state and threshold policy; they do not independently verify that state.
- Structured manifests make comparison replayable, but they still do not provide allocation attribution.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.83/5
- UI automation: 4.76/5
- Performance: 3.86/5
- Release readiness: 3.21/5
- Repo clarity: 4.45/5

### Next Frontier
- On the next live memory probe, pass `--manifest-output` directly and confirm live-probe manifest writing captures the generated CSV, summary, result bundle, and xcodebuild log.
- Decide whether to keep `380/340 MB` as a report-only max-player threshold after one more future run, not as a strict gate yet.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:35 PDT - Live-probe manifest smoke

### Baseline Issue Or Opportunity
- Probe manifests worked when generated from `--analyze-csv`, but the live-probe path still needed proof that it writes the generated CSV, summary, result bundle, and xcodebuild log into the manifest after an actual UI test run.
- The latest frontier called for a live memory probe with `--manifest-output`, then a manifest-based comparison using that fresh manifest.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No app or probe code changed in this loop.
- Reused `testLaunchShowsHomeScreen` as a short Release UI-test smoke for live manifest writing.

### Implementation Notes
- XcodeBuildMCP `session_show_defaults` confirmed the active `imposter-ui` profile before the simulator test: project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
- The live smoke used a low `220/220 MB` report threshold to prove live manifests preserve threshold policy and report-mode failures without failing the run.
- The subsequent manifest comparison intentionally used a looser `380/340 MB` report threshold so the launch-smoke artifact could be compared with a max-player artifact under the same report-gate table.

### Verification Commands And Exact Outcome
- Preflight:
  - `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py && git diff --check`.
  - Passed.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed `iPhone 17 Pro (A113E399-3127-41CE-AB7E-B529DB41B3B6) (Shutdown)`.
- Live manifest probe:
  - Command: `scripts/probe_ui_memory.py --replace --configuration Release --run-label live-manifest-launch-smoke --simulator-state warm-shutdown-no-erase-before-live-manifest-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-live-manifest-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-live-manifest-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-live-manifest-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 220 --max-warm-final-rss-mb 220 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `24.624 seconds`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-live-manifest-smoke.summary.txt`, `42` lines.
  - CSV artifact: `/tmp/imposter-ui-memory-probe-live-manifest-smoke.csv`, `8` lines including the header.
  - xcodebuild log: `/tmp/imposter-ui-memory-probe-live-manifest-smoke.xcodebuild.log`, `11` lines.
  - Manifest artifact: `/tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json`, `26` lines.
- Live probe RSS summary:
  - `Samples: 7`, `PIDs: 56129`, `First elapsed: 24.624 seconds`, `Last elapsed: 28.159 seconds`.
  - `First RSS: 16.984 MB`, `Last RSS: 288.859 MB`, `Peak RSS: 288.859 MB`.
  - Warm-start floor `1.000 MB` began at sample `1 of 7`.
  - Report gates intentionally printed `REPORT-FAIL` for `288.859 MB <= 220.000 MB` peak and final.
- Live manifest inspection:
  - Command: `sed -n '1,220p' /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json`.
  - Exit code `0`.
  - Confirmed `kind: live-probe`, CSV, summary, result bundle, xcodebuild log, `Release` configuration, destination, focused test `ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen`, run label, simulator state, and `220/220 MB` report-threshold policy.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-live-manifest-smoke.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-live-manifest-smoke.xcresult --format json`.
  - Exit code `0`; `testLaunchShowsHomeScreen()` passed in `4.703458s`.
- Manifest comparison using the live manifest:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json /tmp/imposter-ui-memory-probe-release-max-report.manifest.json --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label live-manifest-smoke-vs-max-report --summary-output /tmp/imposter-live-manifest-smoke-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-live-manifest-smoke-comparison.txt`.
  - Output included metadata columns recovered from both manifests, RSS gate comparison, and XCTest comparison.
  - XCTest table showed the live smoke `Passed`, `Total 1`, `Failed 0`, `Case s 4.703`, `Bundle s 27.741`, `Xcode elapsed s 24.301`, device `iPhone 17 Pro`.

### Remaining Risk
- The live manifest smoke used a launch test, not a full gameplay path; max-player manifest writing will still be re-exercised during the next long probe.
- `--compare-manifest` currently uses caller-supplied thresholds for the comparison command; the manifest threshold policy is recorded but not automatically applied as the comparison default.
- This remains RSS/process evidence, not allocation attribution or physical-device memory proof.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.83/5
- UI automation: 4.77/5
- Performance: 3.88/5
- Release readiness: 3.22/5
- Repo clarity: 4.48/5

### Next Frontier
- Teach `--compare-manifest` to optionally use the first manifest's threshold policy when explicit gate flags are omitted.
- Decide whether to keep `380/340 MB` as a report-only max-player threshold after one more future run, not as a strict gate yet.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.

## 2026-05-11 03:37 PDT - Manifest threshold policy defaults

### Baseline Issue Or Opportunity
- Live and analysis manifests now record threshold policy, but `--compare-manifest` still required callers to repeat gate flags manually.
- This weakened the manifest as a replay artifact because comparison behavior depended on remembering the original threshold policy outside the manifest.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- `--compare-manifest` now applies the first manifest's threshold policy when no explicit RSS gate flags are supplied.
- Explicit command-line gate flags still override the manifest policy.

### Implementation Notes
- Added helpers for detecting whether a manifest contains an RSS threshold policy.
- Added an explicit-gate detector so default manifest policy is only applied when the comparison command omitted RSS thresholds and `--rss-gate-mode`.
- The copied policy includes raw peak threshold, warm RSS floor, warm peak/final thresholds, and RSS gate mode.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- Manifest default policy from live smoke:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json /tmp/imposter-ui-memory-probe-release-max-report.manifest.json --run-label manifest-policy-default-smoke --summary-output /tmp/imposter-manifest-policy-default-smoke.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-manifest-policy-default-smoke.txt`.
  - The comparison automatically used the live smoke manifest policy: warm floor `1.000 MB`, peak threshold `220.000 MB`, final threshold `220.000 MB`, and report mode.
  - Gate rows showed `REPORT-FAIL` for both compared artifacts under the inherited `220/220 MB` policy.
- Manifest default policy from max-player report artifact:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-release-max-report.manifest.json /tmp/imposter-ui-memory-probe-release-max-repeat.manifest.json --run-label manifest-policy-default-max --summary-output /tmp/imposter-manifest-policy-default-max.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-manifest-policy-default-max.txt`.
  - The comparison automatically used the max-player manifest policy: warm floor `100.000 MB`, peak threshold `380.000 MB`, final threshold `340.000 MB`, and report mode.
  - Both max-player artifacts passed the inherited gates.
- Explicit override:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json /tmp/imposter-ui-memory-probe-release-max-report.manifest.json --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label manifest-policy-explicit-override --summary-output /tmp/imposter-manifest-policy-explicit-override.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-manifest-policy-explicit-override.txt`.
  - The comparison used the explicit `380/340 MB` thresholds instead of the live smoke manifest's stored `220/220 MB` thresholds; both artifacts passed.
- Partial explicit guard:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json /tmp/imposter-ui-memory-probe-release-max-report.manifest.json --max-warm-final-rss-mb 340`.
  - Exit code `2`.
  - Printed `--warm-rss-floor-mb is required when using warm RSS gates`, confirming partial explicit gate input is not silently filled from the manifest.

### Remaining Risk
- The default policy comes from the first manifest only; mixed-policy comparisons still require conscious ordering or explicit flags.
- Manifest threshold defaults improve replayability, but they still compare RSS samples rather than allocation families.
- The `220/220 MB` live smoke policy was intentionally low for report-mode proof and is not a release threshold.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.83/5
- UI automation: 4.77/5
- Performance: 3.89/5
- Release readiness: 3.23/5
- Repo clarity: 4.5/5

### Next Frontier
- Decide whether to keep `380/340 MB` as a report-only max-player threshold after one more future run, not as a strict gate yet.
- Continue seeking allocation attribution through a trace path that exports cleanly or targeted app-side memory instrumentation.
- Consider adding a manifest schema smoke fixture so manifest replay behavior can be tested without depending on `/tmp` artifacts.

## 2026-05-11 03:45 PDT - Footprint attribution smoke

### Baseline Issue Or Opportunity
- The memory probe had RSS, gates, manifests, and XCTest artifact comparison, but still lacked allocation-family evidence.
- The latest frontier called for moving from RSS-only numbers toward attribution through a trace path that exports cleanly.
- `vmmap -summary` looked promising but needed live evidence before being treated as a viable simulator path.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--vmmap-summary-dir`, `--vmmap-timeout-seconds`, and `--vmmap-peak-min-delta-mb`.
- Added `--footprint-summary-dir`, `--footprint-timeout-seconds`, and `--footprint-peak-min-delta-mb`.
- Live probes can now capture first-sample and peak-sample attribution snapshots.
- Probe manifests now include optional `vmmap_dir`, `vmmap_index`, `footprint_dir`, and `footprint_index` artifact paths.

### Implementation Notes
- `vmmap` snapshots write `first.vmmap-summary.txt`, `peak.vmmap-summary.txt`, and `vmmap-index.json`.
- `footprint` snapshots write `first.footprint-summary.txt`, `first.footprint.json`, `peak.footprint-summary.txt`, `peak.footprint.json`, and `footprint-index.json`.
- Peak snapshots are replaced only when RSS reaches a new peak, with an optional minimum delta guard.
- Snapshot failures are recorded in the index instead of hiding the attribution attempt.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents the vmmap and footprint capture flags.
- `git diff --check`
  - Passed before live attribution probes.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed `iPhone 17 Pro (A113E399-3127-41CE-AB7E-B529DB41B3B6) (Shutdown)`.

### vmmap Result
- Live vmmap smoke command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label vmmap-launch-smoke --simulator-state warm-shutdown-no-erase-before-vmmap-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-vmmap-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-vmmap-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-vmmap-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-vmmap-smoke.manifest.json --vmmap-summary-dir /tmp/imposter-ui-memory-probe-vmmap-smoke-vmmap --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`; UI test passed, but attribution failed.
  - `testLaunchShowsHomeScreen()` passed in `7.481347s`.
  - Probe captured only `1` RSS sample after a `135.463s` first app sample delay, showing this synchronous vmmap path is too disruptive for the short smoke.
  - `first.vmmap-summary.txt` recorded `Child vmmap process died with signal 10 Bus error`.
  - `peak.vmmap-summary.txt` recorded `vmmap cannot examine process 65004 ... because it no longer appears to be running`.
  - `vmmap-index.json` captured both failures with `returncode: 255`.

### footprint Result
- Live footprint smoke command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-launch-smoke --simulator-state warm-shutdown-no-erase-before-footprint-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-footprint-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-smoke.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-smoke-footprint --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `39.517 seconds`.
  - RSS samples: `7`; first RSS `105.156 MB`, peak RSS `285.031 MB`, final RSS `263.656 MB`.
  - Warm report gates passed: peak `285.031 MB <= 380.000 MB`, final `263.656 MB <= 340.000 MB`.
  - `testLaunchShowsHomeScreen()` passed in `9.678574s`.
  - xcodebuild log showed `42.272 elapsed -- Testing started completed`.
  - Summary artifact: `/tmp/imposter-ui-memory-probe-footprint-smoke.summary.txt`, `48` lines.
  - Manifest artifact: `/tmp/imposter-ui-memory-probe-footprint-smoke.manifest.json`, `30` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-smoke-footprint/footprint-index.json`, `26` lines.
  - Footprint peak JSON: `/tmp/imposter-ui-memory-probe-footprint-smoke-footprint/peak.footprint.json`, `5566` bytes.
- Peak footprint attribution:
  - Command: `jq -r '.processes[0].categories | to_entries | sort_by(-.value.dirty) | .[:8][] | "\(.key): dirty=\(.value.dirty) clean=\(.value.clean) swapped=\(.value.swapped) regions=\(.value.regions)"' /tmp/imposter-ui-memory-probe-footprint-smoke-footprint/peak.footprint.json`.
  - Exit code `0`.
  - Top dirty categories at the peak snapshot were `dyld private memory`, `MALLOC_SMALL`, `__DATA`, `__DATA_CONST`, `untagged (VM_ALLOCATE)`, `page table`, `CoreAnimation`, and `unused dyld shared cache area`.
  - `jq -r '.processes[0].name, .processes[0].pid, .processes[0].footprint, .processes[0].auxiliary.phys_footprint' .../peak.footprint.json` returned `Imposter`, PID `67791`, footprint `57362688`, and physical footprint `57395456`.
- Footprint guard checks:
  - `scripts/probe_ui_memory.py --result-bundle /tmp/unused.xcresult --output-csv /tmp/unused.csv --footprint-timeout-seconds 0`.
  - Exit code `2`; printed `--footprint-timeout-seconds must be greater than 0`.
  - `scripts/probe_ui_memory.py --result-bundle /tmp/unused.xcresult --output-csv /tmp/unused.csv --footprint-peak-min-delta-mb -1`.
  - Exit code `2`; printed `--footprint-peak-min-delta-mb cannot be negative`.
- Footprint manifest comparison:
  - Command: `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-footprint-smoke.manifest.json /tmp/imposter-ui-memory-probe-live-manifest-smoke.manifest.json --run-label footprint-manifest-smoke-comparison --summary-output /tmp/imposter-footprint-manifest-smoke-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-manifest-smoke-comparison.txt`.
  - The comparison replayed the footprint smoke and live-manifest smoke RSS/XCTest tables from manifests; both passed the inherited `380/340 MB` report gates from the first manifest.

### Remaining Risk
- `vmmap` is not a reliable live simulator attribution path in this smoke; it bus-errored and then missed the process.
- `footprint` worked on the launch smoke, but still needs to be exercised on a longer gameplay/max-player path before it becomes the preferred attribution gate.
- Footprint categories give allocation-family clues, not Swift object-level ownership or physical-device memory proof.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.83/5
- UI automation: 4.77/5
- Performance: 3.92/5
- Release readiness: 3.24/5
- Repo clarity: 4.52/5

### Next Frontier
- Run a longer Release gameplay or max-player probe with `--footprint-summary-dir` to confirm footprint attribution remains stable outside the launch smoke.
- Consider adding footprint category extraction to the probe summary so top dirty categories do not require a separate `jq` command.
- Treat `vmmap` as experimental until a non-crashing capture path is found.

## 2026-05-11 03:51 PDT - Gameplay footprint attribution probe

### Baseline Issue Or Opportunity
- The launch-smoke footprint probe proved `footprint` could capture process category evidence, but not whether it stayed stable during a longer gameplay UI path.
- The previous ledger also called out that top dirty categories required a separate `jq` command.
- The latest frontier was to run a longer Release gameplay probe with `--footprint-summary-dir` and make footprint category extraction part of the probe summary itself.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added footprint category parsing from captured `footprint` JSON.
- Added `--footprint-top-categories`, defaulting to `8`, to control how many top dirty categories are printed per captured snapshot.
- Added a guard for negative `--footprint-top-categories`.

### Implementation Notes
- Footprint summaries now print process name, PID, footprint, physical footprint, and the top dirty categories for each successful first/peak snapshot.
- This keeps the attribution signal inside the main probe summary instead of requiring a separate `jq` command.
- The long gameplay probe used `--footprint-peak-min-delta-mb 75`; this bounded capture overhead but means the recorded footprint peak snapshot can be below the absolute RSS peak if the final increase is smaller than the delta.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--footprint-top-categories`.
- `scripts/probe_ui_memory.py --result-bundle /tmp/unused.xcresult --output-csv /tmp/unused.csv --footprint-top-categories -1`
  - Exit code `2`; printed `--footprint-top-categories cannot be negative`.
- `git diff --check`
  - Passed before the long gameplay run.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Long gameplay footprint command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-release-gameplay-repeat --simulator-state warm-shutdown-no-erase-before-footprint-gameplay --only-testing ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds --result-bundle /tmp/imposter-ui-memory-probe-footprint-gameplay.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-gameplay.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-gameplay.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-gameplay.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-gameplay-footprint --footprint-peak-min-delta-mb 75 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `22.090 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-gameplay.csv`, `107` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-gameplay.summary.txt`, `68` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-gameplay.manifest.json`, `30` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-gameplay-footprint/footprint-index.json`, `26` lines.
  - Footprint JSON sizes: first `4296` bytes, peak `6059` bytes.
- RSS and gate summary:
  - `Samples: 106`, `PIDs: 70587`, first RSS `105.062 MB`, peak RSS `370.469 MB`, final RSS `342.375 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 106`.
  - Warm peak gate passed: `370.469 MB <= 380.000 MB`.
  - Warm final gate reported `REPORT-FAIL`: `342.375 MB <= 340.000 MB`.
- Footprint attribution:
  - First snapshot: elapsed `22.090s`, RSS `105.062 MB`, process footprint `12.814 MB`, physical `18.924 MB`.
  - Peak footprint snapshot: elapsed `47.809s`, RSS `352.688 MB`, process footprint `67.065 MB`, physical `67.096 MB`.
  - Top dirty categories at the captured peak: `MALLOC_SMALL 20.172 MB`, `dyld private memory 18.016 MB`, `__DATA 10.628 MB`, `__DATA_CONST 7.734 MB`, `untagged (VM_ALLOCATE) 3.469 MB`, `CoreAnimation 2.500 MB`, `page table 1.627 MB`, `unused dyld shared cache area 1.233 MB`.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-gameplay.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-gameplay.xcresult --format json`.
  - Exit code `0`; `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` passed in `115.153241s`.
  - xcodebuild log showed `133.176 elapsed -- Testing started completed`.
- Comparison against prior warm repeat:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-footprint-gameplay.csv /tmp/imposter-ui-memory-probe-release-warm-repeat.csv --compare-label footprint-gameplay --compare-label warm-repeat-baseline --compare-run-label footprint-release-gameplay-repeat --compare-run-label warm-release-repeat-after-metadata-smoke --compare-simulator-state warm-shutdown-no-erase-before-footprint-gameplay --compare-simulator-state warm-shutdown-no-erase-after-smoke --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label footprint-gameplay-vs-warm-repeat --summary-output /tmp/imposter-footprint-gameplay-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-gameplay-comparison.txt`.
  - Footprint gameplay vs warm repeat: peak RSS was `370.469 MB` vs `372.156 MB`; final RSS was `342.375 MB` vs `331.047 MB`.
  - XCTest comparison: both passed one focused test on `iPhone 17 Pro`; case durations were `115.153s` vs `115.966s`; Xcode elapsed was `133.176s` vs `135.925s`.

### Remaining Risk
- The footprint peak snapshot was taken at `352.688 MB` RSS, while the absolute sampled peak was `370.469 MB`; the `75 MB` delta protected runtime but missed the final small rise.
- Final RSS missed the tentative `340 MB` report threshold by `2.375 MB`, so `380/340 MB` should remain report-only.
- Footprint gives memory-family attribution, not Swift object ownership or device proof.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.78/5
- Performance: 3.95/5
- Release readiness: 3.25/5
- Repo clarity: 4.55/5

### Next Frontier
- Add a low-overhead way to capture a final footprint snapshot, or reduce the peak delta for one future run, so footprint attribution aligns more closely with the absolute RSS peak/final sample.
- Keep `380/340 MB` as report-only until final RSS variance stabilizes below the threshold.
- Consider a max-player footprint probe after the final/peak attribution gap is closed.

## 2026-05-11 03:57 PDT - Post-run final footprint attempt

### Baseline Issue Or Opportunity
- The previous gameplay footprint probe captured first and peak snapshots, but the peak footprint was taken at `352.688 MB` RSS while the absolute sampled RSS peak was `370.469 MB`.
- The latest frontier called for a low-overhead way to capture final attribution so footprint evidence better lines up with the final RSS sample.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--footprint-capture-final`.
- When enabled, the live probe attempts one final `footprint` capture from the last sampled app PID after xcodebuild exits.
- The final attempt is included in `footprint-index.json` and the probe summary whether it succeeds or fails.

### Implementation Notes
- This approach is intentionally low-overhead because it does not add more footprint calls during the active UI test.
- It tests whether the simulator app process remains inspectable after xcodebuild has finished.
- The final snapshot uses the last recorded RSS sample and PID, so a failure still documents whether post-run attribution is feasible.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--footprint-capture-final`.
- `git diff --check`
  - Passed before the live run.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Final-snapshot gameplay command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-final-release-gameplay-repeat --simulator-state warm-shutdown-no-erase-before-footprint-final-gameplay --only-testing ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-gameplay.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-final-gameplay.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-final-gameplay.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-final-gameplay.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-gameplay-footprint --footprint-peak-min-delta-mb 75 --footprint-capture-final --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `25.027 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-final-gameplay.csv`, `101` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-final-gameplay.summary.txt`, `69` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-final-gameplay.manifest.json`, `30` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-final-gameplay-footprint/footprint-index.json`, `36` lines.
- RSS and gate summary:
  - `Samples: 100`, `PIDs: 74502`, first RSS `107.406 MB`, peak RSS `380.156 MB`, final RSS `309.281 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 100`.
  - Warm peak gate reported `REPORT-FAIL`: `380.156 MB <= 380.000 MB`.
  - Warm final gate passed: `309.281 MB <= 340.000 MB`.
- Footprint attribution:
  - First snapshot: elapsed `25.027s`, RSS `107.406 MB`, process footprint `8.955 MB`, physical `23.893 MB`.
  - Peak footprint snapshot: elapsed `36.020s`, RSS `343.266 MB`, process footprint `62.752 MB`, physical `62.784 MB`.
  - Peak top dirty categories: `MALLOC_SMALL 18.688 MB`, `dyld private memory 17.562 MB`, `__DATA 10.523 MB`, `__DATA_CONST 7.537 MB`, `untagged (VM_ALLOCATE) 3.094 MB`, `page table 1.580 MB`, `unused dyld shared cache area 1.176 MB`, `CoreAnimation 1.000 MB`.
  - Final footprint attempt: failed with `returncode=66` at elapsed `140.326s`, RSS `309.281 MB`.
  - Failure text: `footprint: Unable to find pid for process matching '74502'` and `Unable to find any processes matching the supplied process names or pids`.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-final-gameplay.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-final-gameplay.xcresult --format json`.
  - Exit code `0`; `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` passed in `117.098472s`.
  - xcodebuild log showed `137.742 elapsed -- Testing started completed`.
- Comparison against prior footprint gameplay run:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-footprint-final-gameplay.csv /tmp/imposter-ui-memory-probe-footprint-gameplay.csv --compare-label footprint-final-gameplay --compare-label footprint-gameplay --compare-run-label footprint-final-release-gameplay-repeat --compare-run-label footprint-release-gameplay-repeat --compare-simulator-state warm-shutdown-no-erase-before-footprint-final-gameplay --compare-simulator-state warm-shutdown-no-erase-before-footprint-gameplay --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label footprint-final-vs-prior-gameplay --summary-output /tmp/imposter-footprint-final-gameplay-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-final-gameplay-comparison.txt`.
  - The final-snapshot run had higher peak RSS by `9.687 MB` and lower final RSS by `33.094 MB`.
  - Both focused tests passed on `iPhone 17 Pro`; case durations were `117.098s` vs `115.153s`; Xcode elapsed was `137.742s` vs `133.176s`.

### Remaining Risk
- Post-run final attribution is not viable for this UI-test path because the app PID is gone by the time the final `footprint` command runs.
- The absolute RSS peak was `380.156 MB`, but the captured footprint peak snapshot was at `343.266 MB`; the `75 MB` delta again missed the final rise.
- `380/340 MB` remains report-only: the prior run missed final by `2.375 MB`, while this run missed peak by `0.156 MB`.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.78/5
- Performance: 3.96/5
- Release readiness: 3.25/5
- Repo clarity: 4.56/5

### Next Frontier
- Replace post-run final capture with an in-run `latest` footprint snapshot captured on a low-frequency cadence, so the process is still alive and attribution lands closer to the final RSS sample.
- Keep `380/340 MB` as report-only until variance stabilizes.
- Consider a max-player footprint probe only after the latest/final attribution gap is closed.

## 2026-05-11 05:28 PDT - In-run latest footprint cadence

### Baseline Issue Or Opportunity
- The post-run final footprint attempt proved that final attribution is too late for this UI-test path: xcodebuild tears down the simulator app process before `footprint` can inspect the last sampled PID.
- The next useful probe shape is a low-frequency in-run `latest` snapshot that overwrites itself while the process is still alive, giving tail-adjacent attribution without capturing on every sample.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--footprint-latest-interval-seconds`.
- The option is disabled by default with `0.0`.
- When enabled with `--footprint-summary-dir`, the live probe updates `latest.footprint-summary.txt` and `latest.footprint.json` at the requested minimum elapsed-time interval.
- `footprint-index.json` and the printed summary now order footprint snapshots as `first`, `peak`, `latest`, then optional `final`.

### Implementation Notes
- The existing `first`, RSS-delta-based `peak`, and optional post-run `final` capture paths are unchanged.
- The latest snapshot uses the current live sample and PID, so it avoids the dead-PID failure seen with `--footprint-capture-final`.
- The cadence is intentionally low-frequency; this run used `30` seconds to keep attribution overhead bounded during the repeated gameplay flow.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--footprint-latest-interval-seconds`.
- `scripts/probe_ui_memory.py --result-bundle /tmp/unused.xcresult --output-csv /tmp/unused.csv --footprint-latest-interval-seconds -1`
  - Exit code `2`; printed `--footprint-latest-interval-seconds cannot be negative`.
- `git diff --check`
  - Passed before the live run.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Latest-cadence gameplay command:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-latest-release-gameplay-repeat --simulator-state warm-shutdown-no-erase-before-footprint-latest-gameplay --only-testing ImposterUITests/ImposterUITests/testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds --result-bundle /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-latest-gameplay-footprint --footprint-peak-min-delta-mb 75 --footprint-latest-interval-seconds 30 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `20.536 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-latest-gameplay.csv`, `101` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-latest-gameplay.summary.txt`, `79` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-latest-gameplay.manifest.json`, `30` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-latest-gameplay-footprint/footprint-index.json`, `36` lines.
  - Footprint JSON sizes: first `5073` bytes, peak `5472` bytes, latest `6444` bytes.
- RSS and gate summary:
  - `Samples: 100`, `PIDs: 21023`, first RSS `108.609 MB`, peak RSS `347.438 MB`, final RSS `315.719 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 100`.
  - Warm peak gate passed: `347.438 MB <= 380.000 MB`.
  - Warm final gate passed: `315.719 MB <= 340.000 MB`.
- Footprint attribution:
  - First snapshot: elapsed `20.536s`, RSS `108.609 MB`, process footprint `10.424 MB`, physical `10.471 MB`.
  - Peak snapshot: elapsed `21.718s`, RSS `273.562 MB`, process footprint `44.924 MB`, physical `45.830 MB`.
  - Latest snapshot: elapsed `112.565s`, RSS `324.578 MB`, process footprint `80.752 MB`, physical `80.784 MB`.
  - Latest top dirty categories: `MALLOC_SMALL 33.047 MB`, `dyld private memory 17.859 MB`, `__DATA 10.678 MB`, `__DATA_CONST 7.760 MB`, `CoreAnimation 5.172 MB`, `page table 1.627 MB`, `untagged (VM_ALLOCATE) 1.484 MB`, `unused dyld shared cache area 1.251 MB`.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.xcresult --format json`.
  - Exit code `0` on sequential rerun; `testRenderedHostedFlowRecordsRuntimeAcrossRepeatedRounds()` passed in `116.84776389598846s`.
  - xcodebuild log showed `134.179 elapsed -- Testing started completed`.
- Comparison against prior footprint gameplay runs:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-footprint-latest-gameplay.csv /tmp/imposter-ui-memory-probe-footprint-final-gameplay.csv /tmp/imposter-ui-memory-probe-footprint-gameplay.csv --compare-label footprint-latest-gameplay --compare-label footprint-final-gameplay --compare-label footprint-gameplay --compare-run-label footprint-latest-release-gameplay-repeat --compare-run-label footprint-final-release-gameplay-repeat --compare-run-label footprint-release-gameplay-repeat --compare-simulator-state warm-shutdown-no-erase-before-footprint-latest-gameplay --compare-simulator-state warm-shutdown-no-erase-before-footprint-final-gameplay --compare-simulator-state warm-shutdown-no-erase-before-footprint-gameplay --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label footprint-latest-vs-prior-gameplay --summary-output /tmp/imposter-footprint-latest-gameplay-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-latest-gameplay-comparison.txt`.
  - Latest run peak/final RSS was `347.438/315.719 MB`; prior final-attempt run was `380.156/309.281 MB`; prior first/peak footprint run was `370.469/342.375 MB`.
  - All three focused XCTest runs passed on `iPhone 17 Pro`; case durations were `116.848s`, `117.098s`, and `115.153s`.

### Remaining Risk
- The RSS-delta peak snapshot still missed the absolute sampled peak because the captured peak was `273.562 MB` and the run never exceeded that by the configured `75 MB` replacement delta.
- The latest snapshot is tail-adjacent, not mathematically final: it landed at `112.565s` while the last RSS sample was at `135.486s`.
- `380/340 MB` remains report-only until more Release gameplay runs show stable headroom.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.79/5
- Performance: 3.98/5
- Release readiness: 3.25/5
- Repo clarity: 4.57/5

### Next Frontier
- Run a max-player Release gameplay footprint probe with `--footprint-latest-interval-seconds 30` to see whether the improved attribution shape still holds under the largest supported pass-and-play game.
- Consider lowering `--footprint-peak-min-delta-mb` for one focused attribution run, because `75 MB` can skip late RSS rises that matter.
- Keep thresholds report-only until warm final RSS consistently lands under `340 MB` across multiple gameplay profiles.

## 2026-05-11 05:35 PDT - Max-player latest-footprint Release probe

### Baseline Issue Or Opportunity
- The previous loop proved that in-run `latest` footprint capture works on the repeated 3-player gameplay lab, but the ledger still needed the same attribution shape under the largest supported rendered flow.
- The current frontier explicitly called for a max-player Release gameplay footprint probe with `--footprint-latest-interval-seconds 30`.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No source tests changed in this loop.
- Reused `ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound` as the rendered 10-player stress lab.
- Added a new Release probe artifact set with RSS sampling, manifest metadata, and `first`/`peak`/`latest` footprint attribution.

### Implementation Notes
- This was an evidence/documentation loop, not an app-code loop.
- The probe exercised the already-rendered 10-player path through setup, role reveal, clue round, discussion, voting, reveal, and summary.
- The footprint cadence stayed at `30` seconds so it remained comparable with the latest 3-player gameplay footprint run.

### Verification Commands And Exact Outcome
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Max-player latest-footprint probe:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-latest-release-max-player --simulator-state warm-shutdown-no-erase-before-footprint-latest-max-player --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-footprint-latest-max.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-latest-max.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-latest-max.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-latest-max.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-latest-max-footprint --footprint-peak-min-delta-mb 75 --footprint-latest-interval-seconds 30 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `37.402 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-latest-max.csv`, `141` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-latest-max.summary.txt`, `79` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-latest-max.manifest.json`, `30` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-latest-max-footprint/footprint-index.json`, `36` lines.
  - Footprint JSON sizes: first `4299` bytes, peak `5515` bytes, latest `6050` bytes.
- RSS and gate summary:
  - `Samples: 140`, `PIDs: 34434`, first RSS `105.750 MB`, peak RSS `326.516 MB`, final RSS `258.188 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 140`.
  - Warm peak gate passed: `326.516 MB <= 380.000 MB`.
  - Warm final gate passed: `258.188 MB <= 340.000 MB`.
- Footprint attribution:
  - First snapshot: elapsed `37.402s`, RSS `105.750 MB`, process footprint `13.830 MB`, physical `19.689 MB`.
  - Peak snapshot: elapsed `38.801s`, RSS `282.859 MB`, process footprint `40.283 MB`, physical `42.221 MB`.
  - Latest snapshot: elapsed `220.402s`, RSS `225.141 MB`, process footprint `78.752 MB`, physical `78.784 MB`.
  - Latest top dirty categories: `MALLOC_SMALL 35.219 MB`, `dyld private memory 18.016 MB`, `__DATA 10.678 MB`, `__DATA_CONST 7.760 MB`, `page table 1.627 MB`, `untagged (VM_ALLOCATE) 1.594 MB`, `unused dyld shared cache area 1.251 MB`, `CoreAnimation 0.891 MB`.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-latest-max.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-latest-max.xcresult --format json`.
  - Exit code `0`; `testMaximumPlayerRenderedFlowCompletesRound()` passed in `194.76119303703308s`.
  - xcodebuild log showed `227.069 elapsed -- Testing started completed`.
- Comparison against prior max-player Release runs:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-footprint-latest-max.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label footprint-latest-max --compare-label max-10p-repeat --compare-label max-10p-report --compare-label max-10p-older --compare-run-label footprint-latest-release-max-player --compare-run-label max-release-repeat-after-xctest-comparison --compare-run-label max-release-report-gates-after-warm-repeat --compare-run-label legacy-max-release-baseline --compare-simulator-state warm-shutdown-no-erase-before-footprint-latest-max-player --compare-simulator-state warm-shutdown-no-erase-after-xctest-comparison --compare-simulator-state warm-shutdown-no-erase-after-warm-repeat --compare-simulator-state pre-metadata-artifact --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label footprint-latest-max-vs-prior-max --summary-output /tmp/imposter-footprint-latest-max-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-latest-max-comparison.txt`.
  - Latest-footprint max-player RSS was `326.516/258.188 MB` peak/final.
  - Prior max-player repeat RSS was `350.859/320.750 MB`; prior max-player report RSS was `318.203/296.656 MB`; older max-player baseline RSS was `366.047/350.844 MB`.
  - All four focused XCTest runs passed on `iPhone 17 Pro`; case durations were `194.761s`, `191.549s`, `189.064s`, and `198.554s`.
  - The older max-player baseline remains the only run in this comparison with a warm-final `REPORT-FAIL` against `340 MB`.

### Remaining Risk
- The `75 MB` peak replacement delta still captures an early footprint peak (`282.859 MB`) rather than the sampled RSS peak (`326.516 MB`).
- The 30-second latest cadence was useful but not mathematically final: latest landed at `220.402s` and `225.141 MB`, while the last sampled RSS was `229.612s` and `258.188 MB`.
- This is simulator-only evidence; physical-device memory and thermal behavior remain unproven.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.80/5
- Performance: 4.00/5
- Release readiness: 3.26/5
- Repo clarity: 4.58/5

### Next Frontier
- Run one focused attribution probe with a smaller `--footprint-peak-min-delta-mb` and shorter `--footprint-latest-interval-seconds` so captured footprint snapshots line up closer to sampled peak and final RSS.
- If that overhead is acceptable, consider changing the documented default probe recipe from `75/30` to a more accurate long-run cadence.
- Keep `380/340 MB` report-only until at least one tighter-attribution run confirms the apparent max-player headroom.

## 2026-05-11 05:42 PDT - Tighter max-player footprint attribution probe

### Baseline Issue Or Opportunity
- The previous max-player footprint run proved the `latest` capture path under 10-player load, but `75/30` still left attribution gaps: peak footprint was `282.859 MB` against sampled peak `326.516 MB`, and latest footprint landed `9.210s` before the final RSS sample.
- The current frontier called for a smaller peak delta and shorter latest cadence to see whether attribution could line up more closely without breaking the rendered max-player UI lab.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- No source tests changed in this loop.
- Reused `ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound` as the rendered 10-player stress lab.
- Added a tighter Release probe artifact set using `--footprint-peak-min-delta-mb 25` and `--footprint-latest-interval-seconds 10`.

### Implementation Notes
- This was an evidence/documentation loop; no app or probe code changed.
- The run intentionally increased footprint capture frequency to trade a small amount of wall/test time for better attribution alignment.
- The tighter recipe is useful enough for targeted diagnostics, but not yet proven as the default long-run recipe.

### Verification Commands And Exact Outcome
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Tighter max-player footprint probe:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-tight-release-max-player --simulator-state warm-shutdown-no-erase-before-footprint-tight-max-player --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-footprint-tight-max.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-tight-max.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-tight-max.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-tight-max.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-tight-max-footprint --footprint-peak-min-delta-mb 25 --footprint-latest-interval-seconds 10 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `34.703 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-tight-max.csv`, `149` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-tight-max.summary.txt`, `79` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-tight-max.manifest.json`, `30` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-tight-max-footprint/footprint-index.json`, `36` lines.
  - Footprint JSON sizes: first `5077` bytes, peak `5896` bytes, latest `6076` bytes.
- RSS and gate summary:
  - `Samples: 148`, `PIDs: 53015`, first RSS `165.359 MB`, peak RSS `344.016 MB`, final RSS `321.719 MB`.
  - Warm-start floor `100.000 MB` began at sample `1 of 148`.
  - Warm peak gate passed: `344.016 MB <= 380.000 MB`.
  - Warm final gate passed: `321.719 MB <= 340.000 MB`.
- Footprint attribution:
  - First snapshot: elapsed `34.703s`, RSS `165.359 MB`, process footprint `24.393 MB`, physical `25.611 MB`.
  - Peak snapshot: elapsed `45.878s`, RSS `341.219 MB`, process footprint `63.065 MB`, physical `63.096 MB`.
  - Latest snapshot: elapsed `228.831s`, RSS `314.938 MB`, process footprint `75.424 MB`, physical `75.471 MB`.
  - Latest top dirty categories: `MALLOC_SMALL 30.719 MB`, `dyld private memory 18.016 MB`, `__DATA 10.678 MB`, `__DATA_CONST 7.760 MB`, `untagged (VM_ALLOCATE) 1.875 MB`, `CoreAnimation 1.719 MB`, `page table 1.643 MB`, `unused dyld shared cache area 1.251 MB`.
- Attribution alignment:
  - Peak footprint RSS was only `2.797 MB` below sampled peak RSS (`341.219 MB` vs `344.016 MB`), much closer than the `75 MB` recipe's `43.657 MB` gap from the previous max-player run.
  - Latest footprint elapsed was `6.752s` before the final sample (`228.831s` vs `235.583s`), better than the previous max-player run's `9.210s` gap.
  - Latest footprint RSS was `6.781 MB` below final RSS (`314.938 MB` vs `321.719 MB`), much closer than the previous max-player run's `33.047 MB` latest/final RSS gap.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-tight-max.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-tight-max.xcresult --format json`.
  - Exit code `0`; `testMaximumPlayerRenderedFlowCompletesRound()` passed in `204.61659502983093s`.
  - xcodebuild log showed `232.318 elapsed -- Testing started completed`.
- Comparison against max-player history:
  - Command: `scripts/probe_ui_memory.py --compare-csv /tmp/imposter-ui-memory-probe-footprint-tight-max.csv /tmp/imposter-ui-memory-probe-footprint-latest-max.csv /tmp/imposter-ui-memory-probe-release-max-repeat.csv /tmp/imposter-ui-memory-probe-release-max-report.csv /tmp/imposter-ui-memory-probe-release-max.csv --compare-label footprint-tight-max --compare-label footprint-latest-max --compare-label max-10p-repeat --compare-label max-10p-report --compare-label max-10p-older --compare-run-label footprint-tight-release-max-player --compare-run-label footprint-latest-release-max-player --compare-run-label max-release-repeat-after-xctest-comparison --compare-run-label max-release-report-gates-after-warm-repeat --compare-run-label legacy-max-release-baseline --compare-simulator-state warm-shutdown-no-erase-before-footprint-tight-max-player --compare-simulator-state warm-shutdown-no-erase-before-footprint-latest-max-player --compare-simulator-state warm-shutdown-no-erase-after-xctest-comparison --compare-simulator-state warm-shutdown-no-erase-after-warm-repeat --compare-simulator-state pre-metadata-artifact --infer-xcresult --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report --run-label footprint-tight-max-vs-prior-max --summary-output /tmp/imposter-footprint-tight-max-comparison.txt`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-tight-max-comparison.txt`.
  - Tight max-player RSS was `344.016/321.719 MB` peak/final.
  - Prior latest-footprint max-player RSS was `326.516/258.188 MB`; prior max-player repeat RSS was `350.859/320.750 MB`; prior max-player report RSS was `318.203/296.656 MB`; older max-player baseline RSS was `366.047/350.844 MB`.
  - All five focused XCTest runs passed on `iPhone 17 Pro`; case durations were `204.617s`, `194.761s`, `191.549s`, `189.064s`, and `198.554s`.
  - The tight run added `9.855s` of case time versus the `75/30` latest-footprint max-player run while preserving both report gates.

### Remaining Risk
- `25/10` is more accurate but measurably heavier; this one run does not prove it should be the default cadence for every long probe.
- Even the tight latest snapshot is not mathematically final; it remained `6.752s` and `6.781 MB` away from the last sample.
- Simulator-only evidence still cannot prove physical-device thermal or memory behavior.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.80/5
- Performance: 4.02/5
- Release readiness: 3.27/5
- Repo clarity: 4.58/5

### Next Frontier
- Teach `scripts/probe_ui_memory.py` to report footprint alignment metrics directly: peak snapshot RSS delta from sampled peak, latest snapshot elapsed delta from final sample, and latest snapshot RSS delta from final sample.
- Add those alignment fields to summaries or manifests so future attribution runs do not depend on hand-calculated ledger math.
- Keep `25/10` as the targeted diagnostic recipe and `75/30` as the lower-overhead long-run recipe until the script can show alignment/cost tradeoffs automatically.

## 2026-05-11 05:45 PDT - Footprint alignment metrics in probe summaries

### Baseline Issue Or Opportunity
- The tight max-player attribution run required hand-calculated math in the ledger to explain whether `peak` and `latest` footprint snapshots aligned with sampled peak/final RSS.
- The previous frontier called for `scripts/probe_ui_memory.py` to report those alignment fields directly so future attribution runs are self-explaining.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `footprint_alignment_lines(...)`.
- Live footprint summaries now include:
  - peak snapshot RSS delta from sampled peak RSS.
  - peak snapshot elapsed delta from sampled peak.
  - latest snapshot elapsed delta from the final sample.
  - latest snapshot RSS delta from final RSS.
- `--analyze-csv` can now read an existing `--footprint-summary-dir` by loading `footprint-index.json`, so saved probe artifacts can be re-summarized with the new alignment section.
- Analyze mode now rejects negative `--footprint-top-categories` and missing footprint indexes with explicit exit-code `2` errors.

### Implementation Notes
- The footprint index reader validates the `imposter.footprint_summary_index` schema and reconstructs `FootprintSnapshot` records from saved artifact paths.
- The manifest writer now carries `footprint_dir` and `footprint_index` for CSV-analysis manifests when a footprint directory is supplied.
- CSV-only analysis without `--footprint-summary-dir` is unchanged.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents that `--footprint-summary-dir` can be used by live probes and CSV analysis.
- `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-tight-max.csv --footprint-top-categories -1`
  - Exit code `2`; printed `--footprint-top-categories cannot be negative`.
- `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-tight-max.csv --footprint-summary-dir /tmp/does-not-have-footprint-index`
  - Exit code `2`; printed `footprint index not found: /private/tmp/does-not-have-footprint-index/footprint-index.json`.
- `git diff --check`
  - Passed after the script change.
- Saved-artifact re-analysis:
  - `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-tight-max.csv --result-bundle /tmp/imposter-ui-memory-probe-footprint-tight-max.xcresult --run-label footprint-tight-max-alignment-reanalysis --simulator-state warm-shutdown-no-erase-before-footprint-tight-max-player --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-tight-max-footprint --summary-output /tmp/imposter-footprint-tight-max-reanalysis-alignment.txt --manifest-output /tmp/imposter-footprint-tight-max-reanalysis-alignment.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Summary artifact: `/tmp/imposter-footprint-tight-max-reanalysis-alignment.txt`.
  - Manifest artifact: `/tmp/imposter-footprint-tight-max-reanalysis-alignment.manifest.json`.
  - Manifest includes CSV, summary, result bundle, xcodebuild log, footprint directory, footprint index, focused test, Release configuration, run label, simulator state, and `380/340 MB` report-threshold policy.
- Alignment output from the re-analysis:
  - `peak vs sampled peak: snapshot_rss=341.219 MB, sampled_peak_rss=344.016 MB, rss_delta=+2.797 MB, elapsed_delta=+87.789s`.
  - `latest vs final sample: snapshot_elapsed=228.831s, final_elapsed=235.583s, elapsed_delta=+6.752s, snapshot_rss=314.938 MB, final_rss=321.719 MB, rss_delta=+6.781 MB`.

### Remaining Risk
- The new peak alignment line makes a useful RSS comparison, but it also exposed that the RSS-matched peak snapshot can be temporally far from the sampled peak.
- Alignment metrics are summary/manifest-adjacent, not structured manifest fields yet.
- Existing old summaries do not gain the alignment section unless re-analyzed with `--analyze-csv --footprint-summary-dir`.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.80/5
- Performance: 4.03/5
- Release readiness: 3.27/5
- Repo clarity: 4.60/5

### Next Frontier
- Add structured alignment fields to the probe manifest so comparison mode can table RSS/elapsed alignment across runs without scraping summary text.
- Consider a `sampled_peak` footprint label or nearest-to-peak capture policy if temporal peak attribution matters more than low-overhead cadence.
- Keep using `--analyze-csv --footprint-summary-dir` to refresh old footprint summaries when attribution math changes.

## 2026-05-11 05:51 PDT - Structured footprint alignment manifest comparison

### Baseline Issue Or Opportunity
- The previous loop printed footprint alignment metrics in summaries, but comparison mode still could not table alignment across runs from structured data.
- The current frontier called for manifest-level alignment fields so `--compare-manifest` can compare attribution quality without scraping summary text.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added structured `footprint_alignment` data to live-probe and CSV-analysis manifests when footprint snapshots are available.
- Added `Footprint alignment comparison` to manifest-driven comparison output.
- The new comparison table reports:
  - peak RSS delta from sampled peak RSS.
  - peak elapsed delta from sampled peak.
  - latest RSS delta from final RSS.
  - latest elapsed delta from final sample.

### Implementation Notes
- `footprint_alignment(...)` now computes a reusable structured payload, and `footprint_alignment_lines(...)` formats that payload for text summaries.
- `apply_compare_manifests(...)` carries each manifest's alignment payload into comparison mode.
- Plain `--compare-csv` behavior is unchanged; the alignment table appears only when manifest inputs provide alignment data.
- An initial verification attempt caught a `NameError` in CSV-analysis manifest writing; the analyzer printed the summary but crashed before writing the manifest. The fix now defines `footprint_alignment_data` in the analyze path before manifest creation.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed after the structured-manifest change.
- `git diff --check`
  - Passed after the structured-manifest change.
- Structured re-analysis manifest for the tight max-player run:
  - `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-tight-max.csv --result-bundle /tmp/imposter-ui-memory-probe-footprint-tight-max.xcresult --run-label footprint-tight-max-structured-alignment --simulator-state warm-shutdown-no-erase-before-footprint-tight-max-player --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-tight-max-footprint --summary-output /tmp/imposter-footprint-tight-max-structured-alignment.txt --manifest-output /tmp/imposter-footprint-tight-max-structured-alignment.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-tight-max-structured-alignment.txt`.
  - Wrote `/tmp/imposter-footprint-tight-max-structured-alignment.manifest.json`.
- Structured re-analysis manifest for the lower-overhead latest max-player run:
  - `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-latest-max.csv --result-bundle /tmp/imposter-ui-memory-probe-footprint-latest-max.xcresult --run-label footprint-latest-max-structured-alignment --simulator-state warm-shutdown-no-erase-before-footprint-latest-max-player --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-latest-max-footprint --summary-output /tmp/imposter-footprint-latest-max-structured-alignment.txt --manifest-output /tmp/imposter-footprint-latest-max-structured-alignment.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-latest-max-structured-alignment.txt`.
  - Wrote `/tmp/imposter-footprint-latest-max-structured-alignment.manifest.json`.
- Manifest field verification:
  - `rg -n "footprint_alignment|peak_vs_sampled_peak|latest_vs_final_sample|rss_delta_mb|elapsed_delta_seconds" /tmp/imposter-footprint-tight-max-structured-alignment.manifest.json /tmp/imposter-footprint-latest-max-structured-alignment.manifest.json`.
  - Exit code `0`.
  - Tight manifest includes `peak_vs_sampled_peak.rss_delta_mb=2.7972500000000196` and `latest_vs_final_sample.rss_delta_mb=6.781499999999994`.
  - Lower-overhead manifest includes `peak_vs_sampled_peak.rss_delta_mb=43.65662500000002` and `latest_vs_final_sample.rss_delta_mb=33.04737499999999`.
- Structured manifest comparison:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-footprint-tight-max-structured-alignment.manifest.json /tmp/imposter-footprint-latest-max-structured-alignment.manifest.json --run-label footprint-structured-alignment-comparison --summary-output /tmp/imposter-footprint-structured-alignment-comparison.txt`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-structured-alignment-comparison.txt`.
  - Output included a `Footprint alignment comparison` table.
  - Tight run row: peak RSS delta `+2.797 MB`, peak elapsed delta `+87.789s`, latest RSS delta `+6.781 MB`, latest elapsed delta `+6.752s`.
  - Lower-overhead row: peak RSS delta `+43.657 MB`, peak elapsed delta `+85.631s`, latest RSS delta `+33.047 MB`, latest elapsed delta `+9.210s`.
  - The same comparison confirmed both focused max-player XCTest runs passed on `iPhone 17 Pro`; tight case duration `204.617s`, lower-overhead case duration `194.761s`.

### Remaining Risk
- The manifest now structures alignment deltas, but it does not yet structure the raw snapshot/sample pair fields in the comparison table.
- The peak elapsed deltas remain large for both recipes, which suggests RSS-magnitude alignment and temporal attribution are separate concerns.
- Older manifests need re-analysis before they can participate in the alignment table.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.80/5
- Performance: 4.04/5
- Release readiness: 3.28/5
- Repo clarity: 4.62/5

### Next Frontier
- Add a `sampled_peak` or `nearest_to_sampled_peak` footprint capture policy for temporal peak attribution, since lower RSS delta alone can still point to an early moment.
- Extend manifest comparison to include optional raw alignment endpoints if the table needs more diagnostic depth.
- Re-analyze older footprint manifests only when they matter for a new comparison, rather than bulk-refreshing all artifacts.

## 2026-05-11 05:59 PDT - Sampled-peak footprint capture policy

### Baseline Issue Or Opportunity
- The structured alignment comparison made the problem explicit: the delta-based `peak` footprint can be close in RSS magnitude while still far from the sampled peak time.
- The current frontier called for a `sampled_peak` or nearest-to-sampled-peak capture policy for temporal peak attribution.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--footprint-capture-sampled-peak`.
- When enabled with `--footprint-summary-dir`, the live probe updates `sampled_peak.footprint-summary.txt` and `sampled_peak.footprint.json` whenever a sample sets a new run-high RSS.
- Footprint indexes now order snapshots as `first`, `peak`, `sampled_peak`, `latest`, then optional `final`.
- Alignment summaries and manifest comparison now include sampled-peak RSS/elapsed deltas when the label is present.

### Implementation Notes
- This is intentionally opt-in because it can perform more in-run `footprint` captures than the lower-overhead `peak` and `latest` recipe.
- The existing delta-based `peak` snapshot remains useful for low-overhead attribution, while `sampled_peak` is the temporal peak diagnostic.
- Plain comparison with older manifests remains backward compatible; sampled-peak columns show `n/a` when old manifests lack the new label.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed before the live run.
- `scripts/probe_ui_memory.py --help`
  - Passed and now documents `--footprint-capture-sampled-peak`.
- Backward-compatible manifest comparison:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-footprint-tight-max-structured-alignment.manifest.json /tmp/imposter-footprint-latest-max-structured-alignment.manifest.json --run-label footprint-sampled-peak-column-backcompat --summary-output /tmp/imposter-footprint-sampled-peak-column-backcompat.txt`.
  - Exit code `0`.
  - Output kept the existing alignment rows and showed sampled-peak columns as `n/a` for older manifests.
- `git diff --check`
  - Passed before the live run.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Sampled-peak max-player Release probe:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-sampled-peak-release-max-player --simulator-state warm-shutdown-no-erase-before-footprint-sampled-peak-max-player --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max-footprint --footprint-peak-min-delta-mb 75 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 30 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `24.603 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.csv`, `167` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.summary.txt`, `94` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.manifest.json`, `56` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-max-footprint/footprint-index.json`, `46` lines.
  - Footprint JSON sizes: first `3512` bytes, peak `5894` bytes, sampled_peak `6075` bytes, latest `6024` bytes.
- RSS and gate summary:
  - `Samples: 166`, `PIDs: 69469`, first RSS `17.969 MB`, peak RSS `378.703 MB`, final RSS `351.203 MB`.
  - Warm-start floor `100.000 MB` began at sample `2 of 166`.
  - Warm peak gate passed: `378.703 MB <= 380.000 MB`.
  - Warm final gate reported `REPORT-FAIL`: `351.203 MB <= 340.000 MB`.
- Footprint attribution:
  - First snapshot: elapsed `24.603s`, RSS `17.969 MB`, process footprint `1.673 MB`, physical `1.673 MB`.
  - Delta-based peak snapshot: elapsed `35.769s`, RSS `342.438 MB`, process footprint `62.893 MB`, physical `62.924 MB`.
  - Sampled-peak snapshot: elapsed `102.587s`, RSS `378.703 MB`, process footprint `81.456 MB`, physical `81.487 MB`.
  - Latest snapshot: elapsed `178.047s`, RSS `346.000 MB`, process footprint `85.831 MB`, physical `85.862 MB`.
  - Sampled-peak top dirty categories: `MALLOC_SMALL 25.812 MB`, `dyld private memory 18.016 MB`, `CoreAnimation 12.703 MB`, `__DATA 10.678 MB`, `__DATA_CONST 7.760 MB`, `untagged (VM_ALLOCATE) 1.969 MB`, `page table 1.643 MB`, `unused dyld shared cache area 1.251 MB`.
- Alignment output:
  - Delta-based peak vs sampled peak: RSS delta `+36.266 MB`, elapsed delta `+66.818s`.
  - Sampled peak vs sampled peak: RSS delta `+0.000 MB`, elapsed delta `+0.000s`.
  - Latest vs final sample: RSS delta `+5.203 MB`, elapsed delta `+24.389s`.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.xcresult --format json`.
  - Exit code `0`; `testMaximumPlayerRenderedFlowCompletesRound()` passed in `179.3681629896164s`.
  - xcodebuild log showed `197.095 elapsed -- Testing started completed`.
- Structured comparison against prior max-player footprint runs:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.manifest.json /tmp/imposter-footprint-tight-max-structured-alignment.manifest.json /tmp/imposter-footprint-latest-max-structured-alignment.manifest.json --run-label footprint-sampled-peak-vs-prior-max --summary-output /tmp/imposter-footprint-sampled-peak-max-comparison.txt`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-sampled-peak-max-comparison.txt`.
  - Alignment table showed sampled-peak row with `Sampled peak RSS delta MB +0.000` and `Sampled peak elapsed delta s +0.000`.
  - The same comparison showed the sampled-peak run was the only run with a warm-final `REPORT-FAIL` in the three-run comparison.

### Remaining Risk
- `--footprint-capture-sampled-peak` proved exact temporal peak attribution, but this run had higher sampled peak/final RSS than the two prior max-player footprint runs.
- The final RSS report miss reinforces that `380/340 MB` must remain report-only.
- The policy captures a new footprint for each observed run-high RSS, so overhead could vary based on how jagged RSS growth is in a given run.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.81/5
- Performance: 4.05/5
- Release readiness: 3.28/5
- Repo clarity: 4.63/5

### Next Frontier
- Add a capture-count/overhead summary for footprint snapshots so each run reports how many `footprint` captures were performed and how much time they added.
- Keep `--footprint-capture-sampled-peak` as a targeted diagnostic rather than the default recipe until overhead is measured directly.
- Consider a final-cadence policy separate from sampled peak if final RSS attribution continues to vary near the report threshold.

## 2026-05-11 06:06 PDT - Footprint capture overhead accounting

### Baseline Issue Or Opportunity
- The sampled-peak policy proved exact temporal peak attribution, but the probe still did not report how many `footprint` captures ran or how much wall time they consumed.
- The current frontier called for capture-count and overhead reporting so sampled peak can remain a targeted diagnostic until its cost is measured directly.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- `FootprintSnapshot` now records `duration_seconds`.
- `footprint-index.json` now persists `duration_seconds` per snapshot.
- Footprint summaries now include a `footprint capture overhead` block with attempts, successes, failures, known durations, total duration, mean duration, and max duration.
- Each snapshot summary line now includes its capture duration.
- Manifests now include `footprint_capture_overhead` when footprint snapshots exist.
- Manifest comparison now includes a `Footprint capture overhead comparison` table.

### Implementation Notes
- Older footprint indexes remain readable; their snapshots report `duration=n/a` and `known durations: 0`.
- The overhead table is intentionally manifest-driven, like the alignment table.
- Delta formatting now normalizes tiny values to `+0.000` instead of `-0.000` when old CSV rounding creates microscopic negative values.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Passed before and after the live proof.
- `git diff --check`
  - Passed before and after the live proof.
- Legacy sampled-peak artifact re-analysis:
  - `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.csv --result-bundle /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.xcresult --run-label footprint-sampled-peak-overhead-legacy-reanalysis --simulator-state warm-shutdown-no-erase-before-footprint-sampled-peak-max-player --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max-footprint --summary-output /tmp/imposter-footprint-sampled-peak-overhead-legacy-reanalysis.txt --manifest-output /tmp/imposter-footprint-sampled-peak-overhead-legacy-reanalysis.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Summary reported attempts `4`, successes `4`, failures `0`, known durations `0`, total/mean/max duration `n/a`.
  - Manifest artifact: `/tmp/imposter-footprint-sampled-peak-overhead-legacy-reanalysis.manifest.json`.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
  - `xcrun simctl list devices | rg 'A113E399|iPhone 17 Pro'`.
  - Confirmed the target simulator was `Shutdown`.
- Live overhead launch smoke:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-overhead-launch-smoke --simulator-state warm-shutdown-no-erase-before-footprint-overhead-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-overhead-smoke-footprint --footprint-peak-min-delta-mb 25 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 2 --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `24.475 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-overhead-smoke.csv`, `7` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-overhead-smoke.summary.txt`, `102` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json`, `65` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-overhead-smoke-footprint/footprint-index.json`, `50` lines.
- Live overhead result:
  - `Samples: 6`, `PIDs: 77051`, first RSS `102.797 MB`, peak RSS `288.281 MB`, final RSS `273.031 MB`.
  - Warm peak gate passed: `288.281 MB <= 380.000 MB`.
  - Warm final gate passed: `273.031 MB <= 340.000 MB`.
  - Footprint captures: attempts `4`, successes `4`, failures `0`, known durations `4`.
  - Total capture duration `0.164s`, mean `0.041s`, max `0.042s`.
  - Snapshot durations: first `0.039s`, peak `0.041s`, sampled_peak `0.041s`, latest `0.042s`.
  - Alignment: peak and sampled_peak both matched sampled peak at `+0.000 MB`, `+0.000s`; latest was `+0.047 MB` and `+0.597s` from final sample.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.xcresult --format json`.
  - Exit code `0`; `testLaunchShowsHomeScreen()` passed in `4.747704029083252s`.
  - xcodebuild log showed `22.750 elapsed -- Testing started completed`.
- Manifest field verification:
  - `rg -n "footprint_capture_overhead|duration_seconds|attempt_count|total_duration_seconds|known_duration_count" /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json /tmp/imposter-ui-memory-probe-footprint-overhead-smoke-footprint/footprint-index.json`.
  - Exit code `0`.
  - Confirmed manifest `attempt_count=4`, `known_duration_count=4`, `total_duration_seconds=0.16399812602321617`.
  - Confirmed each footprint-index snapshot includes `duration_seconds`.
- Structured overhead comparison:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json /tmp/imposter-footprint-sampled-peak-overhead-legacy-reanalysis.manifest.json --run-label footprint-overhead-structured-vs-legacy --summary-output /tmp/imposter-footprint-overhead-comparison.txt`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-overhead-comparison.txt`.
  - Output included `Footprint capture overhead comparison`.
  - Fresh smoke row: attempts `4`, successes `4`, failures `0`, known durations `4`, total `0.164s`, mean `0.041s`, max `0.042s`.
  - Legacy reanalysis row: attempts `4`, successes `4`, failures `0`, known durations `0`, total/mean/max `n/a`.

### Remaining Risk
- The overhead proof used the short launch smoke, not a full max-player run; long-run sampled-peak overhead can still vary with RSS jaggedness.
- Capture duration measures host-side `footprint` command wall time, not all secondary perturbation a capture might cause inside the simulator process.
- The report threshold remains exploratory; the previous sampled-peak max-player run still missed final RSS.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.81/5
- Performance: 4.06/5
- Release readiness: 3.28/5
- Repo clarity: 4.64/5

### Next Frontier
- Run one max-player sampled-peak probe with overhead accounting when time allows, so the diagnostic policy has cost data on the path where it will actually be used.
- Consider adding a final-cadence capture policy if final RSS attribution continues to vary near the report threshold.
- Keep `--footprint-capture-sampled-peak` opt-in until max-player overhead is measured directly.

## 2026-05-11 06:45 PDT - Max-player sampled-peak overhead proof

### Baseline Issue Or Opportunity
- The previous overhead proof used the short launch smoke; the real question was whether sampled-peak footprint capture remains cheap during the long max-player UI flow where peak and final attribution matter.
- The current frontier explicitly called for one max-player sampled-peak probe with overhead accounting before changing the diagnostic policy.

### Files Changed
- `docs/FRONTIER_LEDGER.md`

### Verification Commands And Exact Outcome
- Live max-player sampled-peak overhead run:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-sampled-peak-overhead-release-max-player --simulator-state warm-shutdown-no-erase-before-footprint-sampled-peak-overhead-max-player --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max-footprint --footprint-peak-min-delta-mb 75 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 30 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - First app sample delay: `21.653 seconds`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.csv`, `162` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.summary.txt`, `102` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.manifest.json`, `65` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max-footprint/footprint-index.json`, `50` lines.
- Live max-player result:
  - `Samples: 161`, `PIDs: 79007`, first RSS `108.484 MB`, peak RSS `353.047 MB`, final RSS `341.703 MB`.
  - Warm peak gate passed: `353.047 MB <= 380.000 MB`.
  - Warm final gate reported failure in report mode: `341.703 MB <= 340.000 MB`.
  - Footprint captures: attempts `4`, successes `4`, failures `0`, known durations `4`.
  - Total capture duration `0.195s`, mean `0.049s`, max `0.055s`.
  - Snapshot durations: first `0.039s`, peak `0.051s`, sampled_peak `0.049s`, latest `0.055s`.
  - Alignment: peak and sampled_peak both matched sampled peak at `+0.000 MB`, `+0.000s`; latest was `+4.984 MB` and `+25.705s` from final sample.
- Result-bundle verification:
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results summary --path /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.xcresult --format json`.
  - Exit code `0`; `result: Passed`, `totalTestCount: 1`, `passedTests: 1`, `failedTests: 0`, `skippedTests: 0`.
  - `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcresulttool get test-results tests --path /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.xcresult --format json`.
  - Exit code `0`; `testMaximumPlayerRenderedFlowCompletesRound()` passed in `181.62081801891327s`.
  - xcodebuild log showed `199.992 elapsed -- Testing started completed`.
- Manifest and index field verification:
  - `rg -n "footprint_capture_overhead|duration_seconds|attempt_count|known_duration_count|total_duration_seconds|sampled_peak_vs_sampled_peak" /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.manifest.json /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max-footprint/footprint-index.json`.
  - Exit code `0`.
  - Confirmed manifest `attempt_count=4`, `known_duration_count=4`, `total_duration_seconds=0.19519925100030378`.
  - Confirmed each footprint-index snapshot includes `duration_seconds`.
- Structured max-player comparison:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.manifest.json /tmp/imposter-ui-memory-probe-footprint-sampled-peak-max.manifest.json /tmp/imposter-footprint-tight-max-structured-alignment.manifest.json /tmp/imposter-footprint-latest-max-structured-alignment.manifest.json /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json --run-label footprint-sampled-peak-overhead-max-comparison --summary-output /tmp/imposter-footprint-sampled-peak-overhead-max-comparison.txt`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-sampled-peak-overhead-max-comparison.txt`.
  - Fresh max row: attempts `4`, successes `4`, failures `0`, known durations `4`, total `0.195s`, mean `0.049s`, max `0.055s`.
  - Older sampled-peak max row had no duration fields and was heavier: peak `378.703 MB`, final `351.203 MB`, both tests still passed.
  - Tight and latest lower-overhead max reanalysis rows had no duration fields; their final RSS values were `321.719 MB` and `258.188 MB`, respectively.
  - Launch smoke row remained the cheaper short proof at total `0.164s`, mean `0.041s`, max `0.042s`.

### Remaining Risk
- The max-player overhead itself is now measured and tiny, but the final RSS gate still flickers near the exploratory `340 MB` threshold; this run reported `341.703 MB` while earlier latest-cadence reanalysis was far below it.
- Capture duration measures host-side `footprint` command wall time, not every possible perturbation inside the simulator.
- The data argues for keeping sampled-peak capture opt-in and adding or tuning a final-cadence policy before treating final RSS as a hard release gate.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.82/5
- Performance: 4.07/5
- Release readiness: 3.28/5
- Repo clarity: 4.64/5

### Next Frontier
- Add a final-RSS capture cadence policy or threshold decision so late-run attribution near `340 MB` is less dependent on the last periodic snapshot.
- Repeat the max-player sampled-peak overhead run once after that policy is in place to separate cadence effects from run-to-run memory variance.
- Keep `--footprint-capture-sampled-peak` opt-in; it now has measured max-player overhead evidence, but it is still a diagnostic knob rather than the default recipe.

## 2026-05-11 06:56 PDT - Final-cadence footprint attribution and real capture-event accounting

### Baseline Issue Or Opportunity
- The max-player sampled-peak proof showed final RSS attribution was still dependent on a stale `latest` snapshot, with a `+25.705s` gap from the final RSS sample.
- While implementing a final-cadence policy, the probe accounting gap became explicit: overwritten `sampled_peak`, `latest`, and future `final` captures were not all counted. Older overhead rows therefore represented persisted snapshot labels, not true capture attempts.

### Files Changed
- `scripts/probe_ui_memory.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `--footprint-final-interval-seconds` for live probes. When set, the probe updates a persisted `final` footprint snapshot at that minimum in-run cadence.
- Added `final_vs_final_sample` alignment in summaries and manifests.
- Footprint indexes now include `capture_events` metadata for every `footprint` subprocess attempt, while the existing `snapshots` list still stores the latest persisted artifact for each label.
- Footprint overhead summaries now report `source`, true `attempt_count`, and `persisted_snapshot_count`.
- Manifest comparison now shows overhead source, attempts, persisted snapshot count, and final alignment columns.
- Old footprint indexes remain readable; reanalysis marks their overhead source as `snapshot_index`.

### Verification Commands And Exact Outcome
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Exit code `0`.
- `scripts/probe_ui_memory.py --help`
  - Exit code `0`; help now documents `--footprint-final-interval-seconds`.
- Backcompat reanalysis of the previous max-player index:
  - `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.csv --result-bundle /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.xcresult --run-label footprint-final-cadence-backcompat-reanalysis --simulator-state warm-shutdown-no-erase-before-footprint-sampled-peak-overhead-max-player --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max-footprint --summary-output /tmp/imposter-footprint-final-cadence-backcompat-reanalysis.txt --manifest-output /tmp/imposter-footprint-final-cadence-backcompat-reanalysis.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Reanalysis reported overhead source `snapshot_index`, attempts `4`, persisted snapshots `4`, total duration `0.195s`.
  - This preserves old artifact readability while making the weaker accounting source explicit.
- Final-cadence launch smoke:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-final-cadence-launch-smoke --simulator-state warm-shutdown-no-erase-before-footprint-final-cadence-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke-footprint --footprint-peak-min-delta-mb 25 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 30 --footprint-final-interval-seconds 1 --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - `Samples: 5`, first RSS `11.984 MB`, peak/final RSS `289.266 MB`.
  - Warm peak and final gates passed.
  - Capture events: attempts `13`, persisted snapshots `5`, successes `13`, failures `0`, total duration `0.842s`, mean `0.065s`, max `0.176s`.
  - Alignment: `final_vs_final_sample` was `+0.000 MB`, `+0.000s`; `latest_vs_final_sample` was `+277.281 MB`, `+3.151s`.
  - Result bundle passed: `testLaunchShowsHomeScreen()` passed in `4.619006991386414s`.
- Final-cadence max-player proof:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-final-cadence-release-max-player --simulator-state warm-shutdown-no-erase-before-footprint-final-cadence-max-player --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-cadence-max-footprint --footprint-peak-min-delta-mb 75 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 30 --footprint-final-interval-seconds 10 --interval 1.0 --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - CSV: `/tmp/imposter-ui-memory-probe-footprint-final-cadence-max.csv`, `166` lines including the header.
  - Summary: `/tmp/imposter-ui-memory-probe-footprint-final-cadence-max.summary.txt`, `116` lines.
  - Manifest: `/tmp/imposter-ui-memory-probe-footprint-final-cadence-max.manifest.json`, `75` lines.
  - Footprint index: `/tmp/imposter-ui-memory-probe-footprint-final-cadence-max-footprint/footprint-index.json`, `414` lines.
- Final-cadence max-player result:
  - `Samples: 165`, `PIDs: 93242`, first RSS `118.109 MB`, peak RSS `358.438 MB`, final RSS `333.172 MB`.
  - Warm peak gate passed: `358.438 MB <= 380.000 MB`.
  - Warm final gate passed: `333.172 MB <= 340.000 MB`.
  - Capture events: attempts `39`, persisted snapshots `5`, successes `39`, failures `0`, known durations `39`.
  - Total capture duration `2.110s`, mean `0.054s`, max `0.104s`.
  - Alignment: sampled peak matched exactly at `+0.000 MB`, `+0.000s`; latest was `+9.000 MB` and `+27.145s` from final sample; final cadence was closer at `+6.156 MB` and `+7.544s`.
  - Result bundle passed: `testMaximumPlayerRenderedFlowCompletesRound()` passed in `181.28889799118042s`; xcodebuild log showed `203.218 elapsed -- Testing started completed`.
- Reanalysis of the fresh max-player index:
  - `scripts/probe_ui_memory.py --analyze-csv /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.csv --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.xcresult --run-label footprint-final-cadence-max-reanalysis --simulator-state warm-shutdown-no-erase-before-footprint-final-cadence-max-player --configuration Release --only-testing ImposterUITests/ImposterUITests/testMaximumPlayerRenderedFlowCompletesRound --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-cadence-max-footprint --summary-output /tmp/imposter-footprint-final-cadence-max-reanalysis.txt --manifest-output /tmp/imposter-footprint-final-cadence-max-reanalysis.manifest.json --warm-rss-floor-mb 100 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - Reanalysis preserved source `capture_events`, attempts `39`, persisted snapshots `5`, total duration `2.110s`, and final alignment `+6.156 MB`, `+7.544s`.
- Structured comparison:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-footprint-final-cadence-max.manifest.json /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.manifest.json /tmp/imposter-ui-memory-probe-footprint-sampled-peak-overhead-max.manifest.json /tmp/imposter-ui-memory-probe-footprint-overhead-smoke.manifest.json /tmp/imposter-footprint-final-cadence-backcompat-reanalysis.manifest.json --run-label footprint-final-cadence-comparison --summary-output /tmp/imposter-footprint-final-cadence-comparison.txt`.
  - Exit code `0`.
  - New rows show source `capture_events`; old live manifests without `capture_events` show `n/a`; old reanalysis shows source `snapshot_index`.
  - Final-cadence max row: attempts `39`, persisted snapshots `5`, total `2.110s`; previous max row without event history reported only `4` persisted attempts and no final alignment.

### Remaining Risk
- The 10-second final cadence improved end attribution but still left a `+7.544s` and `+6.156 MB` gap from the last sample; a shorter cadence or post-exit explicit final capture may be needed when final attribution is the primary diagnostic.
- Prior ledger entries before this correction used snapshot-count overhead. Treat those older "attempt" totals as persisted snapshot totals unless their index includes `capture_events`.
- Capture duration still measures host-side `footprint` wall time only; it does not prove there is zero simulator perturbation.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.82/5
- Performance: 4.09/5
- Release readiness: 3.29/5
- Repo clarity: 4.65/5

### Next Frontier
- Tune final attribution further: compare `--footprint-final-interval-seconds 5` against `--footprint-capture-final` on a shorter focused flow, then choose the default diagnostic recipe for final RSS investigations.
- Add a compact "recommended memory probe recipes" doc section so future runs do not accidentally compare `snapshot_index` overhead against `capture_events` overhead.
- Keep the `340 MB` final threshold report-only until multiple final-cadence max-player runs agree.

## 2026-05-11 06:59 PDT - Memory probe recipe guide

### Baseline Issue Or Opportunity
- The probe now records true `capture_events`, final-cadence alignment, and older `snapshot_index` reanalysis, but that policy was only encoded in script behavior and ledger prose.
- The latest frontier called for a compact recommended recipe section so future runs do not compare old persisted-snapshot overhead with true capture-event overhead.

### Files Changed
- `docs/MEMORY_PROBE_RECIPES.md`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `docs/MEMORY_PROBE_RECIPES.md` with the recommended max-player diagnostic command, fast launch smoke command, backcompat reanalysis command, structured comparison command, alignment interpretation, and a ledger checklist.
- The guide explicitly defines `capture_events`, `snapshot_index`, and `n/a` overhead sources so old and new manifests are not treated as the same measurement.

### Verification Commands And Exact Outcome
- `test -s docs/MEMORY_PROBE_RECIPES.md && wc -l docs/MEMORY_PROBE_RECIPES.md`
  - Exit code `0`; guide exists and has `175` lines.
- `rg -n "capture_events|snapshot_index|Recommended Max-Player Diagnostic|Fast Launch Smoke|Backcompat Reanalysis|Structured Comparison|Ledger Checklist|--footprint-final-interval-seconds" docs/MEMORY_PROBE_RECIPES.md`
  - Exit code `0`.
  - Confirmed source interpretation, all recipe headings, ledger checklist, and final-cadence flag are present.
- `scripts/probe_ui_memory.py --help | rg -- '--footprint-final-interval-seconds|--compare-manifest|--footprint-capture-sampled-peak|--manifest-output'`
  - Exit code `0`.
  - Confirmed the documented command flags exist in the current CLI help.
- `python3 -m py_compile scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Exit code `0`.
- `git diff --check`
  - Exit code `0`.

### Remaining Risk
- This was a docs-only policy hardening pass; it did not collect new simulator RSS evidence beyond the already documented final-cadence smoke and max-player proof.
- The guide records the current best recipe, but the next empirical frontier still needs to compare a shorter final cadence against explicit post-exit final capture.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.82/5
- Performance: 4.09/5
- Release readiness: 3.29/5
- Repo clarity: 4.67/5

### Next Frontier
- Run the shorter focused comparison from the guide frontier: `--footprint-final-interval-seconds 5` versus `--footprint-capture-final`, then update `docs/MEMORY_PROBE_RECIPES.md` with the chosen final-RSS diagnostic recipe.
- Keep any comparison manifest-based so the overhead source column remains visible.

## 2026-05-11 07:02 PDT - Final RSS recipe smoke comparison

### Baseline Issue Or Opportunity
- The recipe guide still left the final-RSS diagnostic choice open: shorter in-run final cadence versus explicit post-exit `--footprint-capture-final`.
- The goal was to test that choice on the short launch flow before spending another max-player run.

### Files Changed
- `docs/MEMORY_PROBE_RECIPES.md`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Updated the guide with a `Final RSS Attribution Policy` section.
- The guide now recommends in-run `--footprint-final-interval-seconds` for final RSS attribution, uses `1` second for short launch smokes, keeps `10` seconds for the current max-player diagnostic, and marks post-exit `--footprint-capture-final` as experimental.

### Verification Commands And Exact Outcome
- 5-second final-cadence launch smoke:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-final-interval5-launch-smoke --simulator-state warm-shutdown-no-erase-before-footprint-final-interval5-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke-footprint --footprint-peak-min-delta-mb 25 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 30 --footprint-final-interval-seconds 5 --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - `Samples: 6`, first RSS `19.922 MB`, peak RSS `286.922 MB`, final RSS `286.422 MB`.
  - Warm peak and final gates passed.
  - Capture events: attempts `11`, persisted snapshots `5`, successes `11`, failures `0`, total duration `0.386s`.
  - Final cadence was too coarse for the launch flow: `final_vs_final_sample` was `+266.500 MB`, `+3.210s`.
  - Result bundle passed: `testLaunchShowsHomeScreen()` passed in `4.632044076919556s`.
- Post-exit final-capture launch smoke:
  - `scripts/probe_ui_memory.py --replace --configuration Release --run-label footprint-capture-final-launch-smoke --simulator-state warm-shutdown-no-erase-before-footprint-capture-final-smoke --only-testing ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen --result-bundle /tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.xcresult --output-csv /tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.csv --summary-output /tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.summary.txt --manifest-output /tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.manifest.json --footprint-summary-dir /tmp/imposter-ui-memory-probe-footprint-capture-final-smoke-footprint --footprint-peak-min-delta-mb 25 --footprint-capture-sampled-peak --footprint-latest-interval-seconds 30 --footprint-capture-final --interval 0.5 --warm-rss-floor-mb 1 --max-warm-peak-rss-mb 380 --max-warm-final-rss-mb 340 --rss-gate-mode report`.
  - Exit code `0`.
  - `Samples: 5`, first RSS `107.828 MB`, peak/final RSS `288.812 MB`.
  - Warm peak and final gates passed.
  - Capture events: attempts `10`, persisted snapshots `5`, successes `9`, failures `1`, total duration `0.356s`.
  - The post-exit final snapshot failed with return code `66`: `footprint: Unable to find pid for process matching '98615'`.
  - `final_vs_final_sample` was absent because the final snapshot failed.
  - Result bundle passed: `testLaunchShowsHomeScreen()` passed in `4.430508017539978s`.
- Structured comparison:
  - `scripts/probe_ui_memory.py --compare-manifest /tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.manifest.json /tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.manifest.json /tmp/imposter-ui-memory-probe-footprint-final-cadence-smoke.manifest.json --run-label footprint-final-recipe-smoke-comparison --summary-output /tmp/imposter-footprint-final-recipe-smoke-comparison.txt`.
  - Exit code `0`.
  - Wrote `/tmp/imposter-footprint-final-recipe-smoke-comparison.txt`, `49` lines.
  - Comparison showed 5-second final cadence was stale (`+266.500 MB`, `+3.210s`), post-exit final capture had `1` failure and no final alignment, and the prior 1-second final-cadence launch smoke remained exact (`+0.000 MB`, `+0.000s`).
- Artifact counts:
  - `/tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.csv`: `7` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.summary.txt`: `116` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke.manifest.json`: `75` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-final-interval5-smoke-footprint/footprint-index.json`: `162` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.csv`: `6` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.summary.txt`: `105` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-capture-final-smoke.manifest.json`: `67` lines.
  - `/tmp/imposter-ui-memory-probe-footprint-capture-final-smoke-footprint/footprint-index.json`: `153` lines.
- Guide verification:
  - `test -s docs/MEMORY_PROBE_RECIPES.md && wc -l docs/MEMORY_PROBE_RECIPES.md`.
  - Exit code `0`; guide now has `191` lines.
  - `rg -n 'Final RSS Attribution Policy|--footprint-final-interval-seconds|--footprint-capture-final|return code `66`|Recommended Max-Player Diagnostic|Fast Launch Smoke' docs/MEMORY_PROBE_RECIPES.md`.
  - Exit code `0`; confirmed the policy, flags, return-code caveat, and recipe headings.

### Remaining Risk
- The selected short-flow policy is based on launch smoke evidence; max-player final attribution still needs repeated final-cadence runs before the `340 MB` threshold can become anything other than report-only.
- `--footprint-capture-final` might still work for flows where the app process remains alive after xcodebuild exits, but it is not reliable enough to be the default final-RSS recipe.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.7/5
- Accessibility: 4.05/5
- Localization: 2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.84/5
- UI automation: 4.82/5
- Performance: 4.10/5
- Release readiness: 3.29/5
- Repo clarity: 4.68/5

### Next Frontier
- If continuing memory diagnostics, repeat the max-player final-cadence recipe once more before changing the final RSS policy from report-only.
- Otherwise shift back toward product-facing polish: localization depth, AI fallback UX, or privacy/accessibility proof for hidden-information screens.

## 2026-05-11 07:09 PDT - Role-reveal localization coverage gate

### Baseline Issue Or Opportunity
- The product scorecard had localization stuck at `2/5`, and the catalog only had `30` translated strings for each non-English target locale.
- Privacy and role-reveal strings are especially risky to leave as English fallback because they guide pass-and-play handoff behavior and VoiceOver users around secret information.

### Files Changed
- `Imposter/Resources/Localizable.xcstrings`
- `scripts/check_localization_coverage.py`
- `docs/FRONTIER_LEDGER.md`

### Tests Added Or Updated
- Added `scripts/check_localization_coverage.py`.
- The checker requires target locale coverage for `de`, `es`, `fr`, and `ja`.
- It enforces a floor of `40` translated strings per target locale.
- It requires `10` priority role/secret strings to be localized in every target locale.
- It validates placeholder parity for translated strings so format arguments such as `%@` do not disappear.
- Added German, Spanish, French, and Japanese translations for the high-risk role reveal, hold-to-reveal, private handoff, secret-word, and imposter-hint strings.

### Verification Commands And Exact Outcome
- Localization coverage before this slice:
  - One-off JSON count reported `152` total strings and `30` translations each for `de`, `es`, `fr`, and `ja`.
- `python3 -m json.tool Imposter/Resources/Localizable.xcstrings >/tmp/imposter-localizable-json-check.json && wc -l /tmp/imposter-localizable-json-check.json`
  - Exit code `0`; JSON parsed successfully and formatted output had `1659` lines.
- `python3 -m py_compile scripts/check_localization_coverage.py scripts/probe_ui_memory.py scripts/check_launch_metric.py`
  - Exit code `0`.
- `scripts/check_localization_coverage.py`
  - Exit code `0`.
  - Output: source language `en`, total strings `152`, priority keys `10`.
  - Output: `de: 40 translated strings`, `es: 40 translated strings`, `fr: 40 translated strings`, `ja: 40 translated strings`.
  - Output: `PASS: focused localization coverage is acceptable.`
- `rg -n 'PRIORITY_KEYS|DEFAULT_LOCALES|min-translated-per-locale|placeholder mismatch|PASS: focused localization coverage' scripts/check_localization_coverage.py`
  - Exit code `0`.
  - Confirmed the required locale set, priority-key gate, minimum translation floor, placeholder diagnostics, and pass output are present.
- `rg -n '"Hold to Reveal"|"Hold to Reveal My Role"|"Keep Holding\\.\\.\\."|"Player'\"'\"'s turn to reveal their role"|"Press and hold to see your secret role"|"Private - Hand device to next player"|"Role Reveal"|"The secret word is %@\\. You are not the Imposter\\."|"This is a private screen\\. Please hand the device to the next player before revealing\\."|"You are the Imposter! Your hint is: %@\\."' Imposter/Resources/Localizable.xcstrings`
  - Exit code `0`.
  - Confirmed the priority keys are present in the catalog after translation.
- XcodeBuildMCP preflight:
  - `mcp__xcodebuildmcp__.session_show_defaults`.
  - Confirmed active profile `imposter-ui`, project `Imposter.xcodeproj`, scheme `Imposter-UITests`, simulator `A113E399-3127-41CE-AB7E-B529DB41B3B6`.
- XcodeBuildMCP focused UI test:
  - `mcp__xcodebuildmcp__.test_sim` with `extraArgs: ["-only-testing:ImposterUITests/ImposterUITests/testLaunchShowsHomeScreen"]`.
  - Status `SUCCEEDED`; passed `1`, failed `0`, skipped `0`.
  - `testLaunchShowsHomeScreen` passed in `4876ms`.
  - Diagnostics had no warnings and no errors.
  - Build log: `/Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/logs/test_sim_2026-05-11T14-08-44-406Z_pid15951_6fe5ced5.log`.
  - Result bundle: `/Users/m3-max/Library/Developer/XcodeBuildMCP/workspaces/Imposter-05b65abf5234/result-bundles/test_sim_2026-05-11T14-08-44-407Z_pid15951_28d06c7d.xcresult`.

### Remaining Risk
- This is focused localization coverage, not full 5-language completion; most strings still need translation.
- The new translations were not reviewed by native speakers.
- The checker validates coverage and placeholder safety, but it does not catch tone, line length, or cultural fit.

### Score Snapshot
- Domain correctness: 4.25/5
- Gameplay completeness: 3.95/5
- Privacy: 3.72/5
- Accessibility: 4.07/5
- Localization: 2.2/5
- Liquid Glass fit: 3.15/5
- Animation/haptics: 3.15/5
- AI resilience: 2.5/5
- Persistence safety: 3.25/5
- Test depth: 4.86/5
- UI automation: 4.82/5
- Performance: 4.10/5
- Release readiness: 3.30/5
- Repo clarity: 4.69/5

### Next Frontier
- Expand the localization gate to phase-critical navigation strings: setup, clue, discussion, voting, reveal, summary, and settings.
- Add a localized UI smoke in one non-English language once the critical path has enough translations to make the screen assertions stable.
- Keep privacy/accessibility wording under native-speaker review before claiming App Store-grade localization.
