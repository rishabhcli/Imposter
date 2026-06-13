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
    }

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

        return .success(displayCased(candidate))
    }

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
