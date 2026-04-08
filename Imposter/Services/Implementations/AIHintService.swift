//
//  AIHintService.swift
//  Imposter
//
//  AI-backed hint generation using Foundation Models.
//

import Foundation
import OSLog

// MARK: - AIHintService

/// Production hint service that wraps the existing Foundation Models hint generator.
@MainActor
final class AIHintService: HintServiceProtocol {

    private let logger = Logger(subsystem: "com.imposter", category: "AIHintService")

    func generateHint(for secretWord: String, category: String) async throws -> String {
        do {
            return try await HintGenerator.generateHint(for: secretWord, category: category)
        } catch let error as HintGenerator.HintGeneratorError {
            switch error {
            case .notAvailable(let reason):
                logger.warning("Hint generation unavailable: \(reason)")
                throw HintServiceError.notAvailable(reason: reason)

            case .generationFailed:
                logger.error("Hint generation failed for word '\(secretWord)'")
                throw HintServiceError.generationFailed(underlying: error)
            }
        } catch {
            logger.error("Hint generation failed: \(error.localizedDescription)")
            throw HintServiceError.generationFailed(underlying: error)
        }
    }
}
