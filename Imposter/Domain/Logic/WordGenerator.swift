//
//  WordGenerator.swift
//  Imposter
//
//  Uses Apple Foundation Models to generate secret words from user prompts.
//

import Foundation
import FoundationModels

// MARK: - WordGenerator

/// Generates secret words using Apple's on-device Foundation Models
@MainActor
enum WordGenerator {

    /// Reference to the system language model for availability checking
    private static let model = SystemLanguageModel.default

    /// Generates a single word related to the given prompt using Foundation Models
    /// - Parameter prompt: User's input prompt/theme
    /// - Returns: A generated word related to the prompt (NOT the prompt itself)
    static func generateWord(from prompt: String) async throws -> String {
        // Check availability before attempting generation
        guard case .available = model.availability else {
            throw WordGeneratorError.notAvailable(reason: unavailabilityReason)
        }

        // Create the language model session
        let session = LanguageModelSession()

        // Create a prompt that asks the AI to generate a RELATED word, not the exact input
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

        // Generate response using the language model
        let response = try await session.respond(to: fullPrompt)

        // Extract the text from the response
        let responseText = response.content

        // Clean up the response - remove quotes, extra whitespace, punctuation
        var cleanedWord = responseText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ":", with: "")

        // Take only the first line if multiple lines
        if let firstLine = cleanedWord.split(separator: "\n").first {
            cleanedWord = String(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // If the response is empty or too long, throw error
        guard !cleanedWord.isEmpty, cleanedWord.count <= 50 else {
            throw WordGeneratorError.invalidResponse
        }

        // Make sure we don't return the exact prompt
        if cleanedWord.lowercased() == prompt.lowercased() {
            throw WordGeneratorError.sameAsPrompt
        }

        return cleanedWord.capitalized
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

        var errorDescription: String? {
            switch self {
            case .notAvailable(let reason):
                return reason ?? "Foundation Models not available on this device"
            case .invalidResponse:
                return "Generated response was invalid"
            case .sameAsPrompt:
                return "Generated word was same as prompt"
            }
        }
    }
}
