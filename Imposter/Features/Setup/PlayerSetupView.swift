//
//  PlayerSetupView.swift
//  Imposter
//
//  Player configuration and game settings before starting.
//

import SwiftUI

// MARK: - PlayerSetupView

/// Screen for adding players and configuring game settings
struct PlayerSetupView: View {
    @Environment(GameStore.self) private var store
    @State private var newPlayerID: UUID?

    // Minimum and maximum player counts
    private let minPlayers = 3
    private let maxPlayers = 10

    var body: some View {
        ScrollView {
            VStack(spacing: LGSpacing.large) {
                // Header
                headerSection

                // Players list
                playersSection

                // Game settings (difficulty and timer)
                gameSettingsSection

                // Validation message
                if !store.canStartGame {
                    validationMessage
                }

                // Start button
                startButton
            }
            .padding(LGSpacing.large)
        }
        .background(backgroundGradient)
        .navigationTitle("Add Players")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        AnimatedBackground(style: .subtle)
    }

    private var headerSection: some View {
        VStack(spacing: LGSpacing.small) {
            // Show selected word source
            if store.settings.wordSource == .customPrompt {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "wand.and.stars")
                        .foregroundStyle(LGColors.accentPrimary)
                    Text("Custom: \(store.settings.customWordPrompt ?? "")")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, LGSpacing.small)
            } else if let categories = store.settings.selectedCategories, !categories.isEmpty {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(LGColors.accentPrimary)
                    Text(categories.joined(separator: ", "))
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, LGSpacing.small)
            }

            Text("\(store.players.count) of \(maxPlayers) players")
                .font(LGTypography.bodyMedium)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var playersSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(spacing: LGSpacing.medium) {
                ForEach(store.players) { player in
                    PlayerRowView(
                        player: player,
                        shouldFocus: player.id == newPlayerID
                    )

                    if player.id != store.players.last?.id {
                        Divider()
                    }
                }

                // Add player button
                if store.players.count < maxPlayers {
                    Button {
                        addNewPlayer()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Player")
                        }
                        .font(LGTypography.labelLarge)
                        .foregroundStyle(LGColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LGSpacing.small)
                    }
                    .accessibilityIdentifier("addPlayerButton")
                }
            }
        }
    }

    private var gameSettingsSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                Text("Game Settings")
                    .font(LGTypography.headlineSmall)
                    .foregroundStyle(.primary)

                // Difficulty picker (only for random word mode)
                if store.settings.wordSource == .randomPack {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundStyle(LGColors.accentPrimary)
                        Text("Difficulty")
                            .font(LGTypography.bodyMedium)
                        Spacer()
                        Picker("Difficulty", selection: difficultyBinding) {
                            ForEach(GameSettings.Difficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.displayName).tag(difficulty)
                            }
                        }
                        .labelsHidden()
                    }

                    Divider()
                }

                // Timer settings
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(LGColors.accentPrimary)
                    Text("Clue Timer")
                        .font(LGTypography.bodyMedium)
                    Spacer()
                    Picker("Timer", selection: timerBinding) {
                        ForEach(GameSettings.timerOptions, id: \.self) { minutes in
                            Text(GameSettings.timerDisplayText(minutes: minutes)).tag(minutes)
                        }
                    }
                    .labelsHidden()
                }

                if store.settings.clueTimerMinutes > 0 {
                    Text("Each player has \(store.settings.clueTimerMinutes) minute\(store.settings.clueTimerMinutes == 1 ? "" : "s") per clue round")
                        .font(LGTypography.bodySmall)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var validationMessage: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(LGColors.warning)
            Text("Add at least \(minPlayers) players to start")
                .font(LGTypography.bodyMedium)
                .foregroundStyle(LGColors.warning)
        }
        .padding(LGSpacing.medium)
        .glassBackground(cornerRadius: LGSpacing.cornerRadiusSmall, tint: LGColors.warningTint)
    }

    private var startButton: some View {
        LGLargeButton(
            "Start Game",
            icon: "play.fill",
            isDisabled: !store.canStartGame
        ) {
            store.dispatch(.startGame)
        }
        .padding(.top, LGSpacing.medium)
        .accessibilityIdentifier("startGameButton")
    }

    // MARK: - Helpers

    private func addNewPlayer() {
        let playerNumber = store.players.count + 1
        store.addNewPlayer(name: "Player \(playerNumber)")

        // Set the new player ID to trigger focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let lastPlayer = store.players.last {
                newPlayerID = lastPlayer.id
            }
        }
    }

    // MARK: - Bindings

    private var difficultyBinding: Binding<GameSettings.Difficulty> {
        Binding(
            get: { store.settings.wordPackDifficulty },
            set: { newValue in
                var settings = store.settings
                settings.wordPackDifficulty = newValue
                store.dispatch(.updateSettings(settings))
            }
        )
    }

    private var timerBinding: Binding<Int> {
        Binding(
            get: { store.settings.clueTimerMinutes },
            set: { newValue in
                var settings = store.settings
                settings.clueTimerEnabled = newValue > 0
                settings.clueTimerMinutes = newValue
                store.dispatch(.updateSettings(settings))
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PlayerSetupView()
    }
    .environment(GameStore.preview)
}
