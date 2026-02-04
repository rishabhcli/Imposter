//
//  MockServicesTests.swift
//  ImposterTests
//
//  Unit tests for mock service implementations.
//

import XCTest
@testable import Imposter

// MARK: - MockWordService Tests

@MainActor
final class MockWordServiceTests: XCTestCase {

    var sut: MockWordService!

    override func setUp() {
        super.setUp()
        sut = MockWordService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testSelectWord_ReturnsConfiguredWord() async throws {
        sut.selectWordResult = .success("CustomWord")

        let word = try await sut.selectWord(from: nil, difficulty: .mixed)

        XCTAssertEqual(word, "CustomWord")
    }

    func testSelectWord_ThrowsConfiguredError() async {
        let expectedError = WordServiceError.noWordsAvailable(categories: [], difficulty: .mixed)
        sut.selectWordResult = .failure(expectedError)

        do {
            _ = try await sut.selectWord(from: nil, difficulty: .mixed)
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func testSelectWord_TracksCallCount() async throws {
        _ = try await sut.selectWord(from: nil, difficulty: .mixed)
        _ = try await sut.selectWord(from: nil, difficulty: .easy)

        XCTAssertEqual(sut.selectWordCallCount, 2)
    }

    func testSelectWord_TracksParameters() async throws {
        _ = try await sut.selectWord(from: ["Animals"], difficulty: .hard)

        XCTAssertEqual(sut.lastSelectCategories, ["Animals"])
        XCTAssertEqual(sut.lastSelectDifficulty, .hard)
    }

    func testGenerateWord_ReturnsConfiguredWord() async throws {
        sut.generateWordResult = .success("GeneratedWord")

        let word = try await sut.generateWord(from: "test prompt")

        XCTAssertEqual(word, "GeneratedWord")
    }

    func testGenerateWord_TracksPrompt() async throws {
        _ = try await sut.generateWord(from: "my prompt")

        XCTAssertEqual(sut.lastGeneratePrompt, "my prompt")
    }

    func testReset_ClearsAllTracking() async throws {
        _ = try await sut.selectWord(from: nil, difficulty: .mixed)
        _ = try await sut.generateWord(from: "test")

        sut.reset()

        XCTAssertEqual(sut.selectWordCallCount, 0)
        XCTAssertEqual(sut.generateWordCallCount, 0)
        XCTAssertNil(sut.lastSelectCategories)
        XCTAssertNil(sut.lastGeneratePrompt)
    }
}

// MARK: - MockImageService Tests

@MainActor
final class MockImageServiceTests: XCTestCase {

    var sut: MockImageService!

    override func setUp() {
        super.setUp()
        sut = MockImageService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGenerateImage_ReturnsConfiguredImage() async throws {
        let testImage = MockImageService.testImage(color: .blue)
        sut.generateImageResult = .success(testImage)

        let result = try await sut.generateImage(for: "test", category: "Test", style: nil)

        XCTAssertNotNil(result)
    }

    func testGenerateImage_TracksCallCount() async throws {
        _ = try await sut.generateImage(for: "word1", category: "Cat1", style: nil)
        _ = try await sut.generateImage(for: "word2", category: "Cat2", style: .sketch)

        XCTAssertEqual(sut.generateImageCallCount, 2)
    }

    func testGenerateImage_TracksParameters() async throws {
        _ = try await sut.generateImage(for: "elephant", category: "Animals", style: .illustration)

        XCTAssertEqual(sut.lastWord, "elephant")
        XCTAssertEqual(sut.lastCategory, "Animals")
        XCTAssertEqual(sut.lastStyle, .illustration)
    }

    func testClearCache_IncrementsClearCacheCount() {
        sut.clearCache()
        sut.clearCache()

        XCTAssertEqual(sut.clearCacheCallCount, 2)
    }

    func testReset_ClearsAllTracking() async throws {
        _ = try await sut.generateImage(for: "test", category: "Test", style: nil)
        sut.clearCache()

        sut.reset()

        XCTAssertEqual(sut.generateImageCallCount, 0)
        XCTAssertEqual(sut.clearCacheCallCount, 0)
        XCTAssertNil(sut.lastWord)
    }

    func testTestImage_CreatesImage() {
        let image = MockImageService.testImage(color: .red, size: CGSize(width: 50, height: 50))

        XCTAssertEqual(image.size.width, 50)
        XCTAssertEqual(image.size.height, 50)
    }
}

// MARK: - MockStorageService Tests

@MainActor
final class MockStorageServiceTests: XCTestCase {

    var sut: MockStorageService!

    override func setUp() {
        super.setUp()
        sut = MockStorageService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testSaveAndLoad_InMemory() throws {
        try sut.save("test value", forKey: "key")
        let loaded: String? = try sut.load(String.self, forKey: "key")

        XCTAssertEqual(loaded, "test value")
    }

    func testSave_TracksCallCount() throws {
        try sut.save("value1", forKey: "key1")
        try sut.save("value2", forKey: "key2")

        XCTAssertEqual(sut.saveCallCount, 2)
    }

    func testLoad_TracksCallCount() throws {
        _ = try sut.load(String.self, forKey: "key1")
        _ = try sut.load(String.self, forKey: "key2")

        XCTAssertEqual(sut.loadCallCount, 2)
    }

    func testShouldFailOnSave_ThrowsError() throws {
        sut.shouldFailOnSave = true

        XCTAssertThrowsError(try sut.save("value", forKey: "key"))
    }

    func testShouldFailOnLoad_ThrowsError() throws {
        sut.shouldFailOnLoad = true

        XCTAssertThrowsError(try sut.load(String.self, forKey: "key"))
    }

    func testRecordGameCompletion_UpdatesStatistics() {
        sut.recordGameCompletion(maxScore: 100)

        XCTAssertEqual(sut.gamesPlayed, 1)
        XCTAssertEqual(sut.highScore, 100)
    }

    func testResetAllData_ClearsEverything() throws {
        try sut.save("value", forKey: "key")
        sut.recordGameCompletion(maxScore: 100)

        sut.resetAllData()

        XCTAssertFalse(sut.exists(forKey: "key"))
        XCTAssertEqual(sut.gamesPlayed, 0)
        XCTAssertEqual(sut.saveCallCount, 0)
    }
}

// MARK: - MockHapticsService Tests

@MainActor
final class MockHapticsServiceTests: XCTestCase {

    var sut: MockHapticsService!

    override func setUp() {
        super.setUp()
        sut = MockHapticsService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testPlayImpact_RecordsEvent() {
        sut.playImpact(.heavy)

        XCTAssertTrue(sut.wasCalled(.impact(.heavy)))
    }

    func testPlayNotification_RecordsEvent() {
        sut.playNotification(.success)

        XCTAssertTrue(sut.wasCalled(.notification(.success)))
    }

    func testGameSpecificHaptics_RecordEvents() {
        sut.buttonTap()
        sut.voteSelected()
        sut.imposterCaught()

        XCTAssertTrue(sut.wasCalled(.buttonTap))
        XCTAssertTrue(sut.wasCalled(.voteSelected))
        XCTAssertTrue(sut.wasCalled(.imposterCaught))
    }

    func testCount_ReturnsCorrectCount() {
        sut.buttonTap()
        sut.buttonTap()
        sut.buttonTap()

        XCTAssertEqual(sut.count(of: .buttonTap), 3)
    }

    func testLastEvent_ReturnsLastEvent() {
        sut.buttonTap()
        sut.voteSelected()
        sut.gameStarted()

        XCTAssertEqual(sut.lastEvent, .gameStarted)
    }

    func testPrepare_IncrementsPrepareCount() {
        sut.prepare()
        sut.prepare()

        XCTAssertEqual(sut.prepareCallCount, 2)
    }

    func testReset_ClearsAllEvents() {
        sut.buttonTap()
        sut.prepare()

        sut.reset()

        XCTAssertTrue(sut.events.isEmpty)
        XCTAssertEqual(sut.prepareCallCount, 0)
    }
}
