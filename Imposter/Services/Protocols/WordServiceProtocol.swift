//
//  WordServiceProtocol.swift
//  Imposter
//
//  Protocol for word selection and generation services.
//

import Foundation

// MARK: - WordServiceProtocol

/// Protocol defining word selection and generation capabilities.
/// Implementations can select from word packs or generate words using AI.
protocol WordServiceProtocol: Sendable {

    // MARK: - Word Selection

    /// Selects a random word based on the provided settings.
    /// - Parameters:
    ///   - categories: Categories to select from (nil = all categories)
    ///   - difficulty: Difficulty level for filtering words
    /// - Returns: A randomly selected word
    /// - Throws: `WordServiceError` if selection fails
    func selectWord(
        from categories: [String]?,
        difficulty: GameSettings.Difficulty
    ) async throws -> String

    /// Generates a word related to the given prompt using AI.
    /// - Parameter prompt: User's input theme or prompt
    /// - Returns: A generated word related to the prompt
    /// - Throws: `WordServiceError` if generation fails
    func generateWord(from prompt: String) async throws -> String

    // MARK: - Category Information

    /// All available word categories
    var availableCategories: [String] { get }

    /// Returns the word count for a specific category
    /// - Parameter category: The category name
    /// - Returns: Number of words in the category
    func wordCount(for category: String) -> Int

    // MARK: - Availability

    /// Whether AI word generation is available on this device
    var isAIGenerationAvailable: Bool { get }

    /// User-friendly reason why AI generation is unavailable (if applicable)
    var aiUnavailabilityReason: String? { get }
}

// MARK: - WordServiceError

/// Errors that can occur during word service operations
enum WordServiceError: LocalizedError, Sendable {
    /// No words available for the selected categories/difficulty
    case noWordsAvailable(categories: [String], difficulty: GameSettings.Difficulty)

    /// Failed to load word pack from disk
    case wordPackLoadingFailed(category: String, underlying: Error?)

    /// AI word generation is not available
    case aiNotAvailable(reason: String?)

    /// AI generated an invalid response
    case aiInvalidResponse

    /// AI generated the same word as the prompt
    case aiSameAsPrompt

    /// AI generation timed out
    case aiTimeout

    var errorDescription: String? {
        switch self {
        case .noWordsAvailable(let categories, let difficulty):
            let categoryText = categories.isEmpty ? "all categories" : categories.joined(separator: ", ")
            return "No words available for \(categoryText) at \(difficulty.rawValue) difficulty"
        case .wordPackLoadingFailed(let category, _):
            return "Failed to load word pack for \(category)"
        case .aiNotAvailable(let reason):
            return reason ?? "AI word generation is not available"
        case .aiInvalidResponse:
            return "AI generated an invalid response"
        case .aiSameAsPrompt:
            return "AI generated the same word as the prompt"
        case .aiTimeout:
            return "AI word generation timed out"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noWordsAvailable:
            return "Try selecting different categories or difficulty"
        case .wordPackLoadingFailed:
            return "The app will use fallback words"
        case .aiNotAvailable:
            return "Use random word selection instead"
        case .aiInvalidResponse, .aiSameAsPrompt:
            return "Try again or use random word selection"
        case .aiTimeout:
            return "Check your connection and try again"
        }
    }
}
