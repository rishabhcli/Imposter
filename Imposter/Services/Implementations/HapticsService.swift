//
//  HapticsService.swift
//  Imposter
//
//  Production implementation of HapticsServiceProtocol.
//  Provides haptic feedback using UIKit's feedback generators.
//

import Foundation
import UIKit

// MARK: - HapticsService

/// Production haptics service using UIKit feedback generators.
/// Provides optimized haptic feedback with pre-prepared generators.
final class HapticsService: HapticsServiceProtocol, Sendable {

    // MARK: - Generators

    /// Cached impact generator for light feedback
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)

    /// Cached impact generator for medium feedback
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    /// Cached impact generator for heavy feedback
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    /// Notification feedback generator
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// Selection feedback generator
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    init() {
        // Pre-prepare generators for faster response
        prepare()
    }

    // MARK: - HapticsServiceProtocol - Impact Feedback

    func playImpact(_ style: HapticImpactStyle) {
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
        }
    }

    // MARK: - HapticsServiceProtocol - Notification Feedback

    func playNotification(_ type: HapticNotificationType) {
        notificationGenerator.notificationOccurred(type.uiKitType)
    }

    // MARK: - HapticsServiceProtocol - Selection Feedback

    func playSelection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - HapticsServiceProtocol - Game-Specific Haptics

    func clueSubmitted() {
        playImpact(.light)
    }

    func voteSelected() {
        playImpact(.medium)
    }

    func imposterCaught() {
        playNotification(.success)
    }

    func imposterEscaped() {
        playNotification(.error)
    }

    func buttonTap() {
        playImpact(.light)
    }

    func gameStarted() {
        playImpact(.heavy)
    }

    func roundCompleted() {
        playNotification(.success)
    }

    // MARK: - HapticsServiceProtocol - Preparation

    func prepare() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
