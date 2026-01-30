//
//  StorageKeys.swift
//  Imposter
//
//  UserDefaults keys for persisting app data.
//

import Foundation

// MARK: - StorageKeys

/// Defines all UserDefaults keys used in the app
enum StorageKeys {
    /// Key for persisted game settings
    static let gameSettings = "imposter.gameSettings"

    /// Key for last players (for quick rematch)
    static let lastPlayers = "imposter.lastPlayers"

    /// Key for total games played counter
    static let gamesPlayed = "imposter.gamesPlayed"

    /// Key for highest score achieved
    static let highScore = "imposter.highScore"

    /// Key for last selected categories
    static let lastCategories = "imposter.lastCategories"
}
