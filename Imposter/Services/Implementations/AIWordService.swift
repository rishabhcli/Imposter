//
//  AIWordService.swift
//  Imposter
//
//  AI-powered word generation using Apple Foundation Models.
//  Wraps WordGenerator with WordServiceProtocol interface.
//

import Foundation
import FoundationModels
import OSLog

// MARK: - AIWordService

/// Word service that uses Apple Foundation Models for AI-powered word generation.
/// Falls back to random selection if AI is unavailable.
@MainActor
final class AIWordService: WordServiceProtocol {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.imposter", category: "AIWordService")
    private let fallbackService: WordService
    private let model = SystemLanguageModel.default

    // MARK: - Initialization

    init(fallbackService: WordService? = nil) {
        self.fallbackService = fallbackService ?? WordService()
    }

    // MARK: - WordServiceProtocol

    var availableCategories: [String] {
        fallbackService.availableCategories
    }

    var isAIGenerationAvailable: Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }

    var aiUnavailabilityReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support AI word generation"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            return "AI model is still downloading. Try again later."
        case .unavailable:
            return "AI word generation is currently unavailable"
        }
    }

    func selectWord(
        from categories: [String]?,
        difficulty: GameSettings.Difficulty,
        avoiding avoidedWords: Set<String>
    ) async throws -> String {
        // Delegate to fallback service for random selection
        try await fallbackService.selectWord(
            from: categories,
            difficulty: difficulty,
            avoiding: avoidedWords
        )
    }

    func selectAlternateWord(
        matching secretWord: String,
        from categories: [String]?,
        difficulty: GameSettings.Difficulty,
        avoiding avoidedWords: Set<String>
    ) async throws -> String? {
        try await fallbackService.selectAlternateWord(
            matching: secretWord,
            from: categories,
            difficulty: difficulty,
            avoiding: avoidedWords
        )
    }

    func generateWord(from prompt: String) async throws -> String {
        logger.debug("Generating word from prompt: \(prompt)")

        do {
            // Delegate to the single source of truth, which uses guided
            // generation (@Generable) plus the deterministic safety net.
            let word = try await WordGenerator.generateWord(from: prompt)
            logger.info("AI generated word: \(word)")
            return word
        } catch let error as WordGenerator.WordGeneratorError {
            throw Self.mapGeneratorError(error)
        } catch {
            logger.error("AI generation failed: \(error.localizedDescription)")
            throw WordServiceError.aiNotAvailable(reason: error.localizedDescription)
        }
    }

    /// Translates `WordGenerator` errors into the service-level error vocabulary.
    private static func mapGeneratorError(_ error: WordGenerator.WordGeneratorError) -> WordServiceError {
        switch error {
        case .notAvailable(let reason):
            return .aiNotAvailable(reason: reason)
        case .sameAsPrompt:
            return .aiSameAsPrompt
        case .invalidResponse, .unsafePrompt:
            return .aiInvalidResponse
        }
    }

    func wordCount(for category: String) -> Int {
        fallbackService.wordCount(for: category)
    }
}
