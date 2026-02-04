//
//  ImageService.swift
//  Imposter
//
//  Production implementation of ImageServiceProtocol.
//  Uses ImagePlayground for AI image generation with caching.
//

import Foundation
import ImagePlayground
import OSLog
import UIKit

// MARK: - ImageService

/// Production image service using Apple's ImagePlayground framework.
/// Provides AI-generated images with memory-managed caching.
final class ImageService: ImageServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.imposter", category: "ImageService")
    private let cache = NSCache<NSString, UIImage>()
    private var _availableStyles: [ImageGenerationStyle] = []
    private var _isAvailable: Bool = false
    private var hasCheckedAvailability = false

    // MARK: - Initialization

    init() {
        // Configure cache limits
        cache.countLimit = 5
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    // MARK: - ImageServiceProtocol

    var isAvailable: Bool {
        _isAvailable
    }

    var availableStyles: [ImageGenerationStyle] {
        _availableStyles
    }

    var unavailabilityReason: String? {
        if _isAvailable {
            return nil
        }
        return "Image generation is not available on this device"
    }

    func generateImage(
        for word: String,
        category: String,
        style: ImageGenerationStyle?
    ) async throws -> UIImage? {
        logger.debug("Generating image for word: \(word), category: \(category)")

        // Check cache first
        let cacheKey = "\(word)-\(category)-\(style?.rawValue ?? "default")" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            logger.debug("Returning cached image for: \(word)")
            return cached
        }

        do {
            // Create ImagePlayground creator
            let creator = try await ImageCreator()

            // Update availability info
            await updateAvailability(from: creator)

            guard !creator.availableStyles.isEmpty else {
                logger.warning("No image styles available")
                throw ImageServiceError.noStylesAvailable
            }

            // Select style
            let playgroundStyle = selectPlaygroundStyle(
                preferred: style,
                available: creator.availableStyles
            )

            // Try generating with primary prompt first
            let imagePrompt = createSafePrompt(for: word, category: category)
            
            if let image = try await attemptGeneration(
                creator: creator,
                prompt: imagePrompt,
                style: playgroundStyle,
                cacheKey: cacheKey
            ) {
                return image
            }
            
            // If that fails, try with a more abstract fallback prompt
            let fallbackPrompt = createFallbackPrompt(for: word, category: category)
            logger.debug("Retrying with fallback prompt: \(fallbackPrompt)")
            
            if let image = try await attemptGeneration(
                creator: creator,
                prompt: fallbackPrompt,
                style: playgroundStyle,
                cacheKey: cacheKey
            ) {
                return image
            }

            logger.warning("No images generated for: \(word)")
            return nil

        } catch let error as ImageServiceError {
            throw error
        } catch {
            logger.error("Image generation failed: \(error.localizedDescription)")
            // Return nil instead of throwing - allows game to continue without image
            return nil
        }
    }
    
    private func attemptGeneration(
        creator: ImageCreator,
        prompt: String,
        style: ImagePlaygroundStyle,
        cacheKey: NSString
    ) async throws -> UIImage? {
        let concepts: [ImagePlaygroundConcept] = [.text(prompt)]
        
        logger.debug("ImagePlayground: Generating image with prompt: '\(prompt)'")
        
        do {
            let imageSequence = creator.images(
                for: concepts,
                style: style,
                limit: 1
            )
            
            for try await generatedImage in imageSequence {
                let uiImage = UIImage(cgImage: generatedImage.cgImage)
                cache.setObject(uiImage, forKey: cacheKey)
                logger.info("Successfully generated image")
                return uiImage
            }
        } catch {
            // Check if it's the person identity error
            let errorString = String(describing: error)
            if errorString.contains("conceptsRequirePersonIdentity") {
                logger.warning("ImagePlayground requires person identity - will try fallback")
                return nil
            }
            throw error
        }
        
        return nil
    }

    func clearCache() {
        cache.removeAllObjects()
        logger.debug("Image cache cleared")
    }

    // MARK: - Private Methods

    @MainActor
    private func updateAvailability(from creator: ImageCreator) {
        _isAvailable = true
        _availableStyles = creator.availableStyles.compactMap { playgroundStyle in
            if playgroundStyle == .illustration {
                return .illustration
            } else if playgroundStyle == .animation {
                return .animation
            } else if playgroundStyle == .sketch {
                return .sketch
            } else {
                return nil
            }
        }
        hasCheckedAvailability = true
    }

    private func selectPlaygroundStyle(
        preferred: ImageGenerationStyle?,
        available: [ImagePlaygroundStyle]
    ) -> ImagePlaygroundStyle {
        // Try preferred style first
        if let preferred = preferred {
            switch preferred {
            case .illustration where available.contains(.illustration):
                return .illustration
            case .animation where available.contains(.animation):
                return .animation
            case .sketch where available.contains(.sketch):
                return .sketch
            default:
                break
            }
        }

        // Fall back to priority order - prefer Animation style for fun party game aesthetic
        if available.contains(.animation) {
            return .animation
        } else if available.contains(.illustration) {
            return .illustration
        } else if available.contains(.sketch) {
            return .sketch
        }

        // Use first available
        return available.first ?? .animation
    }

    private func createSafePrompt(for word: String, category: String) -> String {
        // Categories that might have people or IP issues
        let sensitiveCategories = ["People", "Movies", "Music", "Sports"]

        if sensitiveCategories.contains(category) {
            // Use abstract/symbolic imagery instead with animation-friendly style
            switch category {
            case "People":
                return "A friendly cartoon character silhouette with sparkles and colorful aura, cute animated style"
            case "Movies":
                return "A cute cartoon movie camera with film reels, sparkly cinema lights, happy popcorn character"
            case "Music":
                return "Happy musical notes dancing in colorful rainbow waves, cute cartoon instruments with faces"
            case "Sports":
                return "Playful cartoon sports equipment bouncing around, dynamic motion lines, bright cheerful colors"
            default:
                return "Cute colorful cartoon shapes representing: \(category)"
            }
        }

        // Safe object-focused prompt - explicitly avoid any person implications
        return "A single \(word) object floating in space, cute cartoon style illustration, no people, no hands, bright colorful background, simple clean design"
    }
    
    private func createFallbackPrompt(for word: String, category: String) -> String {
        // Ultra-safe abstract prompt that should never require person identity
        return "Abstract colorful geometric shapes and patterns inspired by the concept of '\(category)', vibrant colors, playful design, cartoon illustration style, no people, no faces, no characters"
    }
}
