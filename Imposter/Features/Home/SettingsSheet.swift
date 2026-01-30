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
                // Clue Rounds Section
                Section {
                    Stepper(
                        "Clue Rounds: \(settings.numberOfClueRounds)",
                        value: $settings.numberOfClueRounds,
                        in: 1...5
                    )
                } header: {
                    Text("Gameplay")
                } footer: {
                    Text("Number of times each player gives a clue")
                }

                // Discussion Timer Section
                Section {
                    Toggle("Enable Timer", isOn: $settings.discussionTimerEnabled)

                    if settings.discussionTimerEnabled {
                        Stepper(
                            "\(settings.discussionSeconds) seconds",
                            value: $settings.discussionSeconds,
                            in: 30...300,
                            step: 30
                        )
                    }
                } header: {
                    Text("Discussion Phase")
                }

                // Imposter Options Section
                Section {
                    Toggle("Allow Word Guess", isOn: $settings.allowImposterWordGuess)
                    Toggle("AI Hints for Imposter", isOn: $settings.imposterHintEnabled)
                } header: {
                    Text("Imposter Options")
                } footer: {
                    Text("Word guess lets the caught Imposter try for bonus points. AI hints give the Imposter a cryptic clue instead of just the category.")
                }

                // Scoring Section
                Section {
                    HStack {
                        Text("Correct Vote")
                        Spacer()
                        Stepper(
                            "\(settings.pointsForCorrectVote) pts",
                            value: $settings.pointsForCorrectVote,
                            in: 1...5
                        )
                    }

                    HStack {
                        Text("Imposter Survival")
                        Spacer()
                        Stepper(
                            "\(settings.pointsForImposterSurvival) pts",
                            value: $settings.pointsForImposterSurvival,
                            in: 1...5
                        )
                    }

                    HStack {
                        Text("Word Guess Bonus")
                        Spacer()
                        Stepper(
                            "\(settings.pointsForImposterGuess) pts",
                            value: $settings.pointsForImposterGuess,
                            in: 1...5
                        )
                    }
                } header: {
                    Text("Scoring")
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
