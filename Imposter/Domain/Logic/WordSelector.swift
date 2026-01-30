//
//  WordSelector.swift
//  Imposter
//
//  Word selection logic with category and difficulty filtering.
//

import Foundation

// MARK: - Word Pack Models

/// A word entry in a word pack
struct WordEntry: Codable, Sendable {
    let word: String
    let difficulty: String // "easy", "medium", "hard"
}

/// A category word pack loaded from JSON
struct WordPack: Codable, Sendable {
    let category: String
    let words: [WordEntry]
}

// MARK: - WordSelector

/// Selects words from word packs based on game settings
enum WordSelector {

    // MARK: - Fallback Words

    /// Hardcoded backup words in case JSON loading fails
    private static let fallbackWords = [
        "Apple", "Banana", "Orange", "Grape", "Lemon",
        "Dog", "Cat", "Bird", "Fish", "Rabbit",
        "Chair", "Table", "Lamp", "Book", "Clock",
        "Phone", "Computer", "Camera", "Keyboard", "Mouse"
    ]

    // MARK: - Word Selection

    /// Selects a random word based on game settings
    /// - Parameter settings: The game settings containing category and difficulty preferences
    /// - Returns: A randomly selected word
    static func selectWord(from settings: GameSettings) -> String {
        // Load word packs
        let packs = loadWordPacks()

        guard !packs.isEmpty else {
            return fallbackWords.randomElement() ?? "UNKNOWN"
        }

        // Filter by selected categories
        var filteredPacks = packs
        if let selectedCategories = settings.selectedCategories, !selectedCategories.isEmpty {
            filteredPacks = packs.filter { selectedCategories.contains($0.category) }
        }

        // If no packs match the categories, use all packs
        if filteredPacks.isEmpty {
            filteredPacks = packs
        }

        // Collect all words from filtered packs
        var allWords: [WordEntry] = []
        for pack in filteredPacks {
            allWords.append(contentsOf: pack.words)
        }

        // Filter by difficulty
        let difficultyFiltered: [WordEntry]
        switch settings.wordPackDifficulty {
        case .easy:
            difficultyFiltered = allWords.filter { $0.difficulty == "easy" }
        case .medium:
            difficultyFiltered = allWords.filter { $0.difficulty == "medium" }
        case .hard:
            difficultyFiltered = allWords.filter { $0.difficulty == "hard" }
        case .mixed:
            difficultyFiltered = allWords
        }

        // Use filtered words if available, otherwise use all words
        let finalWords = difficultyFiltered.isEmpty ? allWords : difficultyFiltered

        // Return random word
        if let selected = finalWords.randomElement() {
            return selected.word
        }

        // Ultimate fallback
        return fallbackWords.randomElement() ?? "UNKNOWN"
    }

    // MARK: - Word Pack Loading

    /// Loads all word packs from the bundle
    /// - Returns: Array of WordPack objects
    static func loadWordPacks() -> [WordPack] {
        var packs: [WordPack] = []

        let packFiles = [
            "words_animals",
            "words_technology",
            "words_objects",
            "words_people",
            "words_movies"
        ]

        for fileName in packFiles {
            if let pack = loadWordPack(named: fileName) {
                packs.append(pack)
            }
        }

        return packs
    }

    /// Loads a single word pack from a JSON file
    /// - Parameter name: The file name without extension
    /// - Returns: WordPack if loading succeeds, nil otherwise
    private static func loadWordPack(named name: String) -> WordPack? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("WordSelector: Could not find \(name).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let pack = try JSONDecoder().decode(WordPack.self, from: data)
            return pack
        } catch {
            print("WordSelector: Failed to load \(name).json - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Category Info

    /// Returns all available category names
    static var availableCategories: [String] {
        return [
            "Animals",
            "Technology",
            "Objects",
            "People",
            "Movies"
        ]
    }

    /// Returns word count for a specific category
    static func wordCount(for category: String) -> Int {
        let packs = loadWordPacks()
        return packs.first { $0.category == category }?.words.count ?? 0
    }
}
