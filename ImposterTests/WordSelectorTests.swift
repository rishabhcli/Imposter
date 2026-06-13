//
//  WordSelectorTests.swift
//  ImposterTests
//
//  Unit tests for word selection logic.
//

import Foundation
import Testing
@testable import Imposter

@Suite("Word Selector Tests")
@MainActor
struct WordSelectorTests {

    // MARK: - Basic Selection Tests

    @Test func selectWordReturnsNonEmpty() {
        let settings = GameSettings.default
        let word = WordSelector.selectWord(from: settings)

        #expect(!word.isEmpty)
    }

    @Test func selectWordReturnsValidWord() {
        let settings = GameSettings.default

        // Select multiple times to test randomness
        for _ in 0..<10 {
            let word = WordSelector.selectWord(from: settings)
            #expect(!word.isEmpty)
            #expect(word != "UNKNOWN")
        }
    }

    // MARK: - Category Selection Tests

    @Test func selectWordFromSpecificCategory() {
        var settings = GameSettings.default
        settings.selectedCategories = ["Animals"]

        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordFromMultipleCategories() {
        var settings = GameSettings.default
        settings.selectedCategories = ["Animals", "Technology"]

        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordWithNilCategoriesUsesAll() {
        var settings = GameSettings.default
        settings.selectedCategories = nil

        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    // MARK: - Difficulty Tests

    @Test func selectWordWithEasyDifficulty() {
        var settings = GameSettings.default
        settings.wordPackDifficulty = .easy

        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordWithMediumDifficulty() {
        var settings = GameSettings.default
        settings.wordPackDifficulty = .medium

        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordWithHardDifficulty() {
        var settings = GameSettings.default
        settings.wordPackDifficulty = .hard

        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordWithMixedDifficulty() {
        var settings = GameSettings.default
        settings.wordPackDifficulty = .mixed

        // Should return words from any difficulty
        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func selectWordWithEmptyCategories() {
        var settings = GameSettings.default
        settings.selectedCategories = []

        // Empty array should fallback to all categories
        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordWithInvalidCategory() {
        var settings = GameSettings.default
        settings.selectedCategories = ["NonexistentCategory"]

        // Should handle gracefully
        let word = WordSelector.selectWord(from: settings)
        #expect(!word.isEmpty)
    }

    @Test func selectWordAvoidsRecentWordsWhenFreshCandidateExists() throws {
        let animalPack = try #require(
            WordSelector.loadWordPacks().first { $0.category == "Animals" }
        )
        let mediumWords = animalPack.words
            .filter { $0.difficulty == "medium" }
            .map(\.word)
        let expectedWord = try #require(mediumWords.last)
        let avoidedWords = Set(mediumWords.dropLast())

        var settings = GameSettings.default
        settings.selectedCategories = ["Animals"]
        settings.wordPackDifficulty = .medium

        for _ in 0..<10 {
            let word = WordSelector.selectWord(from: settings, avoiding: avoidedWords)
            #expect(word == expectedWord)
        }
    }

    @Test func selectWordFallsBackWhenAvoidanceExhaustsCandidates() throws {
        let animalPack = try #require(
            WordSelector.loadWordPacks().first { $0.category == "Animals" }
        )
        let mediumWords = animalPack.words
            .filter { $0.difficulty == "medium" }
            .map(\.word)

        var settings = GameSettings.default
        settings.selectedCategories = ["Animals"]
        settings.wordPackDifficulty = .medium

        let word = WordSelector.selectWord(from: settings, avoiding: Set(mediumWords))
        #expect(!word.isEmpty)
    }

    @Test func nearDuplicateDetectionCatchesPlayableCollisions() {
        #expect(WordSelector.isNearDuplicateWord("Beyonce", of: "Beyoncé"))
        #expect(WordSelector.isNearDuplicateWord("Cats", of: "Cat"))
        #expect(WordSelector.isNearDuplicateWord("Apple Watch", of: "Apple"))
        #expect(WordSelector.isNearDuplicateWord("iPhone 16", of: "iPhone 15"))
        #expect(WordSelector.isNearDuplicateWord("Vision Pro headset", of: "Apple Vision Pro"))
        #expect(!WordSelector.isNearDuplicateWord("Cat", of: "Hat"))
        #expect(!WordSelector.isNearDuplicateWord("Moana", of: "Mulan"))
    }

    @Test func playableDistinctWordRejectsNearDuplicateHistory() {
        let blockedWords: Set<String> = ["Cat", "iPhone 16", "Apple Vision Pro"]

        #expect(!WordSelector.isPlayableDistinctWord("Cats", from: blockedWords))
        #expect(!WordSelector.isPlayableDistinctWord("iPhone 15", from: blockedWords))
        #expect(!WordSelector.isPlayableDistinctWord("Vision Pro", from: blockedWords))
        #expect(WordSelector.isPlayableDistinctWord("Dolphin", from: blockedWords))
    }

    @Test func selectAlternateWordPrefersSameCategoryAndDifficulty() throws {
        let animalPack = try #require(
            WordSelector.loadWordPacks().first { $0.category == "Animals" }
        )
        let secretEntry = try #require(
            animalPack.words.first { $0.difficulty == "medium" }
        )

        var settings = GameSettings.default
        settings.wordPackDifficulty = .medium
        settings.selectedCategories = nil

        let alternateWord = try #require(
            WordSelector.selectAlternateWord(
                matching: secretEntry.word,
                from: settings
            )
        )
        let alternateEntry = try #require(
            animalPack.words.first { $0.word == alternateWord }
        )

        #expect(alternateEntry.category == secretEntry.category)
        #expect(alternateEntry.difficulty == secretEntry.difficulty)
        #expect(WordSelector.isPlayableDistinctWord(alternateWord, from: [secretEntry.word]))
    }

    @Test func selectAlternateWordReturnsNilWhenOnlyNearDuplicatesRemain() {
        let pack = WordPack(
            category: "Animals",
            words: [
                testWordEntry(id: "animals-cat", word: "Cat"),
                testWordEntry(id: "animals-cats", word: "Cats")
            ]
        )

        let alternateWord = WordSelector.selectAlternateWord(
            matching: "Cat",
            in: [pack],
            difficulty: .easy
        )

        #expect(alternateWord == nil)
    }

    @Test func selectAlternateWordUsesDeterministicCandidateScoringInsideTier() throws {
        let pack = WordPack(
            category: "Animals",
            words: [
                testWordEntry(
                    id: "animals-tiger",
                    word: "Tiger",
                    tags: ["animal", "feline", "predator"]
                ),
                testWordEntry(
                    id: "animals-whale",
                    word: "Whale",
                    tags: ["animal", "marine"]
                ),
                testWordEntry(
                    id: "animals-lion",
                    word: "Lion",
                    tags: ["animal", "feline", "predator"]
                )
            ]
        )

        for _ in 0..<10 {
            let alternateWord = try #require(
                WordSelector.selectAlternateWord(
                    matching: "Tiger",
                    in: [pack],
                    difficulty: .easy
                )
            )

            #expect(alternateWord == "Lion")
        }
    }

    // MARK: - Custom Prompt Tests

    @Test func customPromptUsedWhenSet() {
        var settings = GameSettings.default
        settings.wordSource = .customPrompt
        settings.customWordPrompt = "My Custom Word"

        // When using custom prompt, the word comes from settings, not the selector
        // This is handled in the reducer, but we test the setting is correct
        #expect(settings.customWordPrompt == "My Custom Word")
    }

    // MARK: - Randomness Test

    @Test func selectWordProvidesVariety() {
        let settings = GameSettings.default
        var words: Set<String> = []

        // Select 20 words, expect at least some variety
        for _ in 0..<20 {
            let word = WordSelector.selectWord(from: settings)
            words.insert(word)
        }

        // With 100+ words per category, we should get multiple unique words
        #expect(words.count > 1)
    }

    // MARK: - Category Summary Tests

    @Test func categorySummariesMirrorAvailableCategories() {
        let summaries = WordSelector.categorySummaries

        #expect(summaries.map(\.name) == GameSettings.availableCategories)
        #expect(summaries.map(\.id) == GameSettings.availableCategories)
    }

    @Test func categorySummariesExposeWordAndDifficultyCounts() {
        let summaries = WordSelector.categorySummaries

        #expect(!summaries.isEmpty)
        #expect(summaries.allSatisfy { $0.wordCount >= 100 })
        #expect(summaries.allSatisfy { $0.easyCount > 0 })
        #expect(summaries.allSatisfy { $0.mediumCount > 0 })
        #expect(summaries.allSatisfy { $0.hardCount > 0 })
        #expect(summaries.allSatisfy { summary in
            summary.count(for: .mixed) == summary.wordCount
        })
    }

    @Test func categorySummariesExposeValidatedMetadata() {
        let summaries = WordSelector.categorySummaries

        #expect(summaries.allSatisfy { !$0.iconSystemName.isEmpty })
        #expect(summaries.allSatisfy { $0.safety == "general" })
        #expect(summaries.allSatisfy { 1...5 ~= $0.partyEnergy })
        #expect(summaries.allSatisfy { 1...5 ~= $0.ambiguity })
        #expect(summaries.allSatisfy { 1...5 ~= $0.imageSuitability })
        #expect(summaries.allSatisfy { !$0.tags.isEmpty })
    }

    @Test func wordPackEntriesExposeSchemaFields() throws {
        let packs = WordSelector.loadWordPacks()
        let entries = packs.flatMap(\.words)

        #expect(!entries.isEmpty)
        #expect(entries.allSatisfy { !$0.id.isEmpty })
        #expect(entries.allSatisfy { $0.displayText == $0.word })
        #expect(entries.allSatisfy { !$0.category.isEmpty })
        #expect(entries.allSatisfy { !$0.tags.isEmpty })
        #expect(entries.allSatisfy { $0.localizationKey.hasPrefix("word.") })
        #expect(entries.allSatisfy { $0.safety.level == "general" })
    }

    @Test func wordEntryLocalizedDisplayFallsBackToDisplayText() throws {
        let entry = try #require(WordSelector.loadWordPacks().first?.words.first)

        #expect(entry.localizedDisplayText() == entry.displayText)
    }

    private func testWordEntry(
        id: String,
        word: String,
        category: String = "Animals",
        difficulty: String = "easy",
        tags: [String] = ["test"]
    ) -> WordEntry {
        WordEntry(
            id: id,
            displayText: word,
            word: word,
            category: category,
            difficulty: difficulty,
            tags: tags,
            localizationKey: "word.\(id.replacingOccurrences(of: "-", with: "."))",
            safety: WordSafetyMetadata(level: "general")
        )
    }
}
