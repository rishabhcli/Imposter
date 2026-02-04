//
//  MockWordService.swift
//  Imposter
//
//  Mock word service for testing and previews.
//

import Foundation

// MARK: - MockWordService

/// Mock implementation of WordServiceProtocol for testing and previews.
/// Allows configuring responses and tracking method calls.
final class MockWordService: WordServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// The word to return from selectWord
    var selectWordResult: Result<String, Error> = .success("Elephant")

    /// The word to return from generateWord
    var generateWordResult: Result<String, Error> = .success("Giraffe")

    /// Categories to return
    var categories: [String] = ["Animals", "Technology", "Objects", "People", "Movies"]

    /// Word counts per category
    var wordCounts: [String: Int] = [
        "Animals": 100,
        "Technology": 100,
        "Objects": 100,
        "People": 100,
        "Movies": 100
    ]

    /// Whether AI generation is available
    var aiAvailable: Bool = true

    /// Reason for AI unavailability
    var aiReason: String? = nil

    /// Delay to simulate async work (in seconds)
    var simulatedDelay: TimeInterval = 0

    // MARK: - Call Tracking

    /// Number of times selectWord was called
    private(set) var selectWordCallCount = 0

    /// Number of times generateWord was called
    private(set) var generateWordCallCount = 0

    /// Last categories passed to selectWord
    private(set) var lastSelectCategories: [String]?

    /// Last difficulty passed to selectWord
    private(set) var lastSelectDifficulty: GameSettings.Difficulty?

    /// Last prompt passed to generateWord
    private(set) var lastGeneratePrompt: String?

    // MARK: - WordServiceProtocol

    var availableCategories: [String] {
        categories
    }

    var isAIGenerationAvailable: Bool {
        aiAvailable
    }

    var aiUnavailabilityReason: String? {
        aiReason
    }

    func selectWord(
        from categories: [String]?,
        difficulty: GameSettings.Difficulty
    ) async throws -> String {
        selectWordCallCount += 1
        lastSelectCategories = categories
        lastSelectDifficulty = difficulty

        if simulatedDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedDelay))
        }

        return try selectWordResult.get()
    }

    func generateWord(from prompt: String) async throws -> String {
        generateWordCallCount += 1
        lastGeneratePrompt = prompt

        if simulatedDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedDelay))
        }

        return try generateWordResult.get()
    }

    func wordCount(for category: String) -> Int {
        wordCounts[category] ?? 0
    }

    // MARK: - Test Helpers

    /// Resets all call tracking
    func reset() {
        selectWordCallCount = 0
        generateWordCallCount = 0
        lastSelectCategories = nil
        lastSelectDifficulty = nil
        lastGeneratePrompt = nil
    }

    /// Configures the mock to fail selectWord
    func failSelectWord(with error: Error) {
        selectWordResult = .failure(error)
    }

    /// Configures the mock to fail generateWord
    func failGenerateWord(with error: Error) {
        generateWordResult = .failure(error)
    }

    /// Configures the mock to return a specific word from selectWord
    func returnWord(_ word: String) {
        selectWordResult = .success(word)
    }

    /// Configures the mock to return a specific word from generateWord
    func returnGeneratedWord(_ word: String) {
        generateWordResult = .success(word)
    }
}
