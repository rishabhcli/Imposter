//
//  HapticsServiceProtocol.swift
//  Imposter
//
//  Protocol for haptic feedback services.
//

import Foundation
import UIKit

// MARK: - HapticsServiceProtocol

/// Protocol defining haptic feedback capabilities.
/// Implementations provide tactile feedback for user interactions.
protocol HapticsServiceProtocol: Sendable {

    // MARK: - Impact Feedback

    /// Plays an impact haptic feedback.
    /// - Parameter style: The intensity of the impact
    func playImpact(_ style: HapticImpactStyle)

    // MARK: - Notification Feedback

    /// Plays a notification haptic feedback.
    /// - Parameter type: The type of notification
    func playNotification(_ type: HapticNotificationType)

    // MARK: - Selection Feedback

    /// Plays a selection changed haptic feedback.
    func playSelection()

    // MARK: - Game-Specific Haptics

    /// Light haptic for clue submission
    func clueSubmitted()

    /// Medium haptic for vote selection
    func voteSelected()

    /// Success haptic when imposter is caught
    func imposterCaught()

    /// Error haptic when imposter escapes
    func imposterEscaped()

    /// Light haptic for button taps
    func buttonTap()

    /// Heavy haptic for game start
    func gameStarted()

    /// Success haptic for round completion
    func roundCompleted()

    // MARK: - Preparation

    /// Prepares the haptic generators for immediate use.
    /// Call before a known haptic event for optimal responsiveness.
    func prepare()
}

// MARK: - HapticImpactStyle

/// Impact haptic intensity styles
enum HapticImpactStyle: Sendable {
    case light
    case medium
    case heavy
    case soft
    case rigid

    /// Converts to UIKit's FeedbackStyle
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        case .soft: return .soft
        case .rigid: return .rigid
        }
    }
}

// MARK: - HapticNotificationType

/// Notification haptic types
enum HapticNotificationType: Sendable {
    case success
    case warning
    case error

    /// Converts to UIKit's FeedbackType
    var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }
}
