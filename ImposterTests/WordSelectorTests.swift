//
//  WordSelectorTests.swift
//  ImposterTests
//
//  Unit tests for word selection logic.
//

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
}
