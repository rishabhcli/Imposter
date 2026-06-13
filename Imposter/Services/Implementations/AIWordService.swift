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

        // Check availability
        guard isAIGenerationAvailable else {
            logger.warning("AI not available: \(self.aiUnavailabilityReason ?? "unknown")")
            throw WordServiceError.aiNotAvailable(reason: aiUnavailabilityReason)
        }

        do {
            // Create language model session
            let session = LanguageModelSession()

            // Create prompt for word generation
            let fullPrompt = """
            You are a word generator for a party guessing game called Imposter.
            Given a theme or topic, respond with ONLY a single word or very short phrase (2-3 words max) that is RELATED to the theme.

            IMPORTANT RULES:
            - Respond with ONLY the word, nothing else
            - Do NOT use the exact word(s) from the input
            - Choose something fun, specific, and guessable
            - Keep it appropriate for all ages
            - The word should be a concrete noun or simple concept
            - No explanations, just the word

            Theme: \(prompt)

            Related word:
            """

            // Generate response
            let response = try await session.respond(to: fullPrompt)
            let responseText = response.content

            switch GeneratedWordPolicy.validate(rawResponse: responseText, prompt: prompt) {
            case .success(let cleanedWord):
                logger.info("AI generated word: \(cleanedWord)")
                return cleanedWord
            case .failure(.promptEcho):
                logger.warning("AI generated same or near-duplicate word as prompt")
                throw WordServiceError.aiSameAsPrompt
            case .failure(let rejection):
                logger.error("AI generated invalid response: \(String(describing: rejection))")
                throw WordServiceError.aiInvalidResponse
            }

        } catch let error as WordServiceError {
            throw error
        } catch {
            logger.error("AI generation failed: \(error.localizedDescription)")
            throw WordServiceError.aiNotAvailable(reason: error.localizedDescription)
        }
    }

    func wordCount(for category: String) -> Int {
        fallbackService.wordCount(for: category)
    }
}
