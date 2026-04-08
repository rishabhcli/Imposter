//
//  FallbackHintService.swift
//  Imposter
//
//  Non-AI fallback hint generation.
//

import Foundation

// MARK: - FallbackHintService

/// Fallback hint service that returns the category context directly.
struct FallbackHintService: HintServiceProtocol {
    func generateHint(for secretWord: String, category: String) async throws -> String {
        category
    }
}
