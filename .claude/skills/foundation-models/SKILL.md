# Foundation Models Skill

## When to Load
Load this skill when:
- Implementing AI-generated images for custom words
- Working with `ImagePlayground` framework
- Handling async image generation
- Managing on-device AI memory/performance

## Key Frameworks

### ImagePlayground
For generating images from text prompts:
```swift
import ImagePlayground
```

### FoundationModels (Optional)
For text generation with on-device LLM:
```swift
import FoundationModels
```

## ImageCreator Usage

### Basic Pattern
```swift
Task.detached(priority: .userInitiated) {
    do {
        let creator = try await ImageCreator()
        let concepts: [ImagePlaygroundConcept] = [.text(prompt)]
        let images = creator.images(for: concepts, style: .illustration, limit: 1)
        
        for try await image in images {
            let uiImage = UIImage(cgImage: image.cgImage)
            await MainActor.run {
                self.state.roundState?.generatedImage = uiImage
            }
            break // Only need first result
        }
    } catch {
        print("Generation failed: \(error)")
    }
}
```

### Available Styles
- `.photo` – Photorealistic
- `.illustration` – Illustrated/artistic
- `.sketch` – Pencil sketch style
- `.monochrome` – Black and white
- `.fantasy` – Fantastical/imaginative

### Concepts
```swift
.text("a medieval castle")           // Text description
.extractedFrom(url)                  // Extract from image URL
.person(...)                         // Person-based (requires permissions)
```

## Important Considerations

1. **Device Support**: Requires A12 Bionic or later
2. **Memory**: Model uses ~few hundred MB when active
3. **Time**: Generation takes 1-3 seconds typically
4. **Off-Main**: Always run in detached Task
5. **Content Safety**: Framework has built-in content filtering
6. **Fallback**: Handle errors gracefully (no image is acceptable)

## UI Alternative

For user-controlled image creation (not recommended for game flow):
```swift
.imagePlaygroundSheet(isPresented: $showPicker, concept: .text(prompt)) { url in
    // Handle generated image URL
}
```

## Memory Management

- Create `ImageCreator` in local scope
- Don't hold reference longer than needed
- Clear `generatedImage` when round ends
- Apple manages model unloading automatically

## Critical Research Notes (Section 14)

### Device Requirements
- Requires A12 Bionic or later
- Model is ~3GB quantized, few hundred MB in active memory
- Available on iOS 26+ without special entitlements

### Content Safety
- Framework has built-in content filtering
- May refuse certain prompts for safety
- Handle gracefully - no image is acceptable fallback

### Alternative: ImagePlaygroundSheet
For user-controlled image creation (NOT recommended for game flow):
```swift
.imagePlaygroundSheet(isPresented: $showPicker, concept: .text(prompt)) { url in
    // Handle generated image URL
}
```
This interrupts flow, so we use programmatic `ImageCreator` instead.

### SystemLanguageModel (Optional)
Could use for generating random word from theme:
```swift
// Pseudo: "Give me one random word related to [theme]"
// But adds unpredictability - we skip this for MVP
```

### Timing Considerations
- Generation takes 1-3 seconds typically
- Kick off during `startGame` action
- Overlaps with role reveal pass-and-play time
- Show `ProgressView` if not ready when needed
