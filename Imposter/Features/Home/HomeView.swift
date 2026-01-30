//
//  HomeView.swift
//  Imposter
//
//  Unified home screen with category selection and player setup.
//  LED title and starfield background persist throughout.
//

import SwiftUI

// MARK: - Setup Step

enum SetupStep {
    case home
    case categorySelection
    case playerSetup
}

// MARK: - HomeView

/// The main menu screen with integrated setup flow
struct HomeView: View {
    @Environment(GameStore.self) private var store
    @State private var setupStep: SetupStep = .home
    @State private var showHowToPlay = false
    @State private var showSettings = false
    @State private var glowIntensity: Double = 0.5

    // Category selection state
    @State private var selectedCategories: Set<String> = []
    @State private var useCustomPrompt = false
    @State private var customPrompt = ""
    @FocusState private var isTextFieldFocused: Bool

    // Player setup state
    @State private var newPlayerID: UUID?
    private let minPlayers = 3
    private let maxPlayers = 10

    var body: some View {
        ZStack {
            // Persistent black background with stars
            Color.black.ignoresSafeArea()
            StarfieldView()

            // Content
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: LGSpacing.large) {
                        // LED glowing title - always visible
                        titleSection
                            .padding(.top, LGSpacing.extraLarge)

                        // Dynamic content based on setup step
                        switch setupStep {
                        case .home:
                            homeContent

                        case .categorySelection:
                            categoryContent
                                .transition(.move(edge: .trailing).combined(with: .opacity))

                        case .playerSetup:
                            playerContent
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }

                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, LGSpacing.large)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isTextFieldFocused) { _, focused in
                    if focused {
                        withAnimation {
                            proxy.scrollTo("customPromptField", anchor: .center)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowIntensity = 1.0
            }
        }
    }

    // MARK: - Title Section (Always Visible)

