//
//  MockStorageService.swift
//  Imposter
//
//  Mock storage service for testing and previews.
//

import Foundation

// MARK: - MockStorageService

/// Mock implementation of StorageServiceProtocol for testing and previews.
/// Uses in-memory storage instead of UserDefaults.
@MainActor
final class MockStorageService: StorageServiceProtocol {

    // MARK: - Storage

    /// In-memory storage dictionary
    private var storage: [String: Data] = [:]

    /// Games played counter
    private var _gamesPlayed: Int = 0

    /// High score
    private var _highScore: Int = 0

    // MARK: - Configuration

    /// Whether to simulate errors
    var shouldFailOnSave: Bool = false
    var shouldFailOnLoad: Bool = false
    var saveError: Error = StorageServiceError.operationFailed(underlying: NSError(domain: "MockStorage", code: 1))
    var loadError: Error = StorageServiceError.decodingFailed(key: "mock", underlying: NSError(domain: "MockStorage", code: 2))

    // MARK: - Call Tracking

    /// Number of times save was called
    private(set) var saveCallCount = 0

    /// Number of times load was called
    private(set) var loadCallCount = 0

    /// Number of times delete was called
    private(set) var deleteCallCount = 0

    /// Last key passed to save
    private(set) var lastSaveKey: String?

    /// Last key passed to load
    private(set) var lastLoadKey: String?

    // MARK: - StorageServiceProtocol

    var gamesPlayed: Int {
        _gamesPlayed
    }

    var highScore: Int {
        _highScore
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        saveCallCount += 1
        lastSaveKey = key

        if shouldFailOnSave {
            throw saveError
        }

        let data = try JSONEncoder().encode(value)
        storage[key] = data
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        loadCallCount += 1
        lastLoadKey = key

        if shouldFailOnLoad {
            throw loadError
        }

        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    func delete(forKey key: String) {
        deleteCallCount += 1
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        storage[key] != nil
    }

    func savePlayers(_ players: [Player]) throws {
        try save(players, forKey: "savedPlayers")
    }

    func loadPlayers() throws -> [Player]? {
        try load([Player].self, forKey: "savedPlayers")
    }

    func saveSettings(_ settings: GameSettings) throws {
        try save(settings, forKey: "gameSettings")
    }

    func loadSettings() throws -> GameSettings? {
        try load(GameSettings.self, forKey: "gameSettings")
    }

    func recordGameCompletion(maxScore: Int) {
        _gamesPlayed += 1
        if maxScore > _highScore {
            _highScore = maxScore
        }
    }

    func isNewHighScore(_ score: Int) -> Bool {
        score > _highScore
    }

    func resetAll() {
        storage.removeAll()
        _gamesPlayed = 0
        _highScore = 0
    }

    // MARK: - Test Helpers

    /// Resets all call tracking
    func reset() {
        saveCallCount = 0
        loadCallCount = 0
        deleteCallCount = 0
        lastSaveKey = nil
        lastLoadKey = nil
    }

    /// Resets all data and call tracking
    func resetAllData() {
        reset()
        resetAll()
    }

    /// Sets the games played counter for testing
    func setGamesPlayed(_ count: Int) {
        _gamesPlayed = count
    }

    /// Sets the high score for testing
    func setHighScore(_ score: Int) {
        _highScore = score
    }

    /// Directly sets data for a key (bypassing encoding)
    func setRawData(_ data: Data, forKey key: String) {
        storage[key] = data
    }

    /// Gets raw data for a key
    func getRawData(forKey key: String) -> Data? {
        storage[key]
    }
}
