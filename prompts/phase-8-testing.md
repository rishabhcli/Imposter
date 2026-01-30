# Phase 8: Testing – Agent Prompt

## Objective
Implement comprehensive unit tests and UI tests to ensure app quality.

## Context
- Read `CLAUDE.md` for architecture
- Reference `Implementation Plan.md` Section 10

## Tasks

### 1. Unit Tests (`ImposterTests/`)

#### GameReducerTests.swift
```swift
final class GameReducerTests: XCTestCase {
    func testAddPlayer() { }
    func testRemovePlayer() { }
    func testUpdatePlayer() { }
    func testStartGameInitializesRound() { }
    func testStartGameRequiresThreePlayers() { }
    func testSubmitClueAdvancesIndex() { }
    func testSubmitClueRejectsEmpty() { }
    func testSubmitClueEnforcesMaxLength() { }
    func testCastVoteRecordsCorrectly() { }
    func testCastVotePreventsSelfVote() { }
    func testVotingOutcomeCorrect() { }
    func testVotingOutcomeIncorrect() { }
    func testScoringForCorrectVote() { }
    func testScoringForImposterSurvival() { }
    func testStartNewRoundResetsState() { }
    func testReturnToHomeClearsPlayers() { }
}
```

#### GamePhaseTests.swift
```swift
final class GamePhaseTests: XCTestCase {
    func testValidTransitions() { }
    func testInvalidTransitions() { }
    func testAllPhasesHaveValidPath() { }
}
```

#### WordSelectorTests.swift
```swift
final class WordSelectorTests: XCTestCase {
    func testSelectsWordFromCategory() { }
    func testFiltersByDifficulty() { }
    func testHandlesMissingWordPack() { }
    func testMixedDifficultyIncludesAll() { }
}
```

### 2. UI Tests (`ImposterUITests/`)

#### ImposterUITests.swift
```swift
final class ImposterUITests: XCTestCase {
    func testLaunchShowsHomeScreen() { }
    func testNewGameNavigatesToSetup() { }
    func testAddPlayersFlow() { }
    func testStartGameRequiresThreePlayers() { }
    func testCompleteGameFlow() { }
}
```

#### LocalizationUITests.swift (optional)
```swift
func testSpanishLocalization() {
    app.launchArguments += ["-AppleLanguages", "(es)"]
    // Verify key strings
}
```

### 3. Test Utilities

#### TestHelpers.swift
```swift
extension GameState {
    static func mock(players: Int = 3) -> GameState { }
}

extension Player {
    static func mock(name: String = "Test") -> Player { }
}
```

### 4. Code Coverage

Target: 80%+ on Domain layer
- GameReducer
- GamePhase
- WordSelector
- GameStore

### 5. Performance Testing

Use Instruments:
- Time Profiler during gameplay
- Memory during AI generation
- Check for main thread blocking
- Look for retain cycles

### 6. Manual Testing Checklist

- [ ] Full game with 3 players
- [ ] Full game with 10 players
- [ ] Custom prompt with AI image
- [ ] Random word from each category
- [ ] VoiceOver navigation
- [ ] Dynamic Type at max size
- [ ] Reduce Motion enabled
- [ ] Reduce Transparency enabled
- [ ] Each supported language
- [ ] Light mode
- [ ] Dark mode
- [ ] iPad layout

## Acceptance Criteria
- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] 80%+ code coverage on Domain
- [ ] No memory leaks detected
- [ ] Consistent 60fps during gameplay
- [ ] Manual test checklist complete

## Next Phase
After completion, proceed to **Phase 9: Release**.

---

## Ralph Loop Checklist
- [ ] Create test files
- [ ] Implement reducer tests
- [ ] Implement phase tests
- [ ] Implement UI tests
- [ ] Run all tests
- [ ] Check coverage
- [ ] Profile performance
- [ ] Complete manual testing
- [ ] Update `TASKS.md`
