//
//  StorageServiceTests.swift
//  ImposterTests
//
//  Unit tests for StorageService implementation.
//

import XCTest
@testable import Imposter

@MainActor
final class StorageServiceTests: XCTestCase {

    var sut: StorageService!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a separate suite to avoid affecting real app data
        testDefaults = UserDefaults(suiteName: "StorageServiceTests")!
        testDefaults.removePersistentDomain(forName: "StorageServiceTests")
        sut = StorageService(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "StorageServiceTests")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Generic Save/Load Tests

    func testSaveAndLoad_String_Succeeds() throws {
        let testValue = "Hello, World!"

        try sut.save(testValue, forKey: "testString")
        let loaded: String? = try sut.load(String.self, forKey: "testString")

        XCTAssertEqual(loaded, testValue)
    }

    func testSaveAndLoad_Int_Succeeds() throws {
        let testValue = 42

        try sut.save(testValue, forKey: "testInt")
        let loaded: Int? = try sut.load(Int.self, forKey: "testInt")

        XCTAssertEqual(loaded, testValue)
    }

    func testSaveAndLoad_Array_Succeeds() throws {
        let testValue = ["one", "two", "three"]

        try sut.save(testValue, forKey: "testArray")
        let loaded: [String]? = try sut.load([String].self, forKey: "testArray")

        XCTAssertEqual(loaded, testValue)
    }

    func testLoad_NonexistentKey_ReturnsNil() throws {
        let loaded: String? = try sut.load(String.self, forKey: "nonexistent")

        XCTAssertNil(loaded)
    }

    func testLoad_WrongType_ThrowsDecodingError() {
        // Save a string
        try? sut.save("string value", forKey: "testKey")

        // Try to load as Int
        XCTAssertThrowsError(try sut.load(Int.self, forKey: "testKey")) { error in
            guard case StorageServiceError.decodingFailed = error else {
                XCTFail("Expected decodingFailed error")
                return
            }
        }
    }

    // MARK: - Delete Tests

    func testDelete_RemovesValue() throws {
        try sut.save("value", forKey: "testKey")
        XCTAssertTrue(sut.exists(forKey: "testKey"))

        sut.delete(forKey: "testKey")

        XCTAssertFalse(sut.exists(forKey: "testKey"))
    }

    // MARK: - Exists Tests

    func testExists_ForExistingKey_ReturnsTrue() throws {
        try sut.save("value", forKey: "testKey")

        XCTAssertTrue(sut.exists(forKey: "testKey"))
    }

    func testExists_ForNonexistentKey_ReturnsFalse() {
        XCTAssertFalse(sut.exists(forKey: "nonexistent"))
    }

    // MARK: - Player Tests

    func testSaveAndLoadPlayers_Succeeds() throws {
        let players = [
            Player(name: "Alice", color: .crimson, emoji: "😀"),
            Player(name: "Bob", color: .azure, emoji: "😎")
        ]

        try sut.savePlayers(players)
        let loaded = try sut.loadPlayers()

        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].name, "Alice")
        XCTAssertEqual(loaded?[1].name, "Bob")
    }

    func testLoadPlayers_WhenNoneSaved_ReturnsNil() throws {
        let loaded = try sut.loadPlayers()

        XCTAssertNil(loaded)
    }

    // MARK: - Settings Tests

    func testSaveAndLoadSettings_Succeeds() throws {
        var settings = GameSettings.default
        settings.numberOfClueRounds = 3
        settings.pointsForCorrectVote = 5

        try sut.saveSettings(settings)
        let loaded = try sut.loadSettings()

        XCTAssertEqual(loaded?.numberOfClueRounds, 3)
        XCTAssertEqual(loaded?.pointsForCorrectVote, 5)
    }

    func testLoadSettings_WhenNoneSaved_ReturnsNil() throws {
        let loaded = try sut.loadSettings()

        XCTAssertNil(loaded)
    }

    // MARK: - Statistics Tests

    func testGamesPlayed_InitiallyZero() {
        XCTAssertEqual(sut.gamesPlayed, 0)
    }

    func testHighScore_InitiallyZero() {
        XCTAssertEqual(sut.highScore, 0)
    }

    func testRecordGameCompletion_IncrementsGamesPlayed() {
        sut.recordGameCompletion(maxScore: 5)

        XCTAssertEqual(sut.gamesPlayed, 1)
    }

    func testRecordGameCompletion_UpdatesHighScore_WhenHigher() {
        sut.recordGameCompletion(maxScore: 10)

        XCTAssertEqual(sut.highScore, 10)
    }

    func testRecordGameCompletion_DoesNotUpdateHighScore_WhenLower() {
        sut.recordGameCompletion(maxScore: 10)
        sut.recordGameCompletion(maxScore: 5)

        XCTAssertEqual(sut.highScore, 10)
    }

    func testIsNewHighScore_WhenHigher_ReturnsTrue() {
        sut.recordGameCompletion(maxScore: 10)

        XCTAssertTrue(sut.isNewHighScore(15))
    }

    func testIsNewHighScore_WhenLower_ReturnsFalse() {
        sut.recordGameCompletion(maxScore: 10)

        XCTAssertFalse(sut.isNewHighScore(5))
    }

    // MARK: - Reset Tests

    func testResetAll_ClearsAllData() throws {
        try sut.savePlayers([Player(name: "Test", color: .crimson, emoji: "😀")])
        try sut.saveSettings(GameSettings.default)
        sut.recordGameCompletion(maxScore: 100)

        sut.resetAll()

        XCTAssertNil(try sut.loadPlayers())
        XCTAssertNil(try sut.loadSettings())
        XCTAssertEqual(sut.gamesPlayed, 0)
        XCTAssertEqual(sut.highScore, 0)
    }
}
