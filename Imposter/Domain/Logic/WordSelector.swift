//
//  WordSelector.swift
//  Imposter
//
//  Word selection logic with category and difficulty filtering.
//

import Foundation

// MARK: - Word Pack Models

/// A word entry in a word pack
struct WordEntry: Codable, Sendable {
    let id: String
    let displayText: String
    let word: String
    let category: String
    let difficulty: String // "easy", "medium", "hard"
    let tags: [String]
    let localizationKey: String
    let safety: WordSafetyMetadata

    func localizedDisplayText(bundle: Bundle = .main) -> String {
        let localized = NSLocalizedString(
            localizationKey,
            bundle: bundle,
            value: displayText,
            comment: "Localized display text for a bundled Imposter word."
        )

        return localized.isEmpty ? displayText : localized
    }
}

/// Safety metadata for a word entry.
struct WordSafetyMetadata: Codable, Sendable, Equatable {
    let level: String
}

/// A category word pack loaded from JSON
struct WordPack: Codable, Sendable {
    let category: String
    let words: [WordEntry]
}

/// Metadata describing how a category behaves in party play and generated-image flows.
struct WordCategoryMetadata: Codable, Sendable, Equatable {
    let category: String
    let iconSystemName: String
    let safety: String
    let partyEnergy: Int
    let ambiguity: Int
    let imageSuitability: Int
    let tags: [String]
}

/// Catalog wrapper for bundled category metadata.
struct WordCategoryMetadataCatalog: Codable, Sendable {
    let version: Int
    let categories: [WordCategoryMetadata]
}

/// Display and verification metadata for a bundled word category.
struct WordCategorySummary: Identifiable, Sendable, Equatable {
    let name: String
    let iconSystemName: String
    let wordCount: Int
    let easyCount: Int
    let mediumCount: Int
    let hardCount: Int
    let safety: String
    let partyEnergy: Int
    let ambiguity: Int
    let imageSuitability: Int
    let tags: [String]

    var id: String { name }

    var hasLoadedWords: Bool {
        wordCount > 0
    }

    func count(for difficulty: GameSettings.Difficulty) -> Int {
        switch difficulty {
        case .easy:
            easyCount
        case .medium:
            mediumCount
        case .hard:
            hardCount
        case .mixed:
            wordCount
        }
    }
}

// MARK: - WordSelector

/// Selects words from word packs based on game settings
enum WordSelector {

    // MARK: - Fallback Words

    /// Hardcoded backup words in case JSON loading fails
    private static let fallbackWords = [
        "Apple", "Banana", "Orange", "Grape", "Lemon",
        "Dog", "Cat", "Bird", "Fish", "Rabbit",
        "Chair", "Table", "Lamp", "Book", "Clock",
        "Phone", "Computer", "Camera", "Keyboard", "Mouse"
    ]

    // MARK: - Word Selection

    /// Selects a random word based on game settings
    /// - Parameter settings: The game settings containing category and difficulty preferences
    /// - Returns: A randomly selected word
    static func selectWord(from settings: GameSettings, avoiding avoidedWords: Set<String> = []) -> String {
        // Load word packs
        let packs = loadWordPacks()

        guard !packs.isEmpty else {
            return fallbackWords.randomElement() ?? "UNKNOWN"
        }

        // Filter by selected categories
        var filteredPacks = packs
        if let selectedCategories = settings.selectedCategories, !selectedCategories.isEmpty {
            filteredPacks = packs.filter { selectedCategories.contains($0.category) }
        }

        // If no packs match the categories, use all packs
        if filteredPacks.isEmpty {
            filteredPacks = packs
        }

        // Collect all words from filtered packs
        var allWords: [WordEntry] = []
        for pack in filteredPacks {
            allWords.append(contentsOf: pack.words)
        }

        // Filter by difficulty
        let difficultyFiltered: [WordEntry]
        switch settings.wordPackDifficulty {
        case .easy:
            difficultyFiltered = allWords.filter { $0.difficulty == "easy" }
        case .medium:
            difficultyFiltered = allWords.filter { $0.difficulty == "medium" }
        case .hard:
            difficultyFiltered = allWords.filter { $0.difficulty == "hard" }
        case .mixed:
            difficultyFiltered = allWords
        }

        // Use filtered words if available, otherwise use all words
        let finalWords = difficultyFiltered.isEmpty ? allWords : difficultyFiltered
        let freshWords = words(finalWords, excluding: avoidedWords)
        let candidateWords = freshWords.isEmpty ? finalWords : freshWords

        // Return random word
        if let selected = candidateWords.randomElement() {
            return selected.localizedDisplayText()
        }

        // Ultimate fallback
        return fallbackWords.randomElement() ?? "UNKNOWN"
    }

