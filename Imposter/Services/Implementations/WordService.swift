//
//  WordService.swift
//  Imposter
//
//  Production implementation of WordServiceProtocol.
//  Handles word selection from word packs with category and difficulty filtering.
//

import Foundation
import OSLog

// MARK: - WordService

/// Production word service that selects words from bundled word packs.
/// Provides category filtering, difficulty filtering, and fallback handling.
@MainActor
final class WordService: WordServiceProtocol {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.imposter", category: "WordService")

    /// Cache for loaded word packs
    private let packCache: WordPackCache

    /// Fallback words in case all loading fails
    private static let fallbackWords = [
        "Apple", "Banana", "Orange", "Grape", "Lemon",
        "Dog", "Cat", "Bird", "Fish", "Rabbit",
        "Chair", "Table", "Lamp", "Book", "Clock",
        "Phone", "Computer", "Camera", "Keyboard", "Mouse"
    ]

    // MARK: - Initialization

    init() {
        self.packCache = WordPackCache()
    }

    // MARK: - WordServiceProtocol

    var availableCategories: [String] {
        ["Animals", "Technology", "Objects", "People", "Movies"]
    }

    var isAIGenerationAvailable: Bool {
        // This service doesn't provide AI generation
        false
    }

    var aiUnavailabilityReason: String? {
        "Use AIWordService for AI-generated words"
    }

    func selectWord(
        from categories: [String]?,
        difficulty: GameSettings.Difficulty
    ) async throws -> String {
        logger.debug("Selecting word from categories: \(categories?.joined(separator: ", ") ?? "all"), difficulty: \(difficulty.rawValue)")

        // Load word packs
        let packs = loadWordPacks(for: categories)

        guard !packs.isEmpty else {
            logger.warning("No word packs loaded, using fallback")
            return Self.fallbackWords.randomElement() ?? "UNKNOWN"
        }

        // Collect all words from packs
        let allWords = packs.flatMap { $0.words }

        // Filter by difficulty
        let filteredWords: [WordEntry]
        switch difficulty {
        case .easy:
            filteredWords = allWords.filter { $0.difficulty == "easy" }
        case .medium:
            filteredWords = allWords.filter { $0.difficulty == "medium" }
        case .hard:
            filteredWords = allWords.filter { $0.difficulty == "hard" }
        case .mixed:
            filteredWords = allWords
        }

        // Use filtered words if available, otherwise use all
        let finalWords = filteredWords.isEmpty ? allWords : filteredWords

        guard let selected = finalWords.randomElement() else {
            logger.warning("No words found after filtering, using fallback")
            return Self.fallbackWords.randomElement() ?? "UNKNOWN"
        }

        logger.info("Selected word: \(selected.word)")
        return selected.word
    }

    func generateWord(from prompt: String) async throws -> String {
        // This service doesn't support AI generation
        throw WordServiceError.aiNotAvailable(reason: "Use AIWordService for AI-generated words")
    }

    func wordCount(for category: String) -> Int {
        // Synchronously check cached pack
        let fileName = "words_\(category.lowercased())"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(WordPack.self, from: data) else {
            return 0
        }
        return pack.words.count
    }

    // MARK: - Private Methods

    private func loadWordPacks(for categories: [String]?) -> [WordPack] {
        let categoriesToLoad = categories ?? availableCategories
        var packs: [WordPack] = []

        for category in categoriesToLoad {
            if let pack = packCache.getPack(category) {
                packs.append(pack)
            }
        }

        return packs
    }
}

// MARK: - WordPackCache

/// Cache for word packs to avoid redundant loading
/// Uses MainActor to satisfy WordPack's Codable conformance requirements
@MainActor
final class WordPackCache {
    private var loadedPacks: [String: WordPack] = [:]
    private let logger = Logger(subsystem: "com.imposter", category: "WordPackCache")

    func getPack(_ category: String) -> WordPack? {
        // Check cache first
        if let cached = loadedPacks[category] {
            return cached
        }

        // Load from disk
        let fileName = "words_\(category.lowercased())"
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            logger.warning("Word pack file not found: \(fileName).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let pack = try JSONDecoder().decode(WordPack.self, from: data)
            loadedPacks[category] = pack
            logger.debug("Loaded word pack: \(category) with \(pack.words.count) words")
            return pack
        } catch {
            logger.error("Failed to load word pack \(category): \(error.localizedDescription)")
            return nil
        }
    }

    func preloadPacks(_ categories: [String]) {
        for category in categories {
            _ = getPack(category)
        }
    }

    func clearCache() {
        loadedPacks.removeAll()
    }
}
