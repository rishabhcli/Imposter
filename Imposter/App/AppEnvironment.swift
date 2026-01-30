//
//  AppEnvironment.swift
//  Imposter
//
//  Dependency injection container for testability.
//

import Foundation

/// Environment container for dependency injection
/// Allows swapping implementations for testing
struct AppEnvironment: Sendable {
    /// Word selection service
    let wordSelector: WordSelectorProtocol

    /// Default environment with production implementations
    static let live = AppEnvironment(
        wordSelector: LiveWordSelector()
    )

    /// Test environment with mock implementations
    static let test = AppEnvironment(
        wordSelector: MockWordSelector()
    )
}

// MARK: - Word Selector Protocol

/// Protocol for word selection to allow mocking in tests
protocol WordSelectorProtocol: Sendable {
    func selectWord(from settings: GameSettings) -> String
}

/// Production word selector
struct LiveWordSelector: WordSelectorProtocol {
    func selectWord(from settings: GameSettings) -> String {
        WordSelector.selectWord(from: settings)
    }
}

/// Mock word selector for testing
struct MockWordSelector: WordSelectorProtocol {
    var fixedWord: String = "TestWord"

    func selectWord(from settings: GameSettings) -> String {
        fixedWord
    }
}
