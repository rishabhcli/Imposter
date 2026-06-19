//
//  GeneratedWordPolicy.swift
//  Imposter
//
//  Deterministic guardrails for AI-generated secret words.
//

import Foundation

// MARK: - GeneratedWordPolicy

enum GeneratedWordPolicy {
    enum Rejection: Error, Equatable, Sendable {
        case empty
        case tooLong
        case tooManyWords
        case promptEcho
        case sentenceLike
        case unsafeContent
    }

    /// Reasons a raw user-supplied theme prompt is rejected before it is ever
    /// sent to the on-device model. This is the first line of defense: it keeps
    /// blatant prompt-injection / jailbreak attempts and obviously unsafe themes
    /// out of the generation pipeline entirely.
    enum PromptRejection: Error, Equatable, Sendable {
        case empty
        case tooLong
        case injectionAttempt
        case unsafeTheme
    }

    /// Maximum length of a user theme. Themes are short ("space animals",
    /// "kitchen gadgets"); anything longer is almost certainly an attempt to
    /// smuggle instructions into the prompt.
    static let maximumPromptLength = 60

    static func validate(rawResponse: String, prompt: String) -> Result<String, Rejection> {
        let candidate = sanitizedCandidate(from: rawResponse)

        guard !candidate.isEmpty else {
            return .failure(.empty)
        }

        guard candidate.count <= 50 else {
            return .failure(.tooLong)
        }

        guard !looksLikeSentence(candidate) else {
            return .failure(.sentenceLike)
        }

        guard wordCount(in: candidate) <= 4 else {
            return .failure(.tooManyWords)
        }

        guard WordSelector.isPlayableDistinctWord(candidate, from: [prompt]) else {
            return .failure(.promptEcho)
        }

        // Output-side safety net. Guided generation plus the model's own
        // guardrails block almost everything, but the word is shown verbatim to
        // players, so we deterministically reject any term that slips through.
        guard !containsUnsafeContent(candidate) else {
            return .failure(.unsafeContent)
        }

        return .success(displayCased(candidate))
    }

    // MARK: - Input Validation (pre-generation guardrail)

    /// Validates and sanitizes a raw user theme *before* it reaches the model.
    /// - Returns: the trimmed prompt on success, or the reason it was rejected.
    static func validateUserPrompt(_ rawPrompt: String) -> Result<String, PromptRejection> {
        let trimmed = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.empty)
        }

        guard trimmed.count <= maximumPromptLength else {
            return .failure(.tooLong)
        }

        if looksLikePromptInjection(trimmed) {
            return .failure(.injectionAttempt)
        }

        if containsUnsafeContent(trimmed) {
            return .failure(.unsafeTheme)
        }

        return .success(trimmed)
    }

    /// Detects blatant attempts to override the system instructions or coax the
    /// model out of its role. Matched case-insensitively as phrases so ordinary
    /// themes (which never contain these sequences) are unaffected.
    static func looksLikePromptInjection(_ value: String) -> Bool {
        let lowered = value.lowercased()
        return injectionMarkers.contains { lowered.contains($0) }
    }

    /// Word-boundary aware check for obviously unsafe content. Tokenizes on
    /// non-alphanumerics so the "Scunthorpe problem" (innocent words containing
    /// a blocked substring) is avoided, while still catching multi-word phrases.
    static func containsUnsafeContent(_ value: String) -> Bool {
        let lowered = value.lowercased()

        if unsafePhrases.contains(where: { lowered.contains($0) }) {
            return true
        }

        let tokens = Set(
            lowered
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )
        return !tokens.isDisjoint(with: unsafeTokens)
    }

    /// Phrases that signal an injection / jailbreak attempt against the theme.
    private static let injectionMarkers: [String] = [
        "ignore previous",
        "ignore all previous",
        "ignore the above",
        "disregard previous",
        "disregard the above",
        "forget your instructions",
        "forget previous",
        "new instructions",
        "system prompt",
        "you are now",
        "act as",
        "pretend to be",
        "developer mode",
        "jailbreak",
        "reveal your",
        "repeat the theme",
        "output the theme",
        "say the theme",
        "instead of a word"
    ]

    /// Multi-word unsafe phrases checked as substrings.
    private static let unsafePhrases: [String] = [
        "child abuse",
        "how to make a bomb",
        "kill yourself"
    ]

    /// Single tokens that mark a theme as inappropriate for a family party game
    /// (sexual-explicit, graphic violence, self-harm, hard drugs). Kept compact
    /// and deliberately conservative; the model's own guardrails cover the rest.
    private static let unsafeTokens: Set<String> = [
        "porn", "pornographic", "nude", "nudity", "naked", "nsfw", "explicit",
        "sex", "sexual", "rape", "incest", "fetish", "orgy",
        "suicide", "selfharm",
        "heroin", "cocaine", "meth", "methamphetamine",
        "genocide", "massacre", "terrorist", "terrorism"
    ]

    private static func sanitizedCandidate(from rawResponse: String) -> String {
        let firstLine = rawResponse
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""

        var candidate = firstLine
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: edgeTrimCharacters)

        candidate = removeListMarker(from: candidate)
        candidate = removeKnownPrefix(from: candidate)
        candidate = candidate
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: edgeTrimCharacters)

        return candidate
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func removeListMarker(from value: String) -> String {
        var candidate = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if let first = candidate.first, bulletMarkerCharacters.contains(first) {
            candidate.removeFirst()
            return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let characters = Array(candidate)
        if characters.count >= 2,
           characters[0].isNumber,
           characters[1] == "." || characters[1] == ")" {
            candidate.removeFirst(2)
            return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return candidate
    }

    private static func removeKnownPrefix(from value: String) -> String {
        var candidate = value
        let prefixes = [
            "related word:",
            "word:",
            "answer:",
            "response:",
            "secret word:"
        ]

        var didRemovePrefix = true
        while didRemovePrefix {
            didRemovePrefix = false
            let lowercased = candidate.lowercased()
            for prefix in prefixes where lowercased.hasPrefix(prefix) {
                candidate.removeFirst(prefix.count)
                candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
                didRemovePrefix = true
                break
            }
        }

        return candidate
    }

    private static func wordCount(in value: String) -> Int {
        value
            .split { character in
                character.isWhitespace || character == "-" || character == "/"
            }
            .count
    }

    private static func looksLikeSentence(_ value: String) -> Bool {
        let lowercased = value.lowercased()
        let blockedPrefixes = [
            "here is",
            "here's",
            "i would",
            "the word",
            "a good"
        ]

        if blockedPrefixes.contains(where: { lowercased.hasPrefix($0) }) {
            return true
        }

        return value.contains(". ") || value.contains("?") || value.contains("!")
    }

    private static func displayCased(_ value: String) -> String {
        value
            .split(separator: " ")
            .map { token in
                let text = String(token)
                if text.contains(where: \.isNumber) || text.dropFirst().contains(where: \.isUppercase) {
                    return text
                }

                guard let first = text.first else {
                    return text
                }

                return first.uppercased() + text.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }

    private static var edgeTrimCharacters: CharacterSet {
        var characters = CharacterSet.whitespacesAndNewlines
        characters.insert(charactersIn: "\"'`“”‘’.,:;")
        return characters
    }

    private static let bulletMarkerCharacters: Set<Character> = ["-", "*", "•"]
}
