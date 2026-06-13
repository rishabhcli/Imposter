//
//  GameRulesTests.swift
//  ImposterTests
//
//  Tests for rule validation, normalization, and setup summaries.
//

import XCTest
@testable import Imposter

@MainActor
final class GameRulesTests: XCTestCase {

    func testValidationBlocksTooFewPlayers() {
        let validation = GameRules.validation(
            settings: .default,
            playerCount: 2
        )

        XCTAssertFalse(validation.canStart)
        XCTAssertEqual(validation.issues, [.tooFewPlayers(minimum: 3, current: 2)])
    }

    func testValidationBlocksMissingCustomPrompt() {
        var settings = GameSettings.default
        settings.wordSource = .customPrompt
        settings.customWordPrompt = "   "

        let validation = GameRules.validation(
            settings: settings,
            playerCount: 3
        )

        XCTAssertFalse(validation.canStart)
        XCTAssertEqual(validation.issues, [.missingCustomPrompt])
        XCTAssertNil(validation.settings.customWordPrompt)
    }

    func testNormalizationKeepsHiddenCustomPromptPlayable() {
        var settings = GameSettings.default
        settings.wordSource = .customPrompt
        settings.customWordPrompt = "Ocean creatures"
        settings.gameMode = .hidden

        let normalized = GameRules.normalized(settings)

        XCTAssertEqual(normalized.wordSource, .customPrompt)
        XCTAssertEqual(normalized.gameMode, .hidden)
        XCTAssertEqual(normalized.customWordPrompt, "Ocean creatures")
    }

    func testNormalizationClampsAndFiltersSettings() {
        var settings = GameSettings.default
        settings.selectedCategories = ["Animals", "Invalid", "Animals", "Movies"]
        settings.numberOfClueRounds = 20
        settings.clueTimerMinutes = -4
        settings.discussionSeconds = 2
        settings.votingSeconds = 999
        settings.pointsForCorrectVote = -1
        settings.pointsForImposterSurvival = 44
        settings.pointsForImposterGuess = 99
        settings.numberOfRounds = 99

        let normalized = GameRules.normalized(settings)

        XCTAssertEqual(normalized.selectedCategories, ["Animals", "Movies"])
        XCTAssertEqual(normalized.numberOfClueRounds, 5)
        XCTAssertEqual(normalized.clueTimerMinutes, 0)
        XCTAssertFalse(normalized.clueTimerEnabled)
        XCTAssertEqual(normalized.discussionSeconds, 15)
        XCTAssertEqual(normalized.votingSeconds, 300)
        XCTAssertEqual(normalized.pointsForCorrectVote, 0)
        XCTAssertEqual(normalized.pointsForImposterSurvival, 10)
        XCTAssertEqual(normalized.pointsForImposterGuess, 15)
        XCTAssertEqual(normalized.numberOfRounds, 10)
    }

    func testSummaryIncludesBlockingIssueForMissingPrompt() {
        var settings = GameSettings.default
        settings.wordSource = .customPrompt
        settings.customWordPrompt = nil

        let summary = GameRules.summary(settings: settings, playerCount: 3)

        XCTAssertEqual(summary.status, .blocked)
        XCTAssertTrue(summary.items.contains { $0.id == "missingCustomPrompt" && $0.tone == .blocking })
    }

    func testSummaryAllowsHiddenCustomPromptWhenThemeExists() {
        var settings = GameSettings.default
        settings.wordSource = .customPrompt
        settings.customWordPrompt = "Ocean creatures"
        settings.gameMode = .hidden

        let summary = GameRules.summary(settings: settings, playerCount: 3)

        XCTAssertEqual(summary.status, .ready)
        XCTAssertTrue(summary.items.contains { $0.id == "mode" && $0.tone == .normal })
        XCTAssertFalse(summary.items.contains { $0.tone == .blocking })
    }
}
