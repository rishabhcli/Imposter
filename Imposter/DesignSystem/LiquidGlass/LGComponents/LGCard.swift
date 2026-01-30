//
//  LGCard.swift
//  Imposter
//
//  Reusable card component with Liquid Glass effect.
//

import SwiftUI

// MARK: - LGCard

/// A card container with Liquid Glass background effect.
/// Automatically applies appropriate padding, border, and shadow.
struct LGCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let elevation: CGFloat

    /// Creates a new Liquid Glass card
    /// - Parameters:
    ///   - cornerRadius: The corner radius of the card
    ///   - elevation: Shadow elevation level (1, 2, or 3)
    ///   - content: The content to display inside the card
    init(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        elevation: CGFloat = LGMaterials.elevation2,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(.all, LGSpacing.medium)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            }
            .lgShadow(elevation)
    }
}

// MARK: - Tinted Card Variant

/// A card with a colored tint on the glass effect
struct LGTintedCard<Content: View>: View {
    let content: Content
    let tintColor: Color
    let cornerRadius: CGFloat
    let elevation: CGFloat

    init(
        tintColor: Color,
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        elevation: CGFloat = LGMaterials.elevation2,
        @ViewBuilder content: () -> Content
    ) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(.all, LGSpacing.medium)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(tintColor),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(tintColor.opacity(0.3), lineWidth: 1)
            }
            .lgShadow(elevation)
    }
}

// MARK: - Interactive Card

/// A card that responds to touch with interactive glass effects
struct LGInteractiveCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let action: () -> Void

    init(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(.all, LGSpacing.medium)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.clear)
                        .glassEffect(
                            .regular.interactive(),
                            in: .rect(cornerRadius: cornerRadius, style: .continuous)
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .lgShadow(LGMaterials.elevation2)
    }
}

// MARK: - Preview

#Preview("LGCard Variants") {
    ZStack {
        LinearGradient(
            colors: [.purple, .blue, .cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: LGSpacing.large) {
            LGCard {
                VStack(alignment: .leading, spacing: LGSpacing.small) {
                    Text("Standard Card")
                        .font(LGTypography.headlineSmall)
                    Text("This is a Liquid Glass card with default settings.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }

            LGTintedCard(tintColor: .blue) {
                VStack(alignment: .leading, spacing: LGSpacing.small) {
                    Text("Tinted Card")
                        .font(LGTypography.headlineSmall)
                    Text("This card has a blue tint applied.")
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
            }

            LGInteractiveCard(action: { print("Tapped!") }) {
                HStack {
                    Text("Interactive Card")
                        .font(LGTypography.headlineSmall)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding()
    }
}
