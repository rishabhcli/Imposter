//
//  HintServiceProtocol.swift
//  Imposter
//
//  Protocol for imposter hint generation services.
//

import Foundation

// MARK: - HintServiceProtocol

/// Protocol defining hint generation for the imposter.
/// Implementations can use AI-backed generation or safe fallbacks.
protocol HintServiceProtocol: Sendable {

    /// Generates a hint for the imposter using the secret word and category context.
    /// - Parameters:
    ///   - secretWord: The secret word known to non-imposters
    ///   - category: The category or prompt context for the round
    /// - Returns: A short hint to help the imposter participate
    func generateHint(for secretWord: String, category: String) async throws -> String
}

// MARK: - HintServiceError

/// Errors that can occur during hint generation.
enum HintServiceError: LocalizedError, Sendable {
    case notAvailable(reason: String?)
    case generationFailed(underlying: Error?)

    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return reason ?? "Hint generation is not available"

        case .generationFailed(let underlying):
            if let underlying {
                return "Hint generation failed: \(underlying.localizedDescription)"
            }
            return "Hint generation failed"
        }
    }
}
