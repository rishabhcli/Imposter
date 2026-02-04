//
//  StorageService.swift
//  Imposter
//
//  Production implementation of StorageServiceProtocol.
//  Uses UserDefaults for persistent storage with proper error handling.
//

import Foundation
import OSLog

// MARK: - StorageService

/// Production storage service using UserDefaults.
/// Provides type-safe persistence with comprehensive error handling.
@MainActor
final class StorageService: StorageServiceProtocol {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "com.imposter", category: "StorageService")

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - StorageServiceProtocol - Generic Storage

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
            logger.debug("Saved data for key: \(key)")
        } catch {
            logger.error("Failed to encode data for key \(key): \(error.localizedDescription)")
            throw StorageServiceError.encodingFailed(underlying: error)
        }
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = defaults.data(forKey: key) else {
            logger.debug("No data found for key: \(key)")
            return nil
        }

        do {
            let value = try JSONDecoder().decode(type, from: data)
            logger.debug("Loaded data for key: \(key)")
            return value
        } catch {
            logger.error("Failed to decode data for key \(key): \(error.localizedDescription)")
            throw StorageServiceError.decodingFailed(key: key, underlying: error)
        }
    }

    func delete(forKey key: String) {
        defaults.removeObject(forKey: key)
        logger.debug("Deleted data for key: \(key)")
    }

    func exists(forKey key: String) -> Bool {
        defaults.object(forKey: key) != nil
    }

    // MARK: - StorageServiceProtocol - Game-Specific Storage

    func savePlayers(_ players: [Player]) throws {
        try save(players, forKey: StorageKeys.lastPlayers)
        logger.info("Saved \(players.count) players")
    }

    func loadPlayers() throws -> [Player]? {
        let players = try load([Player].self, forKey: StorageKeys.lastPlayers)
        if let count = players?.count {
            logger.info("Loaded \(count) players")
        }
        return players
    }

    func saveSettings(_ settings: GameSettings) throws {
        try save(settings, forKey: StorageKeys.gameSettings)
        logger.info("Saved game settings")
    }

    func loadSettings() throws -> GameSettings? {
        let settings = try load(GameSettings.self, forKey: StorageKeys.gameSettings)
        if settings != nil {
            logger.info("Loaded game settings")
        }
        return settings
    }

    // MARK: - StorageServiceProtocol - Statistics

    var gamesPlayed: Int {
        defaults.integer(forKey: StorageKeys.gamesPlayed)
    }

    var highScore: Int {
        defaults.integer(forKey: StorageKeys.highScore)
    }

    func recordGameCompletion(maxScore: Int) {
        let newGamesPlayed = gamesPlayed + 1
        defaults.set(newGamesPlayed, forKey: StorageKeys.gamesPlayed)
        logger.info("Recorded game completion. Total games: \(newGamesPlayed)")

        if maxScore > highScore {
            defaults.set(maxScore, forKey: StorageKeys.highScore)
            logger.info("New high score: \(maxScore)")
        }
    }

    func isNewHighScore(_ score: Int) -> Bool {
        score > highScore
    }

    // MARK: - StorageServiceProtocol - Reset

    func resetAll() {
        delete(forKey: StorageKeys.gameSettings)
        delete(forKey: StorageKeys.lastPlayers)
        defaults.set(0, forKey: StorageKeys.gamesPlayed)
        defaults.set(0, forKey: StorageKeys.highScore)
        logger.info("Reset all stored data")
    }
}

// MARK: - Convenience Extensions

extension StorageService {
    /// Saves players for rematch (same players, new game)
    func savePlayersForRematch(_ players: [Player]) throws {
        try savePlayers(players)
    }

    /// Loads players for new game
    func loadPlayersForNewGame() throws -> [Player]? {
        return try loadPlayers()
    }
}
