//
//  AccessibilityPreferences.swift
//  Imposter
//
//  App-owned accessibility preferences layered on top of system settings.
//

import SwiftUI

// MARK: - Accessibility Preferences

struct AccessibilityPreferences: Sendable, Equatable {
    var forceReduceMotion: Bool
    var forceReduceTransparency: Bool

    static let system = AccessibilityPreferences(
        forceReduceMotion: false,
        forceReduceTransparency: false
    )
}

private struct AccessibilityPreferencesKey: EnvironmentKey {
    static let defaultValue: AccessibilityPreferences = .system
}

extension EnvironmentValues {
    var imposterAccessibilityPreferences: AccessibilityPreferences {
        get { self[AccessibilityPreferencesKey.self] }
        set { self[AccessibilityPreferencesKey.self] = newValue }
    }
}
