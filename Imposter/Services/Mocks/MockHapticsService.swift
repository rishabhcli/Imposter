//
//  MockHapticsService.swift
//  Imposter
//
//  Mock haptics service for testing and previews.
//

import Foundation

// MARK: - MockHapticsService

/// Mock implementation of HapticsServiceProtocol for testing and previews.
/// Records all haptic events without playing actual haptics.
final class MockHapticsService: HapticsServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    /// All haptic events that have been triggered
    private(set) var events: [HapticEvent] = []

    /// Number of times prepare was called
    private(set) var prepareCallCount = 0

    // MARK: - HapticsServiceProtocol

    func playImpact(_ style: HapticImpactStyle) {
        events.append(.impact(style))
    }

    func playNotification(_ type: HapticNotificationType) {
        events.append(.notification(type))
    }

    func playSelection() {
        events.append(.selection)
    }

    func clueSubmitted() {
        events.append(.clueSubmitted)
    }

    func voteSelected() {
        events.append(.voteSelected)
    }

    func imposterCaught() {
        events.append(.imposterCaught)
    }

    func imposterEscaped() {
        events.append(.imposterEscaped)
    }

    func buttonTap() {
        events.append(.buttonTap)
    }

    func gameStarted() {
        events.append(.gameStarted)
    }

    func roundCompleted() {
        events.append(.roundCompleted)
    }

    func prepare() {
        prepareCallCount += 1
    }

    // MARK: - Test Helpers

    /// Resets all call tracking
    func reset() {
        events.removeAll()
        prepareCallCount = 0
    }

    /// Returns the number of times a specific event was triggered
    func count(of event: HapticEvent) -> Int {
        events.filter { $0 == event }.count
    }

    /// Returns whether a specific event was triggered
    func wasCalled(_ event: HapticEvent) -> Bool {
        events.contains(event)
    }

    /// Returns the last event triggered
    var lastEvent: HapticEvent? {
        events.last
    }
}

// MARK: - HapticEvent

/// Represents a recorded haptic event
enum HapticEvent: Equatable, Sendable {
    case impact(HapticImpactStyle)
    case notification(HapticNotificationType)
    case selection
    case clueSubmitted
    case voteSelected
    case imposterCaught
    case imposterEscaped
    case buttonTap
    case gameStarted
    case roundCompleted
}