    static func selectAlternateWord(
        matching secretWord: String,
        from settings: GameSettings,
        avoiding avoidedWords: Set<String> = []
    ) -> String? {
        let packs = packsForSelection(from: loadWordPacks(), settings: settings)
        return selectAlternateWord(
            matching: secretWord,
            in: packs,
            difficulty: settings.wordPackDifficulty,
            avoiding: avoidedWords
        )
    }

    static func selectAlternateWord(
        matching secretWord: String,
        in packs: [WordPack],
        difficulty: GameSettings.Difficulty,
        avoiding avoidedWords: Set<String> = []
    ) -> String? {
        let allWords = packs.flatMap(\.words)
        guard !allWords.isEmpty else {
            return nil
        }

        let difficultyWords = words(allWords, matching: difficulty)
        let preferredDifficultyWords = difficultyWords.isEmpty ? allWords : difficultyWords
        let blockedWords = avoidedWords.union([secretWord])
        let secretEntry = allWords.first { matches($0, displayWord: secretWord) }

        var candidateTiers: [[WordEntry]] = []
        if let secretEntry {
            candidateTiers.append(
                preferredDifficultyWords.filter {
                    $0.category == secretEntry.category && $0.difficulty == secretEntry.difficulty
                }
            )
            candidateTiers.append(allWords.filter { $0.category == secretEntry.category })
            candidateTiers.append(preferredDifficultyWords)
        }
        candidateTiers.append(preferredDifficultyWords)
        candidateTiers.append(allWords)

        for tier in candidateTiers where !tier.isEmpty {
            let playableWords = tier.filter { entry in
                isPlayableDistinctWord(entry.word, from: blockedWords)
                    && isPlayableDistinctWord(entry.localizedDisplayText(), from: blockedWords)
            }

            if let selected = bestAlternateWord(
                from: playableWords,
                matching: secretEntry,
                secretWord: secretWord
            ) {
                return selected.localizedDisplayText()
            }
        }

        return nil
    }

    // MARK: - Word Pack Loading

    /// Loads all word packs from the bundle
    /// - Returns: Array of WordPack objects
    static func loadWordPacks() -> [WordPack] {
        var packs: [WordPack] = []

        let packFiles = [
            "words_animals",
            "words_technology",
            "words_objects",
            "words_people",
            "words_movies"
        ]

        for fileName in packFiles {
            if let pack = loadWordPack(named: fileName) {
                packs.append(pack)
            }
        }

        return packs
    }

