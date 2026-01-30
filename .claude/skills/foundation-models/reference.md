# Foundation Models Reference Code

## Complete Image Generation Implementation

```swift
import ImagePlayground
import SwiftUI

extension GameStore {
    /// Generates an AI image for the secret word when using custom prompt mode
    func generateSecretImage() {
        guard state.settings.wordSource == .customPrompt,
              let prompt = state.roundState?.secretWord,
              !prompt.isEmpty else { return }
        
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                // Initialize the image generator
                let creator = try await ImageCreator()
                
                // Create concept from text prompt
                let concepts: [ImagePlaygroundConcept] = [.text(prompt)]
                
                // Request images with illustration style
                let imageSequence = creator.images(
                    for: concepts,
                    style: .illustration,
                    limit: 1
                )
                
                // Process the async sequence
                for try await generatedImage in imageSequence {
                    let uiImage = UIImage(cgImage: generatedImage.cgImage)
                    
                    // Update state on main actor
                    await MainActor.run {
                        self?.state.roundState?.generatedImage = uiImage
                    }
                    
                    break // Only need the first image
                }
            } catch {
                print("Image generation failed: \(error.localizedDescription)")
                // Graceful degradation - game continues without image
            }
        }
    }
}
```

## RoundState with Image Storage

```swift
struct RoundState: Codable, Sendable {
    let secretWord: String
    let imposterID: UUID
    var clues: [Clue]
    var votes: [UUID: UUID]
    var currentClueIndex: Int
    
    // Note: UIImage is not Codable, handle separately
    var generatedImage: UIImage?
    
    // Custom Codable implementation to exclude image
    enum CodingKeys: String, CodingKey {
        case secretWord, imposterID, clues, votes, currentClueIndex
    }
    
    struct Clue: Codable, Identifiable, Sendable {
        let id: UUID
        let playerID: UUID
        let text: String
        let timestamp: Date
        let roundIndex: Int
    }
}
```

## RoleCardView with Image Display

```swift
struct RoleCardView: View {
    enum Role {
        case informed(word: String)
        case imposter
    }
    
    let role: Role
    @Environment(GameStore.self) private var store
    
    var body: some View {
        LGCard(cornerRadius: 20) {
            VStack(spacing: LGSpacing.large) {
                switch role {
                case .informed(let word):
                    informedContent(word: word)
                case .imposter:
                    imposterContent
                }
            }
            .padding(LGSpacing.extraLarge)
        }
        .frame(maxWidth: 300)
    }
    
    @ViewBuilder
    private func informedContent(word: String) -> some View {
        Text("Secret Word:")
            .font(LGTypography.bodyLarge)
            .foregroundStyle(LGColors.textSecondary)
        
        Text(word.uppercased())
            .font(LGTypography.displayMedium)
            .foregroundStyle(LGColors.accentPrimary)
            .fontWeight(.heavy)
        
        // AI-generated image (if available)
        if let image = store.state.roundState?.generatedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(12)
        } else if store.state.settings.wordSource == .customPrompt {
            // Show loading if expecting an image
            ProgressView("Generating image...")
                .frame(height: 100)
        }
        
        Text("You are NOT the Imposter.")
            .font(LGTypography.bodyMedium)
            .foregroundStyle(LGColors.textPrimary)
    }
    
    @ViewBuilder
    private var imposterContent: some View {
        Image(systemName: "questionmark.circle.fill")
            .font(.system(size: 64))
            .foregroundStyle(LGColors.error)
        
        Text("You are the Imposter!")
            .font(LGTypography.headlineLarge)
            .foregroundStyle(LGColors.textPrimary)
        
        Text("You don't know the word.\nBlend in with your clues!")
            .font(LGTypography.bodyMedium)
            .foregroundStyle(LGColors.textSecondary)
            .multilineTextAlignment(.center)
    }
}
```

## Triggering Generation on Game Start

```swift
// In GameStore.dispatch()
func dispatch(_ action: GameAction) {
    let newState = GameReducer.reduce(state: state, action: action)
    
    // Validate and apply
    if newState.currentPhase != state.currentPhase {
        guard state.currentPhase.canTransition(to: newState.currentPhase) else {
            return
        }
    }
    state = newState
    
    // Trigger side effects AFTER state update
    switch action {
    case .startGame:
        if state.settings.wordSource == .customPrompt {
            generateSecretImage()
        }
    default:
        break
    }
}
```

## Cleanup After Round

```swift
// In reducer for .completeRound or .startNewRound
case .startNewRound:
    // Clear previous image to free memory
    newState.roundState?.generatedImage = nil
    
    // Create new round
    newState.roundState = createNewRound(players: newState.players, settings: newState.settings)
    newState.currentPhase = .roleReveal
```

## Error Handling Patterns

```swift
enum ImageGenerationError: Error {
    case deviceNotSupported
    case generationFailed(underlying: Error)
    case contentFiltered
}

// Check availability before attempting
func canGenerateImages() -> Bool {
    // ImageCreator availability check (pseudo-code)
    // Actual API may differ - consult Apple docs
    return true // Assume available on iOS 26+ with A12+
}
```
