# Phase 5: Gameplay Phases – Agent Prompt

## Objective
Implement ClueRound, Discussion, Voting, Reveal, and Summary phases to complete the game loop.

## Context
- Read `CLAUDE.md` for architecture
- Load `.claude/skills/game-logic/` for reducer patterns
- Load `.claude/skills/liquid-glass/` for UI components
- Reference `Implementation Plan.md` Sections 6.4-6.7

## Tasks

### 1. ClueRoundView (`Features/ClueRound/ClueRoundView.swift`)

Display:
- Round indicator ("Clue Round 1 of 2")
- Current player prompt
- ClueInputView
- ClueHistoryList

Logic:
- Track current player from `roundState.currentClueIndex`
- Auto-advance after all clues
- Show "Proceed" button when done

### 2. ClueInputView (`Features/ClueRound/ClueInputView.swift`)

- TextField with 30-char limit
- Character counter
- Submit button (disabled if empty)
- Auto-focus with `@FocusState`
- Clear field after submit

### 3. ClueHistoryList (`Features/ClueRound/ClueHistoryList.swift`)

- ScrollView of all clues
- Show player color dot + name + clue text
- Updates as new clues are submitted

### 4. DiscussionView (`Features/Voting/DiscussionView.swift`) (Optional)

- Show if `discussionTimerEnabled`
- Countdown timer display
- "Start Voting" button to skip/end

### 5. VotingView (`Features/Voting/VotingView.swift`)

State:
- `@State private var currentVoterIndex = 0`
- `@State private var hasVoted = false`

Flow:
1. Show voter prompt
2. PlayerSelectionGrid (excluding self)
3. On selection: dispatch `.castVote`, set hasVoted
4. Show "Vote recorded. Pass device."
5. On tap: advance to next voter
6. When all done: dispatch `.completeVoting`

### 6. PlayerSelectionGrid (`Features/Voting/PlayerSelectionGrid.swift`)

- LazyVGrid with adaptive columns
- PlayerVoteCard for each selectable player
- Haptic feedback on selection

### 7. PlayerVoteCard (`Features/Voting/PlayerVoteCard.swift`)

- LGCard with player color circle + name
- Tappable
- Accessibility label and hint

### 8. RevealView (`Features/Reveal/RevealView.swift`)

Display:
- "The votes are in..."
- Who received most votes
- RevealAnimationView showing imposter
- Outcome text (correct/wrong)
- Imposter word guess (if enabled and imposter survived)
- "Continue" button → dispatch `.completeRound`

### 9. RevealAnimationView (`Features/Reveal/RevealAnimationView.swift`)

- Initial: question mark circle
- After delay: animate to imposter card
- Use spring animation (respect Reduce Motion)

### 10. SummaryView (`Features/Summary/SummaryView.swift`)

- "Game Summary" title
- Sorted scoreboard (highest first)
- Highlight winner with crown
- "Play Again" → dispatch `.startNewRound`
- "Main Menu" → dispatch `.returnToHome`

### 11. ScoreboardRow (`Features/Summary/ScoreboardRow.swift`)

- Rank number
- Player color circle
- Player name
- Score
- Crown icon if winner
- Highlight background for winner

## Acceptance Criteria
- [ ] Complete game flow works end-to-end
- [ ] Clue submission respects 30-char limit
- [ ] Voting prevents self-votes
- [ ] Scoring calculated correctly per rules
- [ ] Multiple rounds accumulate scores
- [ ] Reveal animation plays (respects Reduce Motion)
- [ ] Summary shows correct winner(s)

## Testing Focus
- Full game with 3 players
- Verify scoring in various scenarios
- Test imposter survival scoring
- Test correct vote scoring
- UI test for complete flow

## Next Phase
After completion, proceed to **Phase 6: AI Integration**.

---

## Ralph Loop Checklist
- [ ] Implement ClueRoundView + helpers
- [ ] Implement VotingView + helpers
- [ ] Implement RevealView + animation
- [ ] Implement SummaryView + scoreboard
- [ ] Test complete game flow
- [ ] Verify all dispatch calls
- [ ] Update `TASKS.md`
