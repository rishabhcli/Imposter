//
//  WordServiceTests.swift
//  ImposterTests
//
//  Unit tests for WordService implementation.
//

import XCTest
@testable import Imposter

@MainActor
final class WordServiceTests: XCTestCase {

    var sut: WordService!

    override func setUp() {
        super.setUp()
        sut = WordService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Available Categories Tests

    func testAvailableCategories_ReturnsExpectedCategories() {
        let categories = sut.availableCategories

        XCTAssertEqual(categories.count, 5)
        XCTAssertTrue(categories.contains("Animals"))
        XCTAssertTrue(categories.contains("Technology"))
        XCTAssertTrue(categories.contains("Objects"))
        XCTAssertTrue(categories.contains("People"))
        XCTAssertTrue(categories.contains("Movies"))
    }

    // MARK: - AI Availability Tests

    func testIsAIGenerationAvailable_ReturnsFalse() {
        // WordService doesn't support AI generation
        XCTAssertFalse(sut.isAIGenerationAvailable)
    }

    func testAiUnavailabilityReason_ReturnsMessage() {
        XCTAssertNotNil(sut.aiUnavailabilityReason)
        XCTAssertTrue(sut.aiUnavailabilityReason!.contains("AIWordService"))
    }

    // MARK: - Select Word Tests

    func testSelectWord_WithAllCategories_ReturnsWord() async throws {
        let word = try await sut.selectWord(from: nil, difficulty: .mixed)

        XCTAssertFalse(word.isEmpty)
        XCTAssertNotEqual(word, "UNKNOWN")
    }

    func testSelectWord_WithSpecificCategory_ReturnsWord() async throws {
        let word = try await sut.selectWord(from: ["Animals"], difficulty: .mixed)

        XCTAssertFalse(word.isEmpty)
    }

    func testSelectWord_WithMultipleCategories_ReturnsWord() async throws {
        let word = try await sut.selectWord(from: ["Animals", "Technology"], difficulty: .mixed)

        XCTAssertFalse(word.isEmpty)
    }

    func testSelectWord_WithEasyDifficulty_ReturnsWord() async throws {
        let word = try await sut.selectWord(from: nil, difficulty: .easy)

        XCTAssertFalse(word.isEmpty)
    }

    func testSelectWord_WithMediumDifficulty_ReturnsWord() async throws {
        let word = try await sut.selectWord(from: nil, difficulty: .medium)

        XCTAssertFalse(word.isEmpty)
    }

    func testSelectWord_WithHardDifficulty_ReturnsWord() async throws {
        let word = try await sut.selectWord(from: nil, difficulty: .hard)

        XCTAssertFalse(word.isEmpty)
    }

    func testSelectWord_WithInvalidCategory_ReturnsFallbackWord() async throws {
        // Invalid category should still return a word (from fallback or other categories)
        let word = try await sut.selectWord(from: ["InvalidCategory"], difficulty: .mixed)

        XCTAssertFalse(word.isEmpty)
    }

    // MARK: - Generate Word Tests

    func testGenerateWord_ThrowsAINotAvailable() async {
        do {
            _ = try await sut.generateWord(from: "test prompt")
            XCTFail("Expected error to be thrown")
        } catch let error as WordServiceError {
            if case .aiNotAvailable = error {
                // Expected
            } else {
                XCTFail("Expected aiNotAvailable error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Word Count Tests

    func testWordCount_ForValidCategory_ReturnsPositiveCount() {
        let count = sut.wordCount(for: "Animals")

        XCTAssertGreaterThan(count, 0)
    }

    func testWordCount_ForInvalidCategory_ReturnsZero() {
        let count = sut.wordCount(for: "InvalidCategory")

        XCTAssertEqual(count, 0)
    }

    // MARK: - Randomness Tests

    func testSelectWord_ReturnsDifferentWordsOverMultipleCalls() async throws {
        var words: Set<String> = []

        for _ in 0..<20 {
            let word = try await sut.selectWord(from: nil, difficulty: .mixed)
            words.insert(word)
        }

        // Should have at least some variety
        XCTAssertGreaterThan(words.count, 1, "Expected random selection to produce variety")
    }
}
