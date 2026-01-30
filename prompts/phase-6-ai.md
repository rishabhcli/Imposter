# Phase 6: AI Integration – Agent Prompt

## Objective
Integrate Apple's ImagePlayground framework to generate images for custom word prompts.

## Context
- Read `CLAUDE.md` for architecture
- Load `.claude/skills/foundation-models/` for ImagePlayground patterns
- Reference `Implementation Plan.md` Section 7.3

## Prerequisites
- ImagePlayground.framework added to project
- Physical device for testing (simulator may not support)

## Tasks

### 1. Import Framework

In `GameStore.swift`:
```swift
import ImagePlayground
```

### 2. Add Image Property to RoundState

```swift
struct RoundState {
    // ... existing properties
    var generatedImage: UIImage?
}
```

Note: UIImage is not Codable. Handle in CodingKeys or make property transient.

### 3. Implement Generation in GameStore

```swift
extension GameStore {
    func generateSecretImage() {
        guard state.settings.wordSource == .customPrompt,
              let prompt = state.roundState?.secretWord,
              !prompt.isEmpty else { return }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let creator = try await ImageCreator()
                let concepts: [ImagePlaygroundConcept] = [.text(prompt)]
                let images = creator.images(for: concepts, style: .illustration, limit: 1)
                
                for try await image in images {
                    let uiImage = UIImage(cgImage: image.cgImage)
                    await MainActor.run {
                        self?.state.roundState?.generatedImage = uiImage
                    }
                    break
                }
            } catch {
                print("Image generation failed: \(error)")
            }
        }
    }
}
```

### 4. Trigger Generation on Game Start

In `dispatch(_:)` after state update:
```swift
case .startGame:
    if state.settings.wordSource == .customPrompt {
        generateSecretImage()
    }
```

### 5. Display in RoleCardView

Already covered in Phase 4. Verify:
- Image shows when available
- ProgressView shows when expecting but not ready
- Graceful fallback if generation fails

### 6. Memory Cleanup

In reducer for `.startNewRound`:
```swift
newState.roundState?.generatedImage = nil
```

### 7. Error Handling

- Log errors but don't crash
- Game continues without image if generation fails
- Consider user feedback (optional toast/alert)

### 8. Test on Device

- Test with various prompts
- Verify image quality and relevance
- Check memory usage with Instruments
- Test generation timing

## Acceptance Criteria
- [ ] Custom prompt triggers image generation
- [ ] Generated image displays in RoleCardView
- [ ] No crash if generation fails
- [ ] Memory freed after round ends
- [ ] Works on physical device with A12+ chip

## Testing Focus
- Test with simple prompts ("cat", "castle")
- Test with complex prompts ("medieval knight")
- Test error scenarios (invalid prompt, unavailable)
- Profile memory during generation

## Next Phase
After completion, proceed to **Phase 7: Polish**.

---

## Ralph Loop Checklist
- [ ] Read skill: foundation-models
- [ ] Add ImagePlayground import
- [ ] Implement generateSecretImage()
- [ ] Wire trigger in dispatch
- [ ] Test on physical device
- [ ] Verify image display
- [ ] Profile memory
- [ ] Update `TASKS.md`
