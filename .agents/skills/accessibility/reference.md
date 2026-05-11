# Accessibility Reference Code

## Phase Change Announcements

```swift
func announcePhaseChange(_ phase: GamePhase) {
    let message: String
    switch phase {
    case .setup:
        message = ""
    case .roleReveal:
        message = "Secret roles are being handed out. Pass the device around."
    case .clueRound:
        message = "Clue round started. Each player will give a clue."
    case .discussion:
        message = "Discussion time. Talk about who might be the imposter."
    case .voting:
        message = "Time to vote for the imposter."
    case .reveal:
        message = "Revealing the results."
    case .summary:
        message = "Game over. Here are the final scores."
    }
    
    if !message.isEmpty {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
```

## Accessible Player Badge

```swift
extension View {
    func accessibilityPlayerBadge(player: Player) -> some View {
        self
            .accessibilityLabel("\(player.name), color \(player.color.rawValue)")
            .accessibilityHint("Player indicator")
    }
}

// Usage
Circle()
    .fill(LGColors.playerColor(player.color))
    .accessibilityPlayerBadge(player: player)
```

## Accessible Vote Card

```swift
struct PlayerVoteCard: View {
    let player: Player
    
    var body: some View {
        LGCard(cornerRadius: 16) {
            VStack(spacing: LGSpacing.small) {
                Circle()
                    .fill(LGColors.playerColor(player.color))
                    .frame(width: 50, height: 50)
                Text(player.name)
                    .font(LGTypography.bodyMedium)
                    .lineLimit(1)
            }
            .padding(LGSpacing.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name)")
        .accessibilityHint("Double tap to vote for this player as the imposter")
        .accessibilityAddTraits(.isButton)
    }
}
```

## Accessible Scoreboard Row

```swift
struct ScoreboardRow: View {
    let player: Player
    let rank: Int
    let isWinner: Bool
    
    var body: some View {
        HStack(spacing: LGSpacing.medium) {
            Text("\(rank).")
                .font(LGTypography.headlineMedium)
                .frame(width: 30, alignment: .trailing)
            
            Circle()
                .fill(LGColors.playerColor(player.color))
                .frame(width: 30, height: 30)
            
            Text(player.name)
                .font(LGTypography.bodyLarge)
            
            Spacer()
            
            Text("\(player.score)")
                .font(LGTypography.headlineLarge)
            
            if isWinner {
                Image(systemName: "crown.fill")
                    .foregroundStyle(LGColors.warning)
            }
        }
        .padding(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }
    
    private var accessibilityText: String {
        var text = "Rank \(rank), \(player.name), \(player.score) points"
        if isWinner {
            text += ", winner"
        }
        return text
    }
}
```

## Reduce Motion Handling

```swift
struct RevealAnimationView: View {
    let imposter: Player
    @State private var isRevealed = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        ZStack {
            if isRevealed {
                imposterCard
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            } else {
                questionMark
            }
        }
        .onAppear {
            let animation: Animation = reduceMotion 
                ? .easeInOut(duration: 0.3)
                : .spring(response: 0.6, dampingFraction: 0.5).delay(1.0)
            
            withAnimation(animation) {
                isRevealed = true
            }
        }
    }
    
    private var imposterCard: some View {
        LGCard(cornerRadius: 16) {
            VStack {
                Text(imposter.name)
                    .font(LGTypography.headlineLarge)
                Text("was the Imposter!")
                    .font(LGTypography.bodyMedium)
            }
            .padding()
        }
    }
    
    private var questionMark: some View {
        Circle()
            .fill(LGColors.surfacePrimary)
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "questionmark")
                    .font(.largeTitle)
            )
    }
}
```

## Localization String Catalog Structure

```json
{
  "sourceLanguage": "en",
  "strings": {
    "imposter_title": {
      "localizations": {
        "en": { "stringUnit": { "value": "Imposter" } },
        "es": { "stringUnit": { "value": "Impostor" } },
        "fr": { "stringUnit": { "value": "Imposteur" } },
        "de": { "stringUnit": { "value": "Betrüger" } },
        "ja": { "stringUnit": { "value": "インポスター" } }
      }
    },
    "new_game_button": {
      "localizations": {
        "en": { "stringUnit": { "value": "New Game" } },
        "es": { "stringUnit": { "value": "Nueva Partida" } },
        "fr": { "stringUnit": { "value": "Nouvelle Partie" } },
        "de": { "stringUnit": { "value": "Neues Spiel" } },
        "ja": { "stringUnit": { "value": "新しいゲーム" } }
      }
    },
    "pass_device_to %@": {
      "localizations": {
        "en": { "stringUnit": { "value": "Pass the device to %@" } },
        "es": { "stringUnit": { "value": "Pasa el dispositivo a %@" } },
        "fr": { "stringUnit": { "value": "Passez l'appareil à %@" } },
        "de": { "stringUnit": { "value": "Gib das Gerät an %@" } },
        "ja": { "stringUnit": { "value": "%@にデバイスを渡してください" } }
      }
    }
  }
}
```

## HapticManager

```swift
import UIKit

enum HapticManager {
    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    static func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// Usage
HapticManager.playImpact(.medium)      // Vote selection
HapticManager.playImpact(.light)       // Clue submit
HapticManager.playNotification(.success) // Correct vote
HapticManager.playNotification(.error)   // Wrong vote
```

## Accessibility Identifiers for UI Tests

```swift
enum AccessibilityIDs {
    // Home
    static let newGameButton = "NewGameButton"
    static let howToPlayButton = "HowToPlayButton"
    static let settingsButton = "SettingsButton"
    
    // Setup
    static let addPlayerButton = "AddPlayerButton"
    static let startGameButton = "StartGameButton"
    static let playerNameField = "PlayerNameField"
    
    // Role Reveal
    static let revealRoleButton = "RevealRoleButton"
    static let tapToContinue = "TapToContinue"
    
    // Clue Round
    static let clueTextField = "ClueTextField"
    static let submitClueButton = "SubmitClueButton"
    static let proceedButton = "ProceedButton"
    
    // Voting
    static func voteCard(for playerID: UUID) -> String {
        "VoteCard_\(playerID.uuidString)"
    }
    
    // Summary
    static let playAgainButton = "PlayAgainButton"
    static let mainMenuButton = "MainMenuButton"
}
```
