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
    @State private var categorySummaries = WordSelector.categorySummaries
    @State private var inspectedCategory: WordCategorySummary?
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
        .sheet(item: $inspectedCategory) { summary in
            CategoryDetailSheet(
                summary: summary,
                selectedDifficulty: store.settings.wordPackDifficulty
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            syncFromSettings()
            categorySummaries = WordSelector.categorySummaries
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
            wordUniverseSummary

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
                ForEach(categorySummaries) { summary in
                    WordCategoryTile(
                        summary: summary,
                        selectedDifficulty: store.settings.wordPackDifficulty,
                        isSelected: selectedCategories.contains(summary.name),
                        onInspect: {
                        inspectedCategory = summary
                        },
                        action: {
                        toggleCategory(summary.name)
                        }
                    )
                }
            }
            
            // Helper text
            Text(selectionHelperText)
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
                        .accessibilityIdentifier(AccessibilityIDs.customPromptField)
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
                .accessibilityIdentifier(AccessibilityIDs.categoryContinueButton)
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

    private var selectedWordCount: Int {
        let activeSummaries = selectedCategories.isEmpty
            ? categorySummaries
            : categorySummaries.filter { selectedCategories.contains($0.name) }
        return activeSummaries.reduce(0) { total, summary in
            total + summary.count(for: store.settings.wordPackDifficulty)
        }
    }

    private var totalWordCount: Int {
        categorySummaries.reduce(0) { $0 + $1.wordCount }
    }

    private var selectionHelperText: String {
        let wordText = String.localizedStringWithFormat(
            String(localized: "%lld words"),
            selectedWordCount
        )

        if selectedCategories.isEmpty {
            return "\(String(localized: "All categories will be used")) - \(wordText)"
        }

        let categoryText = String.localizedStringWithFormat(
            String(localized: "%lld selected categories"),
            selectedCategories.count
        )
        return "\(categoryText) - \(wordText)"
    }

    private var wordUniverseSummary: some View {
        HStack(spacing: LGSpacing.small) {
            SummaryPill(
                icon: "square.grid.2x2.fill",
                value: "\(categorySummaries.count)",
                label: String(localized: "packs")
            )

            SummaryPill(
                icon: "textformat.abc",
                value: "\(totalWordCount)",
                label: String(localized: "words")
            )

            SummaryPill(
                icon: "speedometer",
                value: selectedDifficultyText,
                label: String(localized: "Difficulty")
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String.localizedStringWithFormat(
                String(localized: "%lld words across %lld packs"),
                totalWordCount,
                categorySummaries.count
            )
        )
    }

    // MARK: - Helpers

    private func syncFromSettings() {
        if store.settings.wordSource == .customPrompt {
            useCustomPrompt = true
            customPrompt = store.settings.customWordPrompt ?? ""
            selectedCategories.removeAll()
        } else {
            useCustomPrompt = false
            selectedCategories = Set(store.settings.selectedCategories ?? [])
        }
    }

    private var selectedDifficultyText: String {
        switch store.settings.wordPackDifficulty {
        case .easy:
            return String(localized: "Easy")
        case .medium:
            return String(localized: "Medium")
        case .hard:
            return String(localized: "Hard")
        case .mixed:
            return String(localized: "Mixed")
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
            let orderedSelection = categorySummaries
                .map(\.name)
                .filter { selectedCategories.contains($0) }
            settings.selectedCategories = orderedSelection.isEmpty ? nil : orderedSelection
        }
        store.dispatch(.updateSettings(settings))
    }
}

// MARK: - Word Universe Components

private struct SummaryPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white.opacity(0.82))
        .frame(maxWidth: .infinity, minHeight: 42)
        .padding(.horizontal, LGSpacing.small)
        .glassEffect(.regular.tint(.cyan.opacity(0.12)), in: .rect(cornerRadius: 12))
    }
}

private struct WordCategoryTile: View {
    let summary: WordCategorySummary
    let selectedDifficulty: GameSettings.Difficulty
    let isSelected: Bool
    let onInspect: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LGSpacing.small) {
            HStack(alignment: .top) {
                Image(systemName: summary.iconSystemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .cyan)
                    .frame(width: 32, height: 32)
                    .glassEffect(.regular.tint(.cyan.opacity(0.18)), in: .circle)

                Spacer(minLength: LGSpacing.small)

                Button {
                    onInspect()
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(summary.name) pack details")

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(isSelected ? .cyan : .white.opacity(0.28))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(summary.name))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(wordCountText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            difficultyCounts
                .padding(.top, 2)

            metadataRow
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(LGSpacing.medium)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .glassEffect(
                    isSelected
                        ? .regular.tint(.cyan.opacity(0.28)).interactive()
                        : .regular.tint(.white.opacity(0.05)).interactive(),
                    in: .rect(cornerRadius: 16, style: .continuous)
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSelected ? .cyan.opacity(0.85) : .white.opacity(0.18),
                    lineWidth: isSelected ? 1.5 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture(perform: action)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringKey(summary.name)))
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(isSelected ? "Double tap to remove this category." : "Double tap to include this category.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            action()
        }
        .accessibilityAction(named: "Show Pack Details") {
            onInspect()
        }
        .accessibilityIdentifier(AccessibilityIDs.categoryTile(summary.name))
    }

    private var wordCountText: String {
        String.localizedStringWithFormat(
            String(localized: "%lld words"),
            summary.wordCount
        )
    }

    private var accessibilityValue: String {
        "\(wordCountText), \(summary.easyCount) easy, \(summary.mediumCount) medium, \(summary.hardCount) hard, energy \(summary.partyEnergy), ambiguity \(summary.ambiguity), image suitability \(summary.imageSuitability), \(summary.safety)"
    }

    private var difficultyCounts: some View {
        HStack(spacing: 5) {
            DifficultyCountPill(
                label: "E",
                count: summary.easyCount,
                isActive: isActive(.easy)
            )

            DifficultyCountPill(
                label: "M",
                count: summary.mediumCount,
                isActive: isActive(.medium)
            )

            DifficultyCountPill(
                label: "H",
                count: summary.hardCount,
                isActive: isActive(.hard)
            )
        }
    }

    private func isActive(_ difficulty: GameSettings.Difficulty) -> Bool {
        selectedDifficulty == .mixed || selectedDifficulty == difficulty
    }

    private var metadataRow: some View {
        HStack(spacing: 5) {
            MetadataScorePill(icon: "bolt.fill", value: summary.partyEnergy)
            MetadataScorePill(icon: "questionmark", value: summary.ambiguity)
            MetadataScorePill(icon: "photo.fill", value: summary.imageSuitability)

            Text(LocalizedStringKey(summary.safety.capitalized))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white.opacity(0.68))
                .frame(maxWidth: .infinity, minHeight: 24)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.08))
                )
        }
    }
}

