//
//  HintGenerator.swift
//  Imposter
//
//  Generates simple category classifications.
//

import Foundation
import FoundationModels

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
            Reply with just 1-2 words.
            Examples: Animal, Food, Place, Object, Person, Activity, Vehicle, Tool
            """)

        let prompt = "Category for: \(secretWord)"

        let response = try await session.respond(to: prompt)
        let hint = response.content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ".", with: "")

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
