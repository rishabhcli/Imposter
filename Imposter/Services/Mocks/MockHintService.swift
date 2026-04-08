//
//  MockHintService.swift
//  Imposter
//
//  Mock hint service for testing and previews.
//

import Foundation

// MARK: - MockHintService

/// Mock implementation of HintServiceProtocol for tests and previews.
final class MockHintService: HintServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// The hint to return from generateHint.
    var generateHintResult: Result<String, Error> = .success("Animals")

    /// Delay to simulate async work.
    var simulatedDelay: TimeInterval = 0

    // MARK: - Call Tracking

    private(set) var generateHintCallCount = 0
    private(set) var lastSecretWord: String?
    private(set) var lastCategory: String?

    // MARK: - HintServiceProtocol

    func generateHint(for secretWord: String, category: String) async throws -> String {
        generateHintCallCount += 1
        lastSecretWord = secretWord
        lastCategory = category

        if simulatedDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedDelay))
        }

        return try generateHintResult.get()
    }

    // MARK: - Test Helpers

    func reset() {
        generateHintCallCount = 0
        lastSecretWord = nil
        lastCategory = nil
    }

    func failGenerateHint(with error: Error) {
        generateHintResult = .failure(error)
    }

    func returnHint(_ hint: String) {
        generateHintResult = .success(hint)
    }
}
