//
//  WordGenerator.swift
//  Imposter
//
//  Uses Apple Foundation Models to generate secret words from user prompts.
//

import Foundation
import FoundationModels

// MARK: - GeneratedSecretWord

/// Structured output for guided generation. Constraining the model to this
/// schema means it returns just the word, so we avoid fragile string parsing
/// of free-form prose (prefixes, bullets, quotes, trailing sentences).
@Generable(description: "A single secret word for a party guessing game")
struct GeneratedSecretWord {
    @Guide(description: "A concrete, family-friendly noun related to the theme but never the theme word itself. One to three words, no punctuation or explanation.")
    var word: String
}

// MARK: - WordGenerator

/// Generates secret words using Apple's on-device Foundation Models.
///
/// This is the single source of truth for prompt-based word generation;
/// ``AIWordService`` wraps it to satisfy `WordServiceProtocol`.
@MainActor
enum WordGenerator {

    /// Reference to the system language model for availability checking
    private static let model = SystemLanguageModel.default

    /// Static guidance that defines the model's role. Keeping this in the
    /// session `instructions` (rather than concatenated into every prompt)
    /// separates system guidance from untrusted user input and lets the
    /// framework optimize for it.
    private static let instructions = """
    You generate secret words for a party guessing game called Imposter.
    Given a theme, produce one concrete, family-friendly noun that is related \
    to the theme but is never the theme word itself.
    Prefer fun, specific, guessable things. Keep it to one to three words.
    """

    /// Generates a single word related to the given prompt using Foundation Models.
    /// - Parameter prompt: User's input prompt/theme
    /// - Returns: A generated word related to the prompt (NOT the prompt itself)
    static func generateWord(from prompt: String) async throws -> String {
        // Check availability before attempting generation
        guard case .available = model.availability else {
            throw WordGeneratorError.notAvailable(reason: unavailabilityReason)
        }

        // Input-side guardrail: reject blatant prompt-injection / unsafe themes
        // and oversized input before they ever reach the model. This both keeps
        // attacks out of the pipeline and gives the user a fast, clear failure.
        let sanitizedPrompt: String
        switch GeneratedWordPolicy.validateUserPrompt(prompt) {
        case .success(let clean):
            sanitizedPrompt = clean
        case .failure:
            throw WordGeneratorError.unsafePrompt
        }

        let session = LanguageModelSession(instructions: instructions)

        let candidate: String
        do {
            // Guided generation: the model fills in `GeneratedSecretWord.word`,
            // constrained by the schema, so there's no free-form prose to clean up.
            let response = try await session.respond(
                to: "Theme: \(sanitizedPrompt)",
                generating: GeneratedSecretWord.self
            )
            candidate = response.content.word
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation, .refusal:
                // The theme tripped the safety guardrails (or the model declined).
                throw WordGeneratorError.unsafePrompt
            default:
                throw WordGeneratorError.invalidResponse
            }
        }

        // Deterministic safety net: even with a constrained schema the model can
        // still echo the theme or emit an unplayable value, so keep validating.
        switch GeneratedWordPolicy.validate(rawResponse: candidate, prompt: sanitizedPrompt) {
        case .success(let cleanedWord):
            return cleanedWord
        case .failure(.promptEcho):
            throw WordGeneratorError.sameAsPrompt
        case .failure(.unsafeContent):
            // A term slipped past the model's guardrails — treat it like an
            // unsafe prompt so the caller falls back to a curated pack word.
            throw WordGeneratorError.unsafePrompt
        case .failure:
            throw WordGeneratorError.invalidResponse
        }
    }

    /// The current availability status of Foundation Models
    static var availability: SystemLanguageModel.Availability {
        model.availability
    }

    /// Checks if Foundation Models are available and ready on this device
    static var isAvailable: Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }

    /// Returns a user-friendly message explaining why the model is unavailable
    static var unavailabilityReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support AI word generation"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable on-device AI in Settings"
        case .unavailable(.modelNotReady):
            return "AI model is still downloading. Try again later."
        case .unavailable:
            return "AI word generation is currently unavailable"
        }
    }

    /// Error types for word generation
    enum WordGeneratorError: LocalizedError {
        case notAvailable(reason: String?)
        case invalidResponse
        case sameAsPrompt
        case unsafePrompt

        var errorDescription: String? {
            switch self {
            case .notAvailable(let reason):
                return reason ?? "Foundation Models not available on this device"
            case .invalidResponse:
                return "Generated response was invalid"
            case .sameAsPrompt:
                return "Generated word was same as prompt"
            case .unsafePrompt:
                return "That theme can't be used. Try a different one."
            }
        }
    }
}
