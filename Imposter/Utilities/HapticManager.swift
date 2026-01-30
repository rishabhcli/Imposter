//
//  HapticManager.swift
//  Imposter
//
//  Centralized haptic feedback management.
//

import UIKit

// MARK: - HapticManager

/// Provides centralized haptic feedback for the app.
/// All haptic methods are safe to call - they handle errors gracefully.
enum HapticManager {

    // MARK: - Generators

    /// Cached impact generator for light feedback
    private static let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)

    /// Cached impact generator for medium feedback
    private static let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    /// Cached impact generator for heavy feedback
    private static let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    /// Notification feedback generator
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    /// Selection feedback generator
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Impact Feedback

    /// Plays an impact haptic feedback
    /// - Parameter style: The style of impact feedback
    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            lightImpactGenerator.impactOccurred()
        case .medium:
            mediumImpactGenerator.impactOccurred()
        case .heavy:
            heavyImpactGenerator.impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        @unknown default:
            mediumImpactGenerator.impactOccurred()
        }
    }

    // MARK: - Notification Feedback

    /// Plays a notification haptic feedback
    /// - Parameter type: The type of notification feedback
    static func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    // MARK: - Selection Feedback

    /// Plays a selection changed haptic feedback
    static func playSelection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Game-Specific Haptics

    /// Light haptic for clue submission
    static func clueSubmitted() {
        playImpact(.light)
    }

    /// Medium haptic for vote selection
    static func voteSelected() {
        playImpact(.medium)
    }

    /// Success haptic when imposter is caught
    static func imposterCaught() {
        playNotification(.success)
    }

    /// Error haptic when imposter escapes
    static func imposterEscaped() {
        playNotification(.error)
    }

    /// Light haptic for button taps
    static func buttonTap() {
        playImpact(.light)
    }

    /// Heavy haptic for game start
    static func gameStarted() {
        playImpact(.heavy)
    }

    /// Success haptic for round completion
    static func roundCompleted() {
        playNotification(.success)
    }

    // MARK: - Prepare

    /// Prepares the haptic generators for immediate use
    /// Call this before a known haptic event for optimal responsiveness
    static func prepare() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
