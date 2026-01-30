# Phase 4: Role Reveal – Agent Prompt

## Objective
Implement pass-and-play role reveal where each player privately sees their role (secret word or imposter status).

## Context
- Read `CLAUDE.md` for architecture
- Load `.claude/skills/liquid-glass/` for UI components
- Reference `Implementation Plan.md` Section 6.3

## Tasks

### 1. RoleRevealView (`Features/RoleReveal/RoleRevealView.swift`)

State management:
- `@State private var currentRevealIndex = 0`
- `@State private var roleRevealed = false`

Flow:
1. Show "Pass the device to [PlayerName]"
2. "Reveal Role" button
3. On tap: show RoleCardView
4. "Tap to continue" instruction
5. On tap: hide card, increment index
6. When all done: dispatch `.completeRoleReveal`

Privacy considerations:
- Full-screen view (hide nav bar)
- Cover screen between reveals
- Consider adding blur overlay behind card

```swift
var body: some View {
    let currentPlayer = store.state.players[currentRevealIndex]
    
    VStack {
        if !roleRevealed {
            // "Pass to player" prompt
            // "Reveal Role" button
        } else {
            // RoleCardView
            // "Tap to continue"
        }
    }
    .contentShape(Rectangle())
    .onTapGesture { handleTap() }
}
```

### 2. RoleCardView (`Features/RoleReveal/RoleCardView.swift`)

Two variants via enum:
```swift
enum Role {
    case informed(word: String)
    case imposter
}
```

**Informed Player Card:**
- "Secret Word:" label
- Word in displayMedium, accent color
- AI-generated image (if available, show ProgressView if loading)
- "You are NOT the Imposter."

**Imposter Card:**
- Question mark icon (SF Symbol)
- "You are the Imposter!" headline
- "You don't know the word. Blend in with your clues!"

Both wrapped in LGCard with padding.

### 3. AI Image Integration

If `settings.wordSource == .customPrompt`:
- Check `roundState.generatedImage`
- If nil and expecting image: show ProgressView
- If available: show Image resized to fit

### 4. Accessibility

- VoiceOver labels for prompts and buttons
- Announce when role is revealed
- Consider auto-hide after timeout (optional)

## Acceptance Criteria
- [ ] Each player sees their role privately
- [ ] Imposter sees different content than informed players
- [ ] AI image displays when available
- [ ] Graceful handling when image not ready
- [ ] Correctly cycles through all players
- [ ] Transitions to clueRound phase after completion
- [ ] Works with 3-10 players

## Testing Focus
- Test with exactly 3 players
- Test with 10 players
- Test imposter card display
- Test informed card display
- Verify phase transition

## Next Phase
After completion, proceed to **Phase 5: Gameplay Phases**.

---

## Ralph Loop Checklist
- [ ] Read skill: liquid-glass
- [ ] Implement RoleRevealView
- [ ] Implement RoleCardView (both variants)
- [ ] Add AI image display
- [ ] Test reveal flow
- [ ] Verify phase transition
- [ ] Update `TASKS.md`
