//
//  StorageServiceProtocol.swift
//  Imposter
//
//  Protocol for persistent storage services.
//

import Foundation

// MARK: - StorageServiceProtocol

/// Protocol defining persistent storage capabilities.
/// Implementations can use UserDefaults, file storage, or other persistence mechanisms.
@MainActor
protocol StorageServiceProtocol {

    // MARK: - Generic Storage

    /// Saves a codable value for the given key.
    /// - Parameters:
    ///   - value: The value to save
    ///   - key: The storage key
    /// - Throws: `StorageServiceError` if saving fails
    func save<T: Codable>(_ value: T, forKey key: String) throws

    /// Loads a codable value for the given key.
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: The storage key
    /// - Returns: The decoded value, or nil if not found
    /// - Throws: `StorageServiceError` if loading fails (corruption, decode error)
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?

    /// Deletes the value for the given key.
    /// - Parameter key: The storage key
    func delete(forKey key: String)

    /// Checks if a value exists for the given key.
    /// - Parameter key: The storage key
    /// - Returns: True if a value exists
    func exists(forKey key: String) -> Bool

    // MARK: - Game-Specific Storage

    /// Saves the current players for quick rematch.
    /// - Parameter players: Array of players to save
    /// - Throws: `StorageServiceError` if saving fails
    func savePlayers(_ players: [Player]) throws

    /// Loads the last saved players.
    /// - Returns: Array of players, or nil if none saved
    /// - Throws: `StorageServiceError` if loading fails
    func loadPlayers() throws -> [Player]?

    /// Saves game settings.
    /// - Parameter settings: Settings to save
    /// - Throws: `StorageServiceError` if saving fails
    func saveSettings(_ settings: GameSettings) throws

    /// Loads saved game settings.
    /// - Returns: Settings, or nil if none saved
    /// - Throws: `StorageServiceError` if loading fails
    func loadSettings() throws -> GameSettings?

    // MARK: - Statistics

    /// Gets the total number of games played.
    var gamesPlayed: Int { get }

    /// Gets the high score.
    var highScore: Int { get }

    /// Records completion of a game and updates statistics.
    /// - Parameter maxScore: The maximum score achieved in the game
    func recordGameCompletion(maxScore: Int)

    /// Checks if the given score beats the high score.
    /// - Parameter score: Score to check
    /// - Returns: True if it's a new high score
    func isNewHighScore(_ score: Int) -> Bool

    // MARK: - Reset

    /// Resets all stored data.
    func resetAll()
}

// MARK: - StorageServiceError

/// Errors that can occur during storage operations
enum StorageServiceError: LocalizedError, Sendable {
    /// Failed to encode data for storage
    case encodingFailed(underlying: Error)

    /// Failed to decode stored data
    case decodingFailed(key: String, underlying: Error)

    /// Stored data is corrupted
    case corruptedData(key: String)

    /// Storage operation failed
    case operationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let key, _):
            return "Failed to decode data for key '\(key)'"
        case .corruptedData(let key):
            return "Stored data for '\(key)' is corrupted"
        case .operationFailed(let error):
            return "Storage operation failed: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            return "Try again or contact support"
        case .decodingFailed, .corruptedData:
            return "Default values will be used"
        case .operationFailed:
            return "Check device storage and try again"
        }
    }
}
