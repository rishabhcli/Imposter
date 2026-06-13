//
//  GameRules.swift
//  Imposter
//
//  Rule validation, normalization, and host-facing summary generation.
//

import Foundation

// MARK: - RuleSummary

struct RuleSummary: Sendable, Equatable {
    enum Status: Sendable, Equatable {
        case ready
        case blocked
    }

    let status: Status
    let title: String
    let detail: String
    let items: [RuleSummaryItem]
}

struct RuleSummaryItem: Identifiable, Sendable, Equatable {
    enum Tone: Sendable, Equatable {
        case normal
        case warning
        case blocking
    }

    let id: String
    let icon: String
    let title: String
    let detail: String
    let tone: Tone
}

struct RuleValidation: Sendable, Equatable {
    enum Issue: Sendable, Equatable {
        case tooFewPlayers(minimum: Int, current: Int)
        case tooManyPlayers(maximum: Int, current: Int)
        case missingCustomPrompt
    }

    let settings: GameSettings
    let issues: [Issue]

    var canStart: Bool {
        issues.isEmpty
    }
}

// MARK: - GameRules

enum GameRules {
    static let minimumPlayers = 3
    static let maximumPlayers = 10
    static let maximumRounds = 10

    static func normalized(_ settings: GameSettings) -> GameSettings {
        var normalized = settings

        normalized.selectedCategories = normalizedCategories(from: settings.selectedCategories)
        normalized.customWordPrompt = normalizedPrompt(settings.customWordPrompt)

        normalized.numberOfClueRounds = clamp(settings.numberOfClueRounds, to: 1...5)
        normalized.clueTimerMinutes = clamp(settings.clueTimerMinutes, to: 0...5)
        normalized.clueTimerEnabled = normalized.clueTimerMinutes > 0

        normalized.discussionSeconds = clamp(settings.discussionSeconds, to: 15...600)
        normalized.votingSeconds = clamp(settings.votingSeconds, to: 10...300)

        normalized.pointsForCorrectVote = clamp(settings.pointsForCorrectVote, to: 0...10)
        normalized.pointsForImposterSurvival = clamp(settings.pointsForImposterSurvival, to: 0...10)
        normalized.pointsForImposterGuess = clamp(settings.pointsForImposterGuess, to: 0...15)
        normalized.numberOfRounds = clamp(settings.numberOfRounds, to: 0...maximumRounds)

        if normalized.wordSource == .customPrompt {
            normalized.selectedCategories = nil
        }

        return normalized
    }

    static func validation(settings: GameSettings, playerCount: Int) -> RuleValidation {
        let normalizedSettings = normalized(settings)
        var issues: [RuleValidation.Issue] = []

        if playerCount < minimumPlayers {
            issues.append(.tooFewPlayers(minimum: minimumPlayers, current: playerCount))
        }

        if playerCount > maximumPlayers {
            issues.append(.tooManyPlayers(maximum: maximumPlayers, current: playerCount))
        }

        if normalizedSettings.wordSource == .customPrompt,
           normalizedSettings.customWordPrompt == nil {
            issues.append(.missingCustomPrompt)
        }

        return RuleValidation(settings: normalizedSettings, issues: issues)
    }

    static func summary(settings: GameSettings, playerCount: Int) -> RuleSummary {
        let validation = validation(settings: settings, playerCount: playerCount)
        let settings = validation.settings
        let status: RuleSummary.Status = validation.canStart ? .ready : .blocked
        var items: [RuleSummaryItem] = [
            playerItem(playerCount: playerCount, validation: validation),
            modeItem(settings: settings),
            wordItem(settings: settings),
            timerItem(settings: settings),
            roundItem(settings: settings),
            scoringItem(settings: settings)
        ]

        items.append(contentsOf: validation.issues.map(issueItem))

        return RuleSummary(
            status: status,
            title: status == .ready ? String(localized: "Ready to Start") : String(localized: "Needs Attention"),
            detail: status == .ready
                ? String(localized: "This rule set is playable.")
                : String(localized: "Fix the blocking items before starting."),
            items: items
        )
    }

    private static func playerItem(playerCount: Int, validation: RuleValidation) -> RuleSummaryItem {
        let tone: RuleSummaryItem.Tone = validation.issues.contains { issue in
            switch issue {
            case .tooFewPlayers, .tooManyPlayers:
                return true
            case .missingCustomPrompt:
                return false
            }
        } ? .blocking : .normal

        return RuleSummaryItem(
            id: "players",
            icon: "person.3.fill",
            title: String(localized: "Players"),
            detail: String(
                format: String(localized: "%lld of 10 seated"),
                playerCount
            ),
            tone: tone
        )
    }