    /// Loads a single word pack from a JSON file
    /// - Parameter name: The file name without extension
    /// - Returns: WordPack if loading succeeds, nil otherwise
    private static func loadWordPack(named name: String) -> WordPack? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("WordSelector: Could not find \(name).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let pack = try JSONDecoder().decode(WordPack.self, from: data)
            return pack
        } catch {
            print("WordSelector: Failed to load \(name).json - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Category Info

    /// Returns all available category names
    static var availableCategories: [String] {
        GameSettings.availableCategories
    }

    /// Returns word count for a specific category
    static func wordCount(for category: String) -> Int {
        let packs = loadWordPacks()
        return packs.first { $0.category == category }?.words.count ?? 0
    }

    static func normalizedWordKey(_ word: String) -> String {
        normalizedTokens(in: word).joined(separator: " ")
    }

    static func isPlayableDistinctWord(_ candidate: String, from blockedWords: Set<String>) -> Bool {
        !blockedWords.contains { blockedWord in
            isNearDuplicateWord(candidate, of: blockedWord)
        }
    }

    static func isNearDuplicateWord(_ candidate: String, of reference: String) -> Bool {
        let candidateTokens = normalizedTokens(in: candidate)
        let referenceTokens = normalizedTokens(in: reference)

        guard !candidateTokens.isEmpty, !referenceTokens.isEmpty else {
            return false
        }

        let candidateKey = candidateTokens.joined(separator: " ")
        let referenceKey = referenceTokens.joined(separator: " ")

        if candidateKey == referenceKey {
            return true
        }

        let candidateSet = Set(candidateTokens)
        let referenceSet = Set(referenceTokens)
        if candidateSet.isSubset(of: referenceSet) || referenceSet.isSubset(of: candidateSet) {
            return true
        }

        let sharedTokenCount = candidateSet.intersection(referenceSet).count
        let largerTokenCount = max(candidateSet.count, referenceSet.count)
        if largerTokenCount > 1,
           Double(sharedTokenCount) / Double(largerTokenCount) >= 0.67 {
            return true
        }

        let shorterLength = min(candidateKey.count, referenceKey.count)
        guard shorterLength >= 5 else {
            return false
        }

        let distance = editDistance(between: candidateKey, and: referenceKey)
        if distance <= 1 {
            return true
        }

        let longerLength = max(candidateKey.count, referenceKey.count)
        return shorterLength >= 8
            && distance <= 2
            && Double(distance) / Double(longerLength) <= 0.2
    }

    /// Returns category summaries in the same order shown by setup.
    static var categorySummaries: [WordCategorySummary] {
        var packsByCategory: [String: WordPack] = [:]
        for pack in loadWordPacks() {
            packsByCategory[pack.category] = pack
        }

        let metadataByCategory = loadCategoryMetadata()
        return GameSettings.availableCategories.map { category in
            makeSummary(
                for: category,
                pack: packsByCategory[category],
                metadata: metadataByCategory[category]
            )
        }
    }

    private static func makeSummary(
        for category: String,
        pack: WordPack?,
        metadata: WordCategoryMetadata?
    ) -> WordCategorySummary {
        let difficultyCounts = Dictionary(grouping: pack?.words ?? []) { entry in
            entry.difficulty
        }
        .mapValues(\.count)

        return WordCategorySummary(
            name: category,
            iconSystemName: metadata?.iconSystemName ?? iconSystemName(for: category),
            wordCount: pack?.words.count ?? 0,
            easyCount: difficultyCounts["easy", default: 0],
            mediumCount: difficultyCounts["medium", default: 0],
            hardCount: difficultyCounts["hard", default: 0],
            safety: metadata?.safety ?? "general",
            partyEnergy: metadata?.partyEnergy ?? 3,
            ambiguity: metadata?.ambiguity ?? 3,
            imageSuitability: metadata?.imageSuitability ?? 3,
            tags: metadata?.tags ?? []
        )
    }

    private static func loadCategoryMetadata() -> [String: WordCategoryMetadata] {
        guard let url = Bundle.main.url(forResource: "category_metadata", withExtension: "json") else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(WordCategoryMetadataCatalog.self, from: data)
            return Dictionary(uniqueKeysWithValues: catalog.categories.map { ($0.category, $0) })
        } catch {
            print("WordSelector: Failed to load category metadata - \(error.localizedDescription)")
            return [:]
        }
    }

    private static func iconSystemName(for category: String) -> String {
        switch category {
        case "Animals":
            return "pawprint.fill"
        case "Technology":
            return "gamecontroller.fill"
        case "Objects":
            return "cube.fill"
        case "People":
            return "star.fill"
        case "Movies":
            return "film.fill"
        default:
            return "tag.fill"
        }
    }

    private static func packsForSelection(from packs: [WordPack], settings: GameSettings) -> [WordPack] {
        var filteredPacks = packs
        if let selectedCategories = settings.selectedCategories, !selectedCategories.isEmpty {
            filteredPacks = packs.filter { selectedCategories.contains($0.category) }
        }

        return filteredPacks.isEmpty ? packs : filteredPacks
    }

    private static func words(_ words: [WordEntry], matching difficulty: GameSettings.Difficulty) -> [WordEntry] {
        switch difficulty {
        case .easy:
            return words.filter { $0.difficulty == "easy" }
        case .medium:
            return words.filter { $0.difficulty == "medium" }
        case .hard:
            return words.filter { $0.difficulty == "hard" }
        case .mixed:
            return words
        }
    }

    private static func words(_ words: [WordEntry], excluding avoidedWords: Set<String>) -> [WordEntry] {
        guard !avoidedWords.isEmpty else {
            return words
        }

        return words.filter { isPlayableDistinctWord($0.word, from: avoidedWords) }
    }

    private static func matches(_ entry: WordEntry, displayWord: String) -> Bool {
        let displayKey = normalizedWordKey(displayWord)
        return normalizedWordKey(entry.word) == displayKey
            || normalizedWordKey(entry.displayText) == displayKey
            || normalizedWordKey(entry.localizedDisplayText()) == displayKey
    }

    private static func bestAlternateWord(
        from candidates: [WordEntry],
        matching secretEntry: WordEntry?,
        secretWord: String
    ) -> WordEntry? {
        candidates.sorted { lhs, rhs in
            let lhsScore = decoyCandidateScore(lhs, matching: secretEntry, secretWord: secretWord)
            let rhsScore = decoyCandidateScore(rhs, matching: secretEntry, secretWord: secretWord)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            return lhs.id < rhs.id
        }
        .first
    }

    private static func decoyCandidateScore(
        _ candidate: WordEntry,
        matching secretEntry: WordEntry?,
        secretWord: String
    ) -> Int {
        let secretTokens = normalizedTokens(in: secretEntry?.word ?? secretWord)
        let candidateTokens = normalizedTokens(in: candidate.word)
        let tokenDelta = abs(candidateTokens.count - secretTokens.count)
        let characterDelta = abs(normalizedWordKey(candidate.word).count - normalizedWordKey(secretWord).count)

        guard let secretEntry else {
            return -(tokenDelta * 25) - (characterDelta * 2)
        }

        let sharedTagCount = Set(candidate.tags.map(normalizedWordKey))
            .intersection(Set(secretEntry.tags.map(normalizedWordKey)))
            .count

        var score = 0
        if candidate.category == secretEntry.category {
            score += 500
        }
        if candidate.difficulty == secretEntry.difficulty {
            score += 300
        }
        if candidate.safety.level == secretEntry.safety.level {
            score += 50
        }

        score += sharedTagCount * 80
        score -= tokenDelta * 25
        score -= characterDelta * 2
        return score
    }

    private static func normalizedTokens(in word: String) -> [String] {
        word
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased(with: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map(canonicalToken)
            .filter { !$0.isEmpty }
    }

    private static func canonicalToken(_ token: String) -> String {
        guard token.count > 3 else {
            return token
        }

        if token.hasSuffix("ies"), token.count > 4 {
            return String(token.dropLast(3)) + "y"
        }

        if token.hasSuffix("es"), token.count > 4 {
            return String(token.dropLast(2))
        }

        if token.hasSuffix("s") {
            return String(token.dropLast())
        }

        return token
    }

    private static func editDistance(between lhs: String, and rhs: String) -> Int {
        let lhsCharacters = Array(lhs)
        let rhsCharacters = Array(rhs)

        guard !lhsCharacters.isEmpty else {
            return rhsCharacters.count
        }
        guard !rhsCharacters.isEmpty else {
            return lhsCharacters.count
        }

        var previousRow = Array(0...rhsCharacters.count)
        for (lhsIndex, lhsCharacter) in lhsCharacters.enumerated() {
            var currentRow = Array(repeating: 0, count: rhsCharacters.count + 1)
            currentRow[0] = lhsIndex + 1

            for (rhsIndex, rhsCharacter) in rhsCharacters.enumerated() {
                let deletion = previousRow[rhsIndex + 1] + 1
                let insertion = currentRow[rhsIndex] + 1
                let substitution = previousRow[rhsIndex] + (lhsCharacter == rhsCharacter ? 0 : 1)
                currentRow[rhsIndex + 1] = min(deletion, min(insertion, substitution))
            }

            previousRow = currentRow
        }

        return previousRow[rhsCharacters.count]
    }
}
