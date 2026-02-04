//
//  AppEnvironment.swift
//  Imposter
//
//  Dependency injection container for testability.
//  Holds all service protocols and provides live/preview/test factories.
//

import Foundation
import Observation
import SwiftUI
import UIKit

// MARK: - AppEnvironment

/// Central dependency injection container.
/// Provides all service dependencies to the app and enables testing by swapping implementations.
@Observable
@MainActor
final class AppEnvironment {

    // MARK: - Services

    /// Word selection and generation service
    let wordService: any WordServiceProtocol

    /// Image generation service
    let imageService: any ImageServiceProtocol

    /// Persistent storage service
    let storageService: any StorageServiceProtocol

    /// Haptic feedback service
    let hapticsService: any HapticsServiceProtocol

    // MARK: - Initialization

    init(
        wordService: any WordServiceProtocol,
        imageService: any ImageServiceProtocol,
        storageService: any StorageServiceProtocol,
        hapticsService: any HapticsServiceProtocol
    ) {
        self.wordService = wordService
        self.imageService = imageService
        self.storageService = storageService
        self.hapticsService = hapticsService
    }

    // MARK: - Factory Methods

    /// Creates the production environment with real implementations.
    static func live() -> AppEnvironment {
        AppEnvironment(
            wordService: AIWordService(),
            imageService: ImageService(),
            storageService: StorageService(),
            hapticsService: HapticsService()
        )
    }

    /// Creates a production environment without AI features.
    /// Uses random word selection instead of AI generation.
    static func liveWithoutAI() -> AppEnvironment {
        AppEnvironment(
            wordService: WordService(),
            imageService: ImageService(),
            storageService: StorageService(),
            hapticsService: HapticsService()
        )
    }

    /// Creates a preview environment with mock implementations.
    /// Used for SwiftUI Previews.
    static func preview() -> AppEnvironment {
        AppEnvironment(
            wordService: MockWordService(),
            imageService: MockImageService(),
            storageService: MockStorageService(),
            hapticsService: MockHapticsService()
        )
    }

    /// Creates a test environment with configurable mock implementations.
    /// - Parameters:
    ///   - wordService: Custom word service (defaults to mock)
    ///   - imageService: Custom image service (defaults to mock)
    ///   - storageService: Custom storage service (defaults to mock)
    ///   - hapticsService: Custom haptics service (defaults to mock)
    /// - Returns: Configured test environment
    static func test(
        wordService: (any WordServiceProtocol)? = nil,
        imageService: (any ImageServiceProtocol)? = nil,
        storageService: (any StorageServiceProtocol)? = nil,
        hapticsService: (any HapticsServiceProtocol)? = nil
    ) -> AppEnvironment {
        AppEnvironment(
            wordService: wordService ?? MockWordService(),
            imageService: imageService ?? MockImageService(),
            storageService: storageService ?? MockStorageService(),
            hapticsService: hapticsService ?? MockHapticsService()
        )
    }
}

// MARK: - Environment Key

/// SwiftUI environment key for AppEnvironment
struct AppEnvironmentKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AppEnvironment = .preview()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
