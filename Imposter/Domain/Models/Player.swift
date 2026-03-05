//
//  Player.swift
//  Imposter
//
//  Domain model representing a game participant.
//

import Foundation
import SwiftUI

// MARK: - Player

/// Represents a participant in the game
struct Player: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var color: PlayerColor
    var emoji: String
    var score: Int

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id, name, color, emoji, score
    }

    init(id: UUID = UUID(), name: String, color: PlayerColor, emoji: String? = nil, score: Int = 0) {
        self.id = id
        self.name = name
        self.color = color
        self.emoji = emoji ?? Player.randomFaceEmoji()
        self.score = score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(PlayerColor.self, forKey: .color)
        emoji = try container.decode(String.self, forKey: .emoji)
        score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
    }

    /// Collection of face emojis for random assignment
    static let faceEmojis = [
        "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂",
        "🙂", "😊", "😇", "🥰", "😍", "🤩", "😘", "😋",
        "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫",
        "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒",
        "🙄", "😬", "😮‍💨", "🤥", "😌", "😔", "😪", "🤤",
        "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🤧", "🥵",
        "🥶", "🥴", "😵", "🤯", "🤠", "🥳", "🥸", "😎",
        "🤓", "🧐", "😕", "😟", "🙁", "😮", "😯", "😲",
        "😳", "🥺", "😦", "😧", "😨", "😰", "😥", "😢",
        "😭", "😱", "😖", "😣", "😞", "😓", "😩", "😫",
        "🥱", "😤", "😡", "😠", "🤬", "😈", "👿", "💀",
        "👻", "👽", "🤖", "🎃", "😺", "😸", "😹", "😻"
    ]

    /// Returns a random face emoji
    static func randomFaceEmoji() -> String {
        faceEmojis.randomElement() ?? "😀"
    }
}

// MARK: - PlayerColor

/// Predefined color palette for player identification
/// Each color is distinct and vibrant for easy visual differentiation
enum PlayerColor: String, Codable, CaseIterable, Sendable {
    case crimson
    case azure
    case emerald
    case amber
    case violet
    case coral
    case teal
    case rose

    /// Display name for the color
    var displayName: String {
        rawValue.capitalized
    }

    /// Returns the next available color that isn't already used
    static func nextAvailable(excluding usedColors: [PlayerColor]) -> PlayerColor {
        for color in allCases {
            if !usedColors.contains(color) {
                return color
            }
        }
        // If all colors are used, start over (shouldn't happen with max 10 players and 8 colors)
        return allCases.first ?? .crimson
    }
}
