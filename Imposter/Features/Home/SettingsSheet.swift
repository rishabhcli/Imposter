//
//  SettingsSheet.swift
//  Imposter
//
//  Default game settings configuration sheet.
//

import SwiftUI

// MARK: - SettingsSheet

/// Sheet for configuring default game settings
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameStore.self) private var store

    @State private var settings: GameSettings

    init() {
        // Initialize with default settings - will be updated in onAppear
        _settings = State(initialValue: .default)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Game Mode Section
                Section {
                    Picker("Game Mode", selection: $settings.gameMode) {
                        ForEach(GameSettings.GameMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                } header: {
                    Text("Game Mode")
                } footer: {
                    Text(settings.gameMode.description)
                }

                // Imposter Options Section (only show in classic mode)
                if settings.gameMode == .classic {
                    Section {
                        Toggle("Allow Word Guess", isOn: $settings.allowImposterWordGuess)
                        Toggle("AI Hints for Imposter", isOn: $settings.imposterHintEnabled)
                    } header: {
                        Text("Imposter Options")
                    } footer: {
                        Text("Word guess lets the caught Imposter try for bonus points. AI hints give the Imposter a cryptic clue instead of just the category.")
                    }
                }

                // Word Settings Section
                Section {
                    Picker("Default Difficulty", selection: $settings.wordPackDifficulty) {
                        ForEach(GameSettings.Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                } header: {
                    Text("Words")
                }

                // Rounds Section
                Section {
                    Stepper(
                        "Rounds: \(settings.numberOfRounds == 0 ? "Unlimited" : "\(settings.numberOfRounds)")",
                        value: $settings.numberOfRounds,
                        in: 0...10
                    )
                } header: {
                    Text("Game Length")
                } footer: {
                    Text("Set to 0 for unlimited rounds. The game ends after the set number of rounds.")
                }

                // Scoring Section
                Section {
                    Stepper("Correct Vote: \(settings.pointsForCorrectVote) pts", value: $settings.pointsForCorrectVote, in: 1...5)
                    Stepper("Imposter Survives: \(settings.pointsForImposterSurvival) pts", value: $settings.pointsForImposterSurvival, in: 1...5)
                    Stepper("Word Guess Bonus: \(settings.pointsForImposterGuess) pts", value: $settings.pointsForImposterGuess, in: 1...10)
                } header: {
                    Text("Scoring")
                }

                // Reset Section
                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        settings = .default
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.dispatch(.updateSettings(settings))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                settings = store.settings
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview

#Preview {
    SettingsSheet()
        .environment(GameStore())
}
