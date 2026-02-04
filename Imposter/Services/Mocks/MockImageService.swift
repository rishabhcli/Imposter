//
//  MockImageService.swift
//  Imposter
//
//  Mock image service for testing and previews.
//

import Foundation
import UIKit

// MARK: - MockImageService

/// Mock implementation of ImageServiceProtocol for testing and previews.
/// Allows configuring responses and tracking method calls.
final class MockImageService: ImageServiceProtocol, @unchecked Sendable {

    // MARK: - Configuration

    /// Whether image generation is available
    var available: Bool = true

    /// Available styles
    var styles: [ImageGenerationStyle] = [.illustration, .animation, .sketch]

    /// Reason for unavailability
    var reason: String? = nil

    /// The image to return from generateImage
    var generateImageResult: Result<UIImage?, Error> = .success(nil)

    /// Delay to simulate async work (in seconds)
    var simulatedDelay: TimeInterval = 0

    // MARK: - Call Tracking

    /// Number of times generateImage was called
    private(set) var generateImageCallCount = 0

    /// Last word passed to generateImage
    private(set) var lastWord: String?

    /// Last category passed to generateImage
    private(set) var lastCategory: String?

    /// Last style passed to generateImage
    private(set) var lastStyle: ImageGenerationStyle?

    /// Number of times clearCache was called
    private(set) var clearCacheCallCount = 0

    // MARK: - ImageServiceProtocol

    var isAvailable: Bool {
        available
    }

    var availableStyles: [ImageGenerationStyle] {
        styles
    }

    var unavailabilityReason: String? {
        reason
    }

    func generateImage(
        for word: String,
        category: String,
        style: ImageGenerationStyle?
    ) async throws -> UIImage? {
        generateImageCallCount += 1
        lastWord = word
        lastCategory = category
        lastStyle = style

        if simulatedDelay > 0 {
            try await Task.sleep(for: .seconds(simulatedDelay))
        }

        return try generateImageResult.get()
    }

    func clearCache() {
        clearCacheCallCount += 1
    }

    // MARK: - Test Helpers

    /// Resets all call tracking
    func reset() {
        generateImageCallCount = 0
        lastWord = nil
        lastCategory = nil
        lastStyle = nil
        clearCacheCallCount = 0
    }

    /// Configures the mock to fail generateImage
    func failGenerateImage(with error: Error) {
        generateImageResult = .failure(error)
    }

    /// Configures the mock to return a specific image
    func returnImage(_ image: UIImage?) {
        generateImageResult = .success(image)
    }

    /// Creates a test image with the specified color
    static func testImage(color: UIColor = .red, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