    private static func modeItem(settings: GameSettings) -> RuleSummaryItem {
        RuleSummaryItem(
            id: "mode",
            icon: settings.gameMode == .hidden ? "eye.slash.fill" : "person.fill.questionmark",
            title: String(localized: "Mode"),
            detail: settings.gameMode == .hidden
                ? String(localized: "Hidden Imposter uses a decoy word.")
                : String(localized: "Classic Imposter uses role knowledge and hints."),
            tone: .normal
        )
    }

    private static func wordItem(settings: GameSettings) -> RuleSummaryItem {
        let detail: String
        switch settings.wordSource {
        case .randomPack:
            let categories = settings.selectedCategories?.joined(separator: ", ") ?? String(localized: "All packs")
            detail = String(
                format: String(localized: "%@ at %@ difficulty"),
                categories,
                settings.wordPackDifficulty.displayName
            )
        case .customPrompt:
            let prompt = settings.customWordPrompt ?? String(localized: "Missing prompt")
            detail = String(
                format: String(localized: "Local generation from \"%@\""),
                prompt
            )
        }

        return RuleSummaryItem(
            id: "words",
            icon: settings.wordSource == .customPrompt ? "wand.and.stars" : "textformat.abc",
            title: String(localized: "Words"),
            detail: detail,
            tone: settings.wordSource == .customPrompt && settings.customWordPrompt == nil ? .blocking : .normal
        )
    }

    private static func timerItem(settings: GameSettings) -> RuleSummaryItem {
        var enabledTimers: [String] = []
        if settings.clueTimerEnabled {
            enabledTimers.append(
                String(format: String(localized: "Clues %lld min"), settings.clueTimerMinutes)
            )
        }
        if settings.discussionTimerEnabled {
            enabledTimers.append(
                String(format: String(localized: "Discussion %lld sec"), settings.discussionSeconds)
            )
        }
        if settings.votingTimerEnabled {
            enabledTimers.append(
                String(format: String(localized: "Voting %lld sec"), settings.votingSeconds)
            )
        }

        return RuleSummaryItem(
            id: "timers",
            icon: "timer",
            title: String(localized: "Timers"),
            detail: enabledTimers.isEmpty ? String(localized: "No timers") : enabledTimers.joined(separator: " · "),
            tone: .normal
        )
    }

    private static func roundItem(settings: GameSettings) -> RuleSummaryItem {
        RuleSummaryItem(
            id: "rounds",
            icon: "repeat.circle.fill",
            title: String(localized: "Rounds"),
            detail: settings.numberOfRounds == 0
                ? String(localized: "Unlimited rounds")
                : String(format: String(localized: "%lld round limit"), settings.numberOfRounds),
            tone: .normal
        )
    }

    private static func scoringItem(settings: GameSettings) -> RuleSummaryItem {
        RuleSummaryItem(
            id: "scoring",
            icon: "plus.forwardslash.minus",
            title: String(localized: "Scoring"),
            detail: String(
                format: String(localized: "Vote +%lld · Survival +%lld · Guess +%lld"),
                settings.pointsForCorrectVote,
                settings.pointsForImposterSurvival,
                settings.pointsForImposterGuess
            ),
            tone: .normal
        )
    }

    private static func issueItem(_ issue: RuleValidation.Issue) -> RuleSummaryItem {
        switch issue {
        case .tooFewPlayers(let minimum, _):
            return RuleSummaryItem(
                id: "tooFewPlayers",
                icon: "exclamationmark.triangle.fill",
                title: String(localized: "More players needed"),
                detail: String(
                    format: String(localized: "Add players until at least %lld are seated."),
                    minimum
                ),
                tone: .blocking
            )
        case .tooManyPlayers(let maximum, _):
            return RuleSummaryItem(
                id: "tooManyPlayers",
                icon: "exclamationmark.triangle.fill",
                title: String(localized: "Too many players"),
                detail: String(
                    format: String(localized: "Remove players until no more than %lld are seated."),
                    maximum
                ),
                tone: .blocking
            )
        case .missingCustomPrompt:
            return RuleSummaryItem(
                id: "missingCustomPrompt",
                icon: "text.badge.xmark",
                title: String(localized: "Prompt required"),
                detail: String(localized: "Custom prompt games need a theme before starting."),
                tone: .blocking
            )
        }
    }

    private static func normalizedPrompt(_ prompt: String?) -> String? {
        guard let prompt else { return nil }
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedCategories(from categories: [String]?) -> [String]? {
        guard let categories else { return nil }

        var seen: Set<String> = []
        let filtered = categories.compactMap { category -> String? in
            let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
            guard GameSettings.availableCategories.contains(trimmed), !seen.contains(trimmed) else {
                return nil
            }
            seen.insert(trimmed)
            return trimmed
        }

        return filtered.isEmpty ? nil : filtered
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
