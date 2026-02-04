//
//  ImageServiceProtocol.swift
//  Imposter
//
//  Protocol for AI image generation services.
//

import Foundation
import UIKit

// MARK: - ImageServiceProtocol

/// Protocol defining image generation capabilities.
/// Implementations can generate images using ImagePlayground or other AI services.
protocol ImageServiceProtocol: Sendable {

    // MARK: - Availability

    /// Whether image generation is available on this device
    var isAvailable: Bool { get }

    /// Available image generation styles
    var availableStyles: [ImageGenerationStyle] { get }

    /// User-friendly reason why generation is unavailable (if applicable)
    var unavailabilityReason: String? { get }

    // MARK: - Generation

    /// Generates an image for the given word.
    /// - Parameters:
    ///   - word: The word to generate an image for
    ///   - category: The word category (used for safe prompt generation)
    ///   - style: The preferred image style
    /// - Returns: Generated image, or nil if generation fails gracefully
    /// - Throws: `ImageServiceError` for unrecoverable errors
    func generateImage(
        for word: String,
        category: String,
        style: ImageGenerationStyle?
    ) async throws -> UIImage?

    // MARK: - Cache Management

    /// Clears any cached images
    func clearCache()
}

// MARK: - ImageGenerationStyle

/// Available styles for image generation
enum ImageGenerationStyle: String, Sendable, CaseIterable {
    case illustration
    case animation
    case sketch

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - ImageServiceError

/// Errors that can occur during image generation
enum ImageServiceError: LocalizedError, Sendable {
    /// Image generation is not available on this device
    case notAvailable(reason: String?)

    /// No styles are available for generation
    case noStylesAvailable

    /// Image generation failed
    case generationFailed(underlying: Error?)

    /// Image generation timed out
    case timeout

    /// Device does not meet requirements
    case deviceNotSupported

    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return reason ?? "Image generation is not available"
        case .noStylesAvailable:
            return "No image styles are available"
        case .generationFailed(let error):
            if let error = error {
                return "Image generation failed: \(error.localizedDescription)"
            }
            return "Image generation failed"
        case .timeout:
            return "Image generation timed out"
        case .deviceNotSupported:
            return "This device does not support image generation"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAvailable, .deviceNotSupported:
            return "The game will continue without generated images"
        case .noStylesAvailable:
            return "Try again later"
        case .generationFailed, .timeout:
            return "The game will continue without the image"
        }
    }
}
