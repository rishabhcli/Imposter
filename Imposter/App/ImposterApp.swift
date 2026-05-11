//
//  ImposterApp.swift
//  Imposter
//
//  Main entry point for the Imposter party game.
//

import SwiftUI

@main
struct ImposterApp: App {
    @State private var appEnvironment: AppEnvironment
    @State private var gameStore: GameStore

    init() {
        let appEnvironment = ProcessInfo.processInfo.arguments.contains("-ui-testing")
            ? AppEnvironment.test()
            : AppEnvironment.live()
        _appEnvironment = State(initialValue: appEnvironment)
        _gameStore = State(initialValue: appEnvironment.makeGameStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameStore)
                .environment(\.appEnvironment, appEnvironment)
                .modifier(UITestingAccessibilityOverrides())
        }
    }
}

// MARK: - UI Testing Accessibility Overrides

private struct UITestingAccessibilityOverrides: ViewModifier {
    private let arguments = ProcessInfo.processInfo.arguments

    func body(content: Content) -> some View {
        content
            .environment(\.imposterAccessibilityPreferences, preferences)
    }

    private var preferences: AccessibilityPreferences {
        AccessibilityPreferences(
            forceReduceMotion: arguments.contains("-ui-testing-reduce-motion"),
            forceReduceTransparency: arguments.contains("-ui-testing-reduce-transparency")
        )
    }
}
