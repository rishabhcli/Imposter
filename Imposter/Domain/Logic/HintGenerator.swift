//
//  HintGenerator.swift
//  Imposter
//
//  Generates simple category classifications.
//

import Foundation
import FoundationModels

// MARK: - WordCategory

/// Structured output for guided category classification. Constraining the model
/// to this schema returns just the category label, so there's no prose to strip.
@Generable(description: "A broad category for a word")
struct WordCategory {
    @Guide(description: "A one or two word category such as Animal, Food, Place, Object, Person, Activity, Vehicle, or Tool.")
    var category: String
}

// MARK: - HintGenerator

/// Generates category classifications for words
@MainActor
enum HintGenerator {

    // MARK: - Properties

    private static let model = SystemLanguageModel.default

    // MARK: - Error Types

    enum HintGeneratorError: LocalizedError {
        case notAvailable(reason: String)
        case generationFailed

        var errorDescription: String? {
            switch self {
            case .notAvailable(let reason):
                return "Unavailable: \(reason)"
            case .generationFailed:
                return "Generation failed"
            }
        }
    }

    // MARK: - Public API

    /// Classifies a word into a broad category
    static func generateHint(for secretWord: String, category: String) async throws -> String {
        // Check availability
        guard case .available = model.availability else {
            let reason = unavailabilityReason ?? "Unknown"
            throw HintGeneratorError.notAvailable(reason: reason)
        }

        // Super simple - just ask for category
        let session = LanguageModelSession(instructions: """
            Classify words into broad categories.
            Examples: Animal, Food, Place, Object, Person, Activity, Vehicle, Tool
            """)

        let hint: String
        do {
            // Guided generation returns the bare category, so no string cleanup.
            let response = try await session.respond(
                to: "Category for: \(secretWord)",
                generating: WordCategory.self
            )
            hint = response.content.category.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch is LanguageModelSession.GenerationError {
            // Guardrail or refusal on the word — surface as a clean failure
            // so callers can fall back gracefully.
            throw HintGeneratorError.generationFailed
        }

        guard !hint.isEmpty else {
            throw HintGeneratorError.generationFailed
        }

        return hint
    }

    // MARK: - Private

    private static var unavailabilityReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "Device not supported"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "AI not enabled"
        case .unavailable(.modelNotReady):
            return "Model downloading"
        case .unavailable:
            return "Unavailable"
        }
    }
}
