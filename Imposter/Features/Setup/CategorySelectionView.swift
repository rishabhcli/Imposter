//
//  CategorySelectionView.swift
//  Imposter
//
//  Category selection and custom prompt entry - Liquid Glass design.
//

import SwiftUI

// MARK: - CategorySelectionView

/// Screen for selecting word categories or entering a custom AI prompt
struct CategorySelectionView: View {
    @Environment(GameStore.self) private var store
    @State private var selectedCategories: Set<String> = []
    @State private var useCustomPrompt = false
    @State private var customPrompt = ""
    @State private var navigateToPlayerSetup = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground(style: .subtle)
            
            VStack(spacing: 0) {
                // Scrollable content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: LGSpacing.extraLarge) {
                            // Mode selector (segmented style)
                            modeSelector
                            
                            // Content based on mode
                            if useCustomPrompt {
                                customPromptCard
                                    .id("customPromptSection")
                            } else {
                                categoryGrid
                            }
                        }
                        .padding(.horizontal, LGSpacing.large)
                        .padding(.top, LGSpacing.medium)
                        .padding(.bottom, 120)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: isTextFieldFocused) { _, focused in
                        if focused {
                            withAnimation {
                                proxy.scrollTo("customPromptSection", anchor: .center)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                // Fixed bottom button
                bottomSection
            }
        }
        .navigationTitle("Choose Words")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToPlayerSetup) {
            PlayerSetupView()
        }
    }

    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        HStack(spacing: 0) {
            // Random Word option
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    useCustomPrompt = false
                }
                HapticManager.buttonTap()
            } label: {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Random")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(!useCustomPrompt ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    if !useCustomPrompt {
                        Capsule()
                            .fill(.clear)
                            .glassEffect(
                                .regular.tint(.cyan.opacity(0.4)),
                                in: .capsule
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Custom Word option
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    useCustomPrompt = true
                }
                HapticManager.buttonTap()
            } label: {
                HStack(spacing: LGSpacing.small) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Custom")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(useCustomPrompt ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    if useCustomPrompt {
                        Capsule()
                            .fill(.clear)
                            .glassEffect(
                                .regular.tint(.cyan.opacity(0.4)),
                                in: .capsule
                            )
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Category Grid
    
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: LGSpacing.medium) {
            // Section header
            HStack {
                Text("Pick Categories")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                if !selectedCategories.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            .padding(.horizontal, LGSpacing.small)
            
            // Category cards in a grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: LGSpacing.medium),
                GridItem(.flexible(), spacing: LGSpacing.medium)
            ], spacing: LGSpacing.medium) {
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
            
            // Helper text
            Text(selectedCategories.isEmpty ? "All categories will be used" : "\(selectedCategories.count) selected")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, LGSpacing.small)
        }
    }

    // MARK: - Custom Prompt Card
    
    private var customPromptCard: some View {
        VStack(alignment: .leading, spacing: LGSpacing.large) {
            // Prompt input
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                Text("Enter a Theme")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(.cyan)
                    
                    TextField("e.g., 80s rock bands, fast food chains...", text: $customPrompt)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.white)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                }
                .padding(LGSpacing.medium)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
            }
            
            // Example suggestions
            VStack(alignment: .leading, spacing: LGSpacing.small) {
                Text("Try these")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LGSpacing.small) {
                        ForEach(["Fast Food", "NBA Teams", "Disney Villains", "90s Songs", "Superheroes"], id: \.self) { suggestion in
                            Button {
                                customPrompt = suggestion
                                HapticManager.buttonTap()
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(.horizontal, LGSpacing.medium)
                                    .padding(.vertical, LGSpacing.small)
                                    .glassEffect(.regular, in: .capsule)
                            }
                            .buttonStyle(.glass)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [.clear, LGColors.darkBackground.opacity(0.8), LGColors.darkBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            
            // Button container
            VStack(spacing: LGSpacing.small) {
                if useCustomPrompt && customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Enter a theme to continue")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.8))
                }
                
                Button {
                    saveSettings()
                    navigateToPlayerSetup = true
                    HapticManager.buttonTap()
                } label: {
                    HStack(spacing: LGSpacing.small) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(canContinue ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .glassEffect(
                        canContinue
                            ? .regular.tint(.cyan.opacity(0.3))
                            : .regular,
                        in: .rect(cornerRadius: 16)
                    )
                }
                .buttonStyle(.glass)
                .disabled(!canContinue)
            }
            .padding(.horizontal, LGSpacing.large)
            .padding(.bottom, LGSpacing.large)
            .background(LGColors.darkBackground)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canContinue: Bool {
        if useCustomPrompt {
            return !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
    .environment(GameStore())
}
