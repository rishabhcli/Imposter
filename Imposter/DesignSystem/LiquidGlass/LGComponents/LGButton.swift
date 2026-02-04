//
//  LGButton.swift
//  Imposter
//
//  Button components with Liquid Glass styling - no gradients.
//

import SwiftUI

// MARK: - LGButton

/// A button with Liquid Glass styling in primary, secondary, or tertiary styles.
struct LGButton: View {
    /// Button style variants
    enum Style {
        case primary    // White background
        case secondary  // Glass effect
        case tertiary   // Text-only, no background
    }

    let title: String
    let style: Style
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        switch style {
        case .primary:
            primaryButton
        case .secondary:
            secondaryButton
        case .tertiary:
            tertiaryButton
        }
    }

    // MARK: - Button Variants

    private var primaryButton: some View {
        Button(action: wrappedAction) {
            buttonContent
        }
        .buttonStyle(.glassProminent)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.4 : 1.0)
        .saturation(isDisabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }

    private var secondaryButton: some View {
        Button(action: wrappedAction) {
            buttonContent
        }
        .buttonStyle(.glass)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.4 : 1.0)
        .saturation(isDisabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }

    private var tertiaryButton: some View {
        Button(action: wrappedAction) {
            buttonContent
        }
        .buttonStyle(.glass(.clear))
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.4 : 1.0)
        .saturation(isDisabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
    
    private func wrappedAction() {
        HapticManager.buttonTap()
        action()
    }

    // MARK: - Private

    private var buttonContent: some View {
        HStack(spacing: LGSpacing.small) {
            if isLoading {
                ProgressView()
                    .tint(foregroundColor)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
            }

            Text(title)
                .font(LGTypography.labelLarge)
        }
        .foregroundStyle(foregroundColor)
        .frame(minWidth: 100)
        .frame(height: LGSpacing.buttonHeight)
        .padding(.horizontal, LGSpacing.large)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .black
        case .secondary:
            return .white
        case .tertiary:
            return .white
        }
    }
}

// MARK: - Large Button Variant

/// A larger button for primary actions (like "Start Game")
struct LGLargeButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.buttonTap()
            action()
        } label: {
            HStack(spacing: LGSpacing.medium) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: LGSpacing.buttonHeightLarge)
        }
        .buttonStyle(.glassProminent)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.4 : 1.0)
        .saturation(isDisabled ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// MARK: - Icon Button

/// A circular icon-only button with Liquid Glass styling
struct LGIconButton: View {
    let icon: String
    let style: LGButton.Style
    let action: () -> Void

    init(
        icon: String,
        style: LGButton.Style = .secondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        switch style {
        case .primary:
            primaryIconButton
        case .secondary:
            secondaryIconButton
        case .tertiary:
            tertiaryIconButton
        }
    }

    private var primaryIconButton: some View {
        Button(action: action) {
            iconContent
        }
        .buttonStyle(.glassProminent)
    }

    private var secondaryIconButton: some View {
        Button(action: action) {
            iconContent
        }
        .buttonStyle(.glass)
    }

    private var tertiaryIconButton: some View {
        Button(action: action) {
            iconContent
        }
        .buttonStyle(.glass(.clear))
    }

    private var iconContent: some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: LGSpacing.minTouchTarget, height: LGSpacing.minTouchTarget)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .black
        case .secondary:
            return .white
        case .tertiary:
            return .white
        }
    }
}

// MARK: - Pill Button (for tags/chips)

struct LGPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            Button(action: action) {
                Text(title)
                    .font(LGTypography.labelMedium)
                    .padding(.horizontal, LGSpacing.medium)
                    .padding(.vertical, LGSpacing.small)
            }
            .buttonStyle(.glassProminent)
        } else {
            Button(action: action) {
                Text(title)
                    .font(LGTypography.labelMedium)
                    .padding(.horizontal, LGSpacing.medium)
                    .padding(.vertical, LGSpacing.small)
            }
            .buttonStyle(.glass)
        }
    }
}

// MARK: - Preview

#Preview("LGButton Variants") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        VStack(spacing: LGSpacing.large) {
            LGButton("Primary", style: .primary, icon: "play.fill") { }

            LGButton("Secondary", style: .secondary, icon: "gear") { }

            LGButton("Tertiary", style: .tertiary) { }

            LGLargeButton("Start Game", icon: "play.fill") { }

            HStack(spacing: LGSpacing.medium) {
                LGIconButton(icon: "xmark", style: .secondary) { }
                LGIconButton(icon: "checkmark", style: .primary) { }
            }

            HStack(spacing: LGSpacing.small) {
                LGPillButton(title: "Easy", isSelected: false) { }
                LGPillButton(title: "Medium", isSelected: true) { }
                LGPillButton(title: "Hard", isSelected: false) { }
            }
        }
        .padding()
    }
}
