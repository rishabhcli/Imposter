//
//  HomeView.swift
//  Imposter
//
//  Unified home screen with category selection and player setup.
//  Premium Liquid Glass design with animated title and immersive starfield background.
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
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 50
    @State private var buttonsOpacity: Double = 0

    // Category selection state
    @State private var selectedCategories: Set<String> = []
    @State private var useCustomPrompt = false
    @State private var customPrompt = ""
    @FocusState private var isTextFieldFocused: Bool

    // Player setup state
    @State private var newPlayerID: UUID?
    private let minPlayers = 3

    var body: some View {
        ZStack {
            // Persistent black background with stars
            Color.black.ignoresSafeArea()
            StarfieldView()

            // Content - Only scroll for player setup
            if setupStep == .home {
                // Home screen - no scroll
                homeContent
                    .padding(.horizontal, LGSpacing.large)
            } else if setupStep == .categorySelection {
                // Category selection - no scroll
                categoryContent
                    .padding(.horizontal, LGSpacing.large)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // Player setup - scrollable for long player lists
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            playerContent
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))

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
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheet()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Glow pulsing
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
        
        // Logo entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Buttons entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            buttonsOffset = 0
            buttonsOpacity = 1.0
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            // Hero section with logo
            heroSection
            
            Spacer()
                .frame(height: 60)
            
            // Main actions
            mainActionsSection
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)
            
            Spacer()
                .frame(height: 32)
            
            // Secondary actions
            secondaryActionsSection
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)
            
            Spacer()
            
            // Footer
            footerSection
                .opacity(buttonsOpacity)
        }
        .frame(minHeight: 700)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: LGSpacing.large) {
            // Animated spy icon with glass effect
            ZStack {
                // Glass circle background
                Circle()
                    .fill(.clear)
                    .frame(width: 120, height: 120)
                    .glassEffect(
                        .regular.tint(.cyan.opacity(0.2)),
                        in: .circle
                    )
                
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.5), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 130, height: 130)
                    .blur(radius: 2)
                    .opacity(glowIntensity * 0.8)
                
                // Spy silhouette with question mark
                ZStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .cyan.opacity(glowIntensity * 0.4), radius: 12)
                    
                    // Question mark badge
                    ZStack {
                        Circle()
                            .fill(.clear)
                            .frame(width: 28, height: 28)
                            .glassEffect(
                                .regular.tint(.cyan.opacity(0.5)),
                                in: .circle
                            )
                        
                        Text("?")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 24, y: -22)
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            
            // Title
            VStack(spacing: LGSpacing.small) {
                Text("IMPOSTER")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(glowIntensity), radius: 2)
                    .shadow(color: .cyan.opacity(glowIntensity * 0.7), radius: 8)
                    .shadow(color: .cyan.opacity(glowIntensity * 0.5), radius: 16)
                
                Text("The Social Deduction Party Game")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Imposter, The Social Deduction Party Game")
    }
    
    // MARK: - Main Actions Section
    
    private var mainActionsSection: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                setupStep = .categorySelection
            }
            HapticManager.buttonTap()
        } label: {
            HStack(spacing: LGSpacing.medium) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("New Game")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
        .buttonStyle(.glassProminent)
        .tint(.cyan)
        .accessibilityIdentifier("newGameButton")
    }
    
    // MARK: - Secondary Actions Section
    
    private var secondaryActionsSection: some View {
        HStack(spacing: LGSpacing.medium) {
            // How to Play
            Button {
                showHowToPlay = true
                HapticManager.buttonTap()
            } label: {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 16))
                    Text("How to Play")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("howToPlayButton")
            
            // Settings
            Button {
                showSettings = true
                HapticManager.buttonTap()
            } label: {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                    Text("Settings")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(.glass)
            .accessibilityIdentifier("settingsButton")
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: LGSpacing.small) {
            Text("3+ Players • Pass & Play")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("v1.0")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.bottom, LGSpacing.large)
    }

    // MARK: - Compact Title (for other steps)
    
    private var compactTitleSection: some View {
        VStack(spacing: LGSpacing.small) {
            Text("IMPOSTER")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white)
                .shadow(color: .cyan.opacity(glowIntensity * 0.5), radius: 6)
            
            Text(subtitleText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, LGSpacing.large)
        .padding(.bottom, LGSpacing.medium)
    }

    private var subtitleText: String {
        switch setupStep {
        case .home:
            return "The Social Deduction Party Game"
        case .categorySelection:
            return "Choose Word Source"
        case .playerSetup:
            return "\(store.players.count) Players"
        }
    }

    // MARK: - Category Selection Content

    private var categoryContent: some View {
        VStack(spacing: LGSpacing.large) {
            compactTitleSection
            
            // Mode selector
            modeSelector
            
            // Content area with fixed top alignment to prevent layout shift
            VStack(alignment: .leading, spacing: 0) {
                if useCustomPrompt {
                    customPromptSection
                } else {
                    categorySection
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .animation(.none, value: useCustomPrompt)

            // Navigation buttons
            HStack(spacing: LGSpacing.medium) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        setupStep = .home
                    }
                    HapticManager.buttonTap()
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.glass)

                Button {
                    saveSettings()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        setupStep = .playerSetup
                    }
                    HapticManager.buttonTap()
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Text("Continue")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.glassProminent)
                .tint(.cyan)
                .disabled(!canContinueCategory)
            }
        }
    }
    
    private var canContinueCategory: Bool {
        if useCustomPrompt {
            return !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
    
    private var modeSelector: some View {
        Picker("Word Source", selection: $useCustomPrompt) {
            Label("Random", systemImage: "shuffle")
                .tag(false)
            Label("Custom", systemImage: "wand.and.stars")
                .tag(true)
        }
        .pickerStyle(.segmented)
        .onChange(of: useCustomPrompt) { _, _ in
            HapticManager.buttonTap()
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            HStack {
                Text("Pick Categories")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                if !selectedCategories.isEmpty {
                    Button {
                        withAnimation {
                            selectedCategories.removeAll()
                        }
                        HapticManager.buttonTap()
                    } label: {
                        Text("Clear")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.cyan)
                    }
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: LGSpacing.small),
                GridItem(.flexible(), spacing: LGSpacing.small)
            ], spacing: LGSpacing.small) {
                ForEach(GameSettings.availableCategories, id: \.self) { category in
                    CategoryTile(
                        title: category,
                        icon: categoryIcon(for: category),
                        isSelected: selectedCategories.contains(category)
                    ) {
                        toggleCategory(category)
                    }
                }
            }
            
            Text(selectedCategories.isEmpty ? "All categories will be used" : "\(selectedCategories.count) selected")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var customPromptSection: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            Text("Enter a Theme")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            
            HStack(spacing: LGSpacing.medium) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(.cyan)
                
                TextField("e.g., 80s rock bands...", text: $customPrompt)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
            }
            .padding(LGSpacing.medium)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .id("customPromptField")
        }
    }

    // MARK: - Player Setup Content

    private var playerContent: some View {
        VStack(spacing: LGSpacing.large) {
            compactTitleSection
            
            // Show selected source
            selectedSourceBadge

            // Players list
            playersSection

            // Game settings
            gameSettingsSection

            // Validation
            if !store.canStartGame {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange.opacity(0.8))
                    Text("Add at least \(minPlayers) players")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.8))
                }
                .padding(LGSpacing.small)
                .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .capsule)
            }

            // Navigation buttons
            HStack(spacing: LGSpacing.medium) {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        setupStep = .categorySelection
                    }
                    HapticManager.buttonTap()
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.glass)

                Button {
                    startGameWithPreloading()
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        if store.isPreparingGame {
                            ProgressView()
                                .tint(.white)
                            Text("Loading...")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Start Game")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.glassProminent)
                .tint(.cyan)
                .disabled(!store.canStartGame || store.isPreparingGame)
            }
        }
    }

    private var selectedSourceBadge: some View {
        HStack(spacing: LGSpacing.small) {
            if useCustomPrompt {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(.cyan)
                Text(customPrompt)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            } else if !selectedCategories.isEmpty {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.cyan)
                Text(selectedCategories.joined(separator: ", "))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            } else {
                Image(systemName: "shuffle")
                    .foregroundStyle(.cyan)
                Text("All Categories")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
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

            Button {
                addNewPlayer()
            } label: {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Player")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.cyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LGSpacing.medium)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.cyan.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                }
            }
            .buttonStyle(.glass)
        }
        .padding(LGSpacing.medium)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var gameSettingsSection: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            Text("Game Settings")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            if !useCustomPrompt {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundStyle(.cyan)
                        .frame(width: 24)
                    Text("Difficulty")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("Difficulty", selection: difficultyBinding) {
                        ForEach(GameSettings.Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    .labelsHidden()
                    .tint(.cyan)
                }

                Divider()
                    .background(.white.opacity(0.1))
            }

            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.cyan)
                    .frame(width: 24)
                Text("Discussion Timer")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Picker("Timer", selection: timerBinding) {
                    ForEach(GameSettings.timerOptions, id: \.self) { minutes in
                        Text(GameSettings.timerDisplayText(minutes: minutes)).tag(minutes)
                    }
                }
                .labelsHidden()
                .tint(.cyan)
            }
        }
        .padding(LGSpacing.medium)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Animals": return "pawprint.fill"
        case "Technology": return "gamecontroller.fill"
        case "Objects": return "cube.fill"
        case "Celebrities": return "star.fill"
        case "People": return "star.fill"
        case "Movies & TV": return "film.fill"
        case "Movies": return "film.fill"
        default: return "tag.fill"
        }
    }

    private func toggleCategory(_ category: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }
        HapticManager.categoryToggled()
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

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            if let lastPlayer = store.players.last {
                newPlayerID = lastPlayer.id
            }
        }
        HapticManager.buttonTap()
    }

    private func startGameWithPreloading() {
        store.prepareAndStartGame()
        HapticManager.buttonTap()
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

// MARK: - Category Tile (Liquid Glass)

struct CategoryTile: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: LGSpacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .cyan : .white.opacity(0.7))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .contentShape(Rectangle())
            .glassEffect(
                isSelected ? .regular.tint(.cyan.opacity(0.3)).interactive() : .regular.interactive(),
                in: .rect(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.cyan)
                    .background {
                        Circle()
                            .fill(.black)
                            .padding(2)
                    }
                    .offset(x: 6, y: -6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .accessibilityLabel("\(title), \(isSelected ? "selected" : "not selected")")
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
