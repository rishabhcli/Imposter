//
//  CategorySelectionView.swift
//  Imposter
//
//  Category selection and custom prompt entry - shown before player setup.
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
            // Background
            backgroundGradient

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: LGSpacing.extraLarge) {
                        // Header
                        headerSection

                        // Word source toggle
                        wordSourceToggle

                        if useCustomPrompt {
                            // Custom AI prompt section
                            customPromptSection
                                .id("customPromptSection")
                        } else {
                            // Category selection
                            categorySection
                        }

                        // Continue button
                        continueButton

                        // Extra space for keyboard
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(LGSpacing.large)
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
        }
        .navigationTitle("Imposter")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $navigateToPlayerSetup) {
            PlayerSetupView()
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        ZStack {
            LGColors.darkBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    LGColors.darkBackgroundSecondary,
                    LGColors.darkBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var headerSection: some View {
        VStack(spacing: LGSpacing.small) {
            Text("Select Word Source")
                .font(LGTypography.headlineLarge)
                .foregroundStyle(.white)

            Text("Choose categories or create a custom word")
                .font(LGTypography.bodyMedium)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, LGSpacing.large)
    }

    private var wordSourceToggle: some View {
        VStack(spacing: LGSpacing.medium) {
            // Random categories option
            Button {
                withAnimation(LGMaterials.springAnimation) {
                    useCustomPrompt = false
                }
            } label: {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "dice.fill")
                        .font(.title2)
                        .foregroundStyle(useCustomPrompt ? .secondary : LGColors.accentPrimary)

                    VStack(alignment: .leading, spacing: LGSpacing.extraSmall) {
                        Text("Random Word")
                            .font(LGTypography.labelLarge)
                            .foregroundStyle(.primary)

                        Text("Pick from themed categories")
                            .font(LGTypography.bodySmall)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !useCustomPrompt {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LGColors.accentPrimary)
                    }
                }
                .padding(LGSpacing.medium)
                .frame(maxWidth: .infinity)
                .glassEffect(
                    useCustomPrompt
                        ? .regular.interactive()
                        : .regular.tint(LGColors.accentPrimary).interactive(),
                    in: .rect(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            // Custom AI prompt option
            Button {
                withAnimation(LGMaterials.springAnimation) {
                    useCustomPrompt = true
                }
            } label: {
                HStack(spacing: LGSpacing.medium) {
                    Image(systemName: "wand.and.stars")
                        .font(.title2)
                        .foregroundStyle(useCustomPrompt ? LGColors.accentPrimary : .secondary)

                    VStack(alignment: .leading, spacing: LGSpacing.extraSmall) {
                        Text("Custom Word")
                            .font(LGTypography.labelLarge)
                            .foregroundStyle(.primary)

                        Text("Enter a theme for a random word")
                            .font(LGTypography.bodySmall)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if useCustomPrompt {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LGColors.accentPrimary)
                    }
                }
                .padding(LGSpacing.medium)
                .frame(maxWidth: .infinity)
                .glassEffect(
                    useCustomPrompt
                        ? .regular.tint(LGColors.accentPrimary).interactive()
                        : .regular.interactive(),
                    in: .rect(cornerRadius: LGSpacing.cornerRadiusMedium, style: .continuous)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var categorySection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                Text("Categories")
                    .font(LGTypography.headlineSmall)
                    .foregroundStyle(.primary)

                Text("Select one or more categories (or leave empty for all)")
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(.secondary)

                // Category chips
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
        }
    }

    private var customPromptSection: some View {
        LGCard(cornerRadius: LGSpacing.cornerRadiusLarge) {
            VStack(alignment: .leading, spacing: LGSpacing.medium) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(LGColors.accentPrimary)
                    Text("Custom Word")
                        .font(LGTypography.headlineSmall)
                }

                Text("Enter a theme or topic for a random word.")
                    .font(LGTypography.bodySmall)
                    .foregroundStyle(.secondary)

                LGTextField("Enter a theme or topic...", text: $customPrompt, icon: "wand.and.stars", isFocused: $isTextFieldFocused)
                    .padding(.top, LGSpacing.small)
            }
        }
    }

    private var continueButton: some View {
        VStack(spacing: LGSpacing.medium) {
            if useCustomPrompt && customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(LGColors.warning)
                    Text("Enter a custom word to continue")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(LGColors.warning)
                }
            }

            LGLargeButton(
                "Continue to Player Setup",
                icon: "arrow.right",
                isDisabled: useCustomPrompt && customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                saveSettings()
                navigateToPlayerSetup = true
            }
        }
        .padding(.top, LGSpacing.medium)
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
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LGSpacing.small) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(LGTypography.labelMedium)
            }
            .padding(.horizontal, LGSpacing.medium)
            .padding(.vertical, LGSpacing.small)
            .background {
                Capsule()
                    .fill(.clear)
                    .glassEffect(
                        isSelected
                            ? .regular.tint(LGColors.accentPrimary).interactive()
                            : .regular.interactive(),
                        in: .capsule
                    )
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
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
