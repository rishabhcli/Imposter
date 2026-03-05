//
//  ScoringEngine.swift
//  Imposter
//
//  Pure scoring calculations for round completion.
//

import Foundation

// MARK: - ScoringEngine

/// Pure scoring calculations for round completion
enum ScoringEngine {

    /// Points earned by each player in a round
    struct RoundScores: Sendable {
        /// Map of player ID to points earned this round
        let playerScores: [UUID: Int]
    }

    /// Calculates scores for a completed round
    static func calculate(
        roundState: RoundState,
        players: [Player],
        settings: GameSettings,
        imposterGuessedCorrectly: Bool
    ) -> RoundScores {
        var scores: [UUID: Int] = [:]
        let imposterID = roundState.imposterID

        // Calculate voting result
        let votingResult = GameReducer.calculateVotingResult(roundState: roundState)

        if votingResult.isCorrect {
            // Imposter was caught - award points to correct voters
            for (voterID, suspectID) in roundState.votes {
                if voterID != imposterID && suspectID == imposterID {
                    scores[voterID, default: 0] += settings.pointsForCorrectVote
                }
            }

            // Imposter guessed the word correctly - bonus points
            if imposterGuessedCorrectly {
                scores[imposterID, default: 0] += settings.pointsForImposterGuess
            }
        } else {
            // Imposter survived undetected (or vote was a tie)
            scores[imposterID, default: 0] += settings.pointsForImposterSurvival
        }

        return RoundScores(playerScores: scores)
    }

    /// Applies round scores to players, returning updated player array
    static func applyScores(_ roundScores: RoundScores, to players: [Player]) -> [Player] {
        players.map { player in
            var updated = player
            updated.score += roundScores.playerScores[player.id, default: 0]
            return updated
        }
    }
}
