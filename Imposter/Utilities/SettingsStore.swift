//
//  SettingsStore.swift
//  Imposter
//
//  Manages persistence of game settings and player data.
//

import Foundation
import Observation
import UIKit

// MARK: - SettingsStore

/// Manages persistence of game settings and statistics to UserDefaults.
/// Automatically saves on property changes and loads on init.
@Observable
@MainActor
final class SettingsStore {

    // MARK: - Properties

    /// The current game settings (auto-saved on change)
    var settings: GameSettings {
        didSet {
            saveSettings()
        }
    }

    /// Last players used (for quick rematch)
    var lastPlayers: [PlayerInfo] {
        didSet {
            saveLastPlayers()
        }
    }

    /// Total number of games played
    private(set) var gamesPlayed: Int {
        didSet {
            UserDefaults.standard.set(gamesPlayed, forKey: StorageKeys.gamesPlayed)
        }
    }

    /// Highest score achieved
    private(set) var highScore: Int {
        didSet {
            UserDefaults.standard.set(highScore, forKey: StorageKeys.highScore)
        }
    }

    // MARK: - Nested Types

    /// Simplified player info for persistence
    struct PlayerInfo: Codable, Sendable {
        let name: String
        let colorRawValue: String

        init(name: String, color: PlayerColor) {
            self.name = name
            self.colorRawValue = color.rawValue
        }

        var color: PlayerColor {
            PlayerColor(rawValue: colorRawValue) ?? .azure
        }
    }

    // MARK: - Initialization

    init() {
        // Load settings
        if let data = UserDefaults.standard.data(forKey: StorageKeys.gameSettings),
           let loadedSettings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            self.settings = loadedSettings
        } else {
            self.settings = .default
        }

        // Load last players
        if let data = UserDefaults.standard.data(forKey: StorageKeys.lastPlayers),
           let loadedPlayers = try? JSONDecoder().decode([PlayerInfo].self, from: data) {
            self.lastPlayers = loadedPlayers
        } else {
            self.lastPlayers = []
        }

        // Load statistics
        self.gamesPlayed = UserDefaults.standard.integer(forKey: StorageKeys.gamesPlayed)
        self.highScore = UserDefaults.standard.integer(forKey: StorageKeys.highScore)
    }

    // MARK: - Public Methods

    /// Records completion of a game and updates statistics
    /// - Parameter scores: Array of player scores
    func recordGameCompletion(scores: [Int]) {
        gamesPlayed += 1

        if let maxScore = scores.max(), maxScore > highScore {
            highScore = maxScore
        }
    }

    /// Saves the current players for quick rematch
    /// - Parameter players: Array of players to save
    func saveCurrentPlayers(_ players: [Player]) {
        lastPlayers = players.map { PlayerInfo(name: $0.name, color: $0.color) }
    }

    /// Checks if the given score beats the high score
    /// - Parameter score: Score to check
    /// - Returns: True if score is a new high score
    func isNewHighScore(_ score: Int) -> Bool {
        score > highScore
    }

    /// Resets all stored data
    func resetAll() {
        settings = .default
        lastPlayers = []
        gamesPlayed = 0
        highScore = 0
    }

    // MARK: - Private Methods

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: StorageKeys.gameSettings)
        }
    }

    private func saveLastPlayers() {
        if let data = try? JSONEncoder().encode(lastPlayers) {
            UserDefaults.standard.set(data, forKey: StorageKeys.lastPlayers)
        }
    }
}

// MARK: - Preview Support

extension SettingsStore {
    /// Preview instance with default data
    nonisolated static var preview: SettingsStore {
        MainActor.assumeIsolated {
            SettingsStore()
        }
    }
}