private struct DifficultyCountPill: View {
    let label: String
    let count: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))

            Text("\(count)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(isActive ? .white : .white.opacity(0.5))
        .frame(maxWidth: .infinity, minHeight: 22)
        .background(
            Capsule()
                .fill(isActive ? .cyan.opacity(0.24) : .white.opacity(0.08))
        )
    }
}

private struct MetadataScorePill: View {
    let icon: String
    let value: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))

            Text("\(value)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(.white.opacity(0.68))
        .frame(maxWidth: .infinity, minHeight: 24)
        .background(
            Capsule()
                .fill(.white.opacity(0.08))
        )
    }
}

private struct CategoryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let summary: WordCategorySummary
    let selectedDifficulty: GameSettings.Difficulty

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LGSpacing.large) {
                    header
                    difficultySection
                    metadataSection
                    tagsSection
                }
                .padding(LGSpacing.large)
            }
            .background(AnimatedBackground(style: .subtle))
            .navigationTitle("Pack Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            HStack(spacing: LGSpacing.medium) {
                Image(systemName: summary.iconSystemName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.cyan)
                    .frame(width: 54, height: 54)
                    .glassEffect(.regular.tint(.cyan.opacity(0.18)), in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(summary.name))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(
                        String.localizedStringWithFormat(
                            String(localized: "%lld words"),
                            summary.wordCount
                        )
                    )
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: LGSpacing.small)
            }
        }
    }

    private var difficultySection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                sectionTitle("Difficulty Mix", icon: "speedometer")

                DifficultyMeter(
                    label: String(localized: "Easy"),
                    count: summary.easyCount,
                    total: summary.wordCount,
                    isActive: isActive(.easy)
                )

                DifficultyMeter(
                    label: String(localized: "Medium"),
                    count: summary.mediumCount,
                    total: summary.wordCount,
                    isActive: isActive(.medium)
                )

                DifficultyMeter(
                    label: String(localized: "Hard"),
                    count: summary.hardCount,
                    total: summary.wordCount,
                    isActive: isActive(.hard)
                )
            }
        }
    }

    private var metadataSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                sectionTitle("Pack Signals", icon: "slider.horizontal.3")

                MetadataMeter(
                    label: String(localized: "Party Energy"),
                    icon: "bolt.fill",
                    value: summary.partyEnergy
                )

                MetadataMeter(
                    label: String(localized: "Ambiguity"),
                    icon: "questionmark",
                    value: summary.ambiguity
                )

                MetadataMeter(
                    label: String(localized: "Image Fit"),
                    icon: "photo.fill",
                    value: summary.imageSuitability
                )

                HStack {
                    Label(String(localized: "Safety"), systemImage: "checkmark.shield.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))

                    Spacer()

                    Text(LocalizedStringKey(summary.safety.capitalized))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan)
                }
            }
        }
    }

    private var tagsSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                sectionTitle("Tags", icon: "tag.fill")

                FlowTagLayout(tags: summary.tags)
            }
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
    }

    private func isActive(_ difficulty: GameSettings.Difficulty) -> Bool {
        selectedDifficulty == .mixed || selectedDifficulty == difficulty
    }
}

private struct DifficultyMeter: View {
    let label: String
    let count: Int
    let total: Int
    let isActive: Bool

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Spacer()

                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isActive ? .cyan : .secondary)
            }

            ProgressView(value: progress)
                .tint(isActive ? .cyan : .white.opacity(0.35))
        }
    }
}

private struct MetadataMeter: View {
    let label: String
    let icon: String
    let value: Int

    var body: some View {
        HStack(spacing: LGSpacing.small) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            Spacer()

            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= value ? .cyan : .white.opacity(0.18))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityLabel("\(label) \(value) out of 5")
        }
    }
}

private struct FlowTagLayout: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: LGSpacing.small)], alignment: .leading, spacing: LGSpacing.small) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, LGSpacing.small)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.08))
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
    .environment(GameStore())
}