    private var titleSection: some View {
        VStack(spacing: LGSpacing.medium) {
            // LED glowing "IMPOSTER" text
            Text("IMPOSTER")
                .font(.system(size: setupStep == .home ? 56 : 36, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .shadow(color: .cyan.opacity(glowIntensity), radius: 2)
                .shadow(color: .cyan.opacity(glowIntensity), radius: 4)
                .shadow(color: .cyan.opacity(glowIntensity * 0.9), radius: 10)
                .shadow(color: .cyan.opacity(glowIntensity * 0.8), radius: 20)
                .shadow(color: .cyan.opacity(glowIntensity * 0.6), radius: 40)
                .shadow(color: .blue.opacity(glowIntensity * 0.3), radius: 60)
                .animation(.easeInOut(duration: 0.3), value: setupStep)

            // Subtitle changes based on step
            Text(subtitleText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .animation(.easeInOut, value: setupStep)

            // Spy silhouette icon only on home screen
            if setupStep == .home {
                ZStack {
                    // Shadow/glow behind
                    Image(systemName: "person.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.cyan.opacity(glowIntensity * 0.3))
                        .blur(radius: 20)

                    // Main silhouette
                    Image(systemName: "person.fill")
                        .font(.system(size: 65))
                        .foregroundStyle(.white.opacity(0.7))
                        .shadow(color: .cyan.opacity(glowIntensity * 0.6), radius: 12)

                    // Question mark overlay (mystery element)
                    Image(systemName: "questionmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.cyan.opacity(glowIntensity * 0.8))
                        .offset(y: -5)
                }
                .padding(.top, LGSpacing.medium)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Imposter, \(subtitleText)")
    }

    private var subtitleText: String {
        switch setupStep {
        case .home:
            return "The Social Deduction Party Game"
        case .categorySelection:
            return "Choose Word Source"
        case .playerSetup:
            return "\(store.players.count) of \(maxPlayers) Players"
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        VStack(spacing: LGSpacing.large) {
            Spacer()
                .frame(height: LGSpacing.extraLarge)

            // New Game button
            Button {
                withAnimation(LGMaterials.springAnimation) {
                    setupStep = .categorySelection
                }
            } label: {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("New Game")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: LGSpacing.buttonHeightLarge)
            }
            .buttonStyle(.glassProminent)
            .accessibilityIdentifier("newGameButton")

            // Secondary buttons
            HStack(spacing: LGSpacing.medium) {
                Button {
                    showHowToPlay = true
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "book.fill")
                        Text("How to Play")
                    }
                    .font(LGTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: LGSpacing.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("howToPlayButton")

                Button {
                    showSettings = true
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .font(LGTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: LGSpacing.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityIdentifier("settingsButton")
            }

            // Version
            Text("v1.0")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.top, LGSpacing.medium)
        }
    }

    // MARK: - Category Selection Content

    private var categoryContent: some View {
        VStack(spacing: LGSpacing.large) {
            // Word source toggle
            wordSourceToggle

            if useCustomPrompt {
                customPromptSection
            } else {
                categorySection
            }

            // Navigation buttons
            HStack(spacing: LGSpacing.medium) {
                // Back button
                Button {
                    withAnimation(LGMaterials.springAnimation) {
                        setupStep = .home
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(LGTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: LGSpacing.buttonHeight)
                }
                .buttonStyle(.glass)

                // Continue button
                Button {
                    saveSettings()
                    withAnimation(LGMaterials.springAnimation) {
                        setupStep = .playerSetup
                    }
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                    }
                    .font(LGTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: LGSpacing.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .disabled(useCustomPrompt && customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(useCustomPrompt && customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
    }

    private var wordSourceToggle: some View {
        VStack(spacing: LGSpacing.medium) {
            // Random word option
            Button {
                withAnimation(LGMaterials.springAnimation) {
                    useCustomPrompt = false
                }
            } label: {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundStyle(useCustomPrompt ? Color.secondary : Color.cyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Random Word")
                            .font(LGTypography.labelLarge)
                            .foregroundStyle(.white)

                        Text("Pick from themed categories")
                            .font(LGTypography.bodySmall)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    if !useCustomPrompt {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.cyan)
                    }
                }
                .padding(LGSpacing.medium)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)

            // Custom word option
            Button {
                withAnimation(LGMaterials.springAnimation) {
                    useCustomPrompt = true
                }
            } label: {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(useCustomPrompt ? Color.cyan : Color.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom Word")
                            .font(LGTypography.labelLarge)
                            .foregroundStyle(.white)

                        Text("Enter a theme for a random word")
                            .font(LGTypography.bodySmall)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    if useCustomPrompt {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.cyan)
                    }
                }
                .padding(LGSpacing.medium)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            Text("Categories")
                .font(LGTypography.headlineSmall)
                .foregroundStyle(.white)

            Text("Select one or more (or leave empty for all)")
                .font(LGTypography.bodySmall)
                .foregroundStyle(.white.opacity(0.6))

            FlowLayout(spacing: LGSpacing.small) {
                ForEach(GameSettings.availableCategories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        icon: categoryIcon(for: category),
                        isSelected: selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
        }
        .padding(LGSpacing.large)
        .glassEffect(.regular, in: .rect(cornerRadius: LGSpacing.cornerRadiusLarge))
    }

    private var customPromptSection: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.cyan)
                Text("Custom Word")
                    .font(LGTypography.headlineSmall)
                    .foregroundStyle(.white)
            }

            Text("Enter a theme or topic for a random word.")
                .font(LGTypography.bodySmall)
                .foregroundStyle(.white.opacity(0.6))

            LGTextField("Enter a theme or topic...", text: $customPrompt, icon: "wand.and.stars", isFocused: $isTextFieldFocused)
                .id("customPromptField")
        }
        .padding(LGSpacing.large)
        .glassEffect(.regular, in: .rect(cornerRadius: LGSpacing.cornerRadiusLarge))
    }

    // MARK: - Player Setup Content

    private var playerContent: some View {
        VStack(spacing: LGSpacing.large) {
            // Show selected source
            selectedSourceBadge

            // Players list
            playersSection

            // Game settings
            gameSettingsSection

            // Validation
            if !store.canStartGame {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Add at least \(minPlayers) players to start")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.orange)
                }
            }

            // Navigation buttons
            HStack(spacing: LGSpacing.medium) {
                Button {
                    withAnimation(LGMaterials.springAnimation) {
                        setupStep = .categorySelection
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(LGTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: LGSpacing.buttonHeight)
                }
                .buttonStyle(.glass)

                Button {
                    startGameWithPreloading()
                } label: {
                    HStack {
                        if store.isPreparingGame {
                            ProgressView()
                                .tint(.white)
                            Text("Preparing...")
                        } else {
                            Image(systemName: "play.fill")
                            Text("Start Game")
                        }
                    }
                    .font(LGTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .frame(height: LGSpacing.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .disabled(!store.canStartGame || store.isPreparingGame)
                .opacity(store.canStartGame ? 1 : 0.5)
            }
        }
    }

    private var selectedSourceBadge: some View {
        HStack(spacing: LGSpacing.small) {
            if useCustomPrompt {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(.cyan)
                Text("Theme: \(customPrompt)")
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(.white.opacity(0.7))
            } else if !selectedCategories.isEmpty {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.cyan)
                Text(selectedCategories.joined(separator: ", "))
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Image(systemName: "dice.fill")
                    .foregroundStyle(.cyan)
                Text("All Categories")
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, LGSpacing.medium)
        .padding(.vertical, LGSpacing.small)
        .glassEffect(.regular, in: .capsule)
    }

    private var playersSection: some View {
        VStack(spacing: LGSpacing.medium) {
            ForEach(store.players) { player in
                PlayerRowView(
                    player: player,
                    shouldFocus: player.id == newPlayerID
                )
            }

            if store.players.count < maxPlayers {
                Button {
                    addNewPlayer()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Player")
                    }
                    .font(LGTypography.labelLarge)
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LGSpacing.medium)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(LGSpacing.large)
        .glassEffect(.regular, in: .rect(cornerRadius: LGSpacing.cornerRadiusLarge))
    }

    private var gameSettingsSection: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            Text("Game Settings")
                .font(LGTypography.headlineSmall)
                .foregroundStyle(.white)

            if !useCustomPrompt {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundStyle(.cyan)
                    Text("Difficulty")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("Difficulty", selection: difficultyBinding) {
                        ForEach(GameSettings.Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    .labelsHidden()
                }

                Divider()
                    .background(.white.opacity(0.2))
            }

            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.cyan)
                Text("Clue Timer")
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.white)
                Spacer()
                Picker("Timer", selection: timerBinding) {
                    ForEach(GameSettings.timerOptions, id: \.self) { minutes in
                        Text(GameSettings.timerDisplayText(minutes: minutes)).tag(minutes)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(LGSpacing.large)
        .glassEffect(.regular, in: .rect(cornerRadius: LGSpacing.cornerRadiusLarge))
    }

    // MARK: - Helpers

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Animals": return "pawprint.fill"
        case "Technology": return "desktopcomputer"
        case "Objects": return "cube.fill"
        case "People": return "person.2.fill"
        case "Movies": return "film.fill"
        default: return "tag.fill"
        }
    }

    private func toggleCategory(_ category: String) {
        withAnimation(LGMaterials.springAnimation) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
    }

    private func saveSettings() {
        var settings = store.settings
        if useCustomPrompt {
            settings.wordSource = .customPrompt
            settings.customWordPrompt = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            settings.selectedCategories = nil
        } else {
            settings.wordSource = .randomPack
            settings.customWordPrompt = nil
            settings.selectedCategories = selectedCategories.isEmpty ? nil : Array(selectedCategories)
        }
        store.dispatch(.updateSettings(settings))
    }

    private func addNewPlayer() {
        let playerNumber = store.players.count + 1
        store.addNewPlayer(name: "Player \(playerNumber)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let lastPlayer = store.players.last {
                newPlayerID = lastPlayer.id
            }
        }
    }

    private func startGameWithPreloading() {
        // Prepare game first (generates word + starts image generation), then transitions
        store.prepareAndStartGame()
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

// MARK: - Starfield View

struct StarfieldView: View {
    @State private var stars: [Star] = []
    @State private var featureStars: [Star] = []

    struct Star: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var blinkSpeed: Double
        var hasGlow: Bool = false
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    BlinkingStar(star: star)
                        .position(x: star.x * geometry.size.width,
                                  y: star.y * geometry.size.height)
                }

                ForEach(featureStars) { star in
                    FeatureStar(star: star)
                        .position(x: star.x * geometry.size.width,
                                  y: star.y * geometry.size.height)
                }
            }
            .onAppear {
                generateStars()
            }
        }
    }

    private func generateStars() {
        stars = (0..<150).map { _ in
            Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 1...2.5),
                opacity: Double.random(in: 0.2...0.8),
                blinkSpeed: Double.random(in: 0.8...3.0)
            )
        }

        featureStars = (0..<15).map { _ in
            Star(
                x: CGFloat.random(in: 0.05...0.95),
                y: CGFloat.random(in: 0.05...0.95),
                size: CGFloat.random(in: 3...6),
                opacity: Double.random(in: 0.7...1.0),
                blinkSpeed: Double.random(in: 1.0...2.5),
                hasGlow: true
            )
        }
    }
}

// MARK: - Blinking Star

struct BlinkingStar: View {
    let star: StarfieldView.Star
    @State private var isVisible = true

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: star.size, height: star.size)
            .opacity(isVisible ? star.opacity : star.opacity * 0.1)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: star.blinkSpeed)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...3))
                ) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - Feature Star

struct FeatureStar: View {
    let star: StarfieldView.Star
    @State private var brightness: Double = 0.5
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(brightness * 0.3))
                .frame(width: star.size * 4, height: star.size * 4)
                .blur(radius: 8)

            Circle()
                .fill(.white.opacity(brightness * 0.6))
                .frame(width: star.size * 2, height: star.size * 2)
                .blur(radius: 3)

            Circle()
                .fill(.white)
                .frame(width: star.size, height: star.size)

            Rectangle()
                .fill(.white.opacity(brightness * 0.8))
                .frame(width: star.size * 3, height: 1)
                .blur(radius: 1)

            Rectangle()
                .fill(.white.opacity(brightness * 0.8))
                .frame(width: 1, height: star.size * 3)
                .blur(radius: 1)
        }
        .scaleEffect(scale)
        .opacity(star.opacity)
        .onAppear {
            withAnimation(
                .easeInOut(duration: star.blinkSpeed)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
            ) {
                brightness = 1.0
                scale = 1.2
            }
        }
    }
}

// MARK: - Preview

#Preview("Dark Mode") {
    HomeView()
        .environment(GameStore())
        .preferredColorScheme(.dark)
}
