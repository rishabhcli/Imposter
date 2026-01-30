//
//  LGTypography.swift
//  Imposter
//
//  Typography scale for the Liquid Glass design system.
//  Uses SF Pro Rounded for a playful, modern feel.
//

import SwiftUI

// MARK: - LGTypography

/// Typography scale with semantic naming.
/// Uses SF Pro Rounded for a friendly, modern aesthetic.
enum LGTypography {

    // MARK: - Display Styles (Largest) - Rounded for playfulness

    /// Largest display text - for main titles like "Imposter"
    static let displayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)

    /// Medium display text - for section headers
    static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)

    /// Small display text - for prominent labels
    static let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)

    // MARK: - Headline Styles - Rounded with good weight

    /// Large headline - for screen titles
    static let headlineLarge = Font.system(size: 24, weight: .bold, design: .rounded)

    /// Medium headline - for card titles
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// Small headline - for section headers
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .rounded)

    // MARK: - Body Styles - Default for readability

    /// Large body text - for primary content
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// Medium body text - for secondary content
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    /// Small body text - for tertiary content
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Label Styles - Rounded for buttons and interactive elements

    /// Large label - for button text
    static let labelLarge = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Medium label - for interactive elements
    static let labelMedium = Font.system(size: 15, weight: .medium, design: .rounded)

    /// Small label - for captions and metadata
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .rounded)

    // MARK: - Special Styles

    /// Monospaced style for clues/codes
    static let mono = Font.system(.body, design: .monospaced).weight(.medium)

    /// Timer display style - large, rounded, bold
    static let timer = Font.system(size: 56, weight: .bold, design: .rounded)

    /// Score display style
    static let score = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Hero title style for "IMPOSTER" branding - dramatic and bold
    static let heroTitle = Font.system(size: 52, weight: .black, design: .rounded)

    /// Smaller hero title variant
    static let heroTitleSmall = Font.system(size: 40, weight: .black, design: .rounded)

    /// Legacy scary title (serif) - keeping for compatibility
    static let scaryTitle = Font.system(size: 56, weight: .black, design: .serif)
    static let scaryTitleSmall = Font.system(size: 42, weight: .black, design: .serif)

    // MARK: - Expressive Styles

    /// Fun accent text - for emphasis
    static let accent = Font.system(size: 16, weight: .bold, design: .rounded)

    /// Large number display (for scores, timers)
    static let numberLarge = Font.system(size: 64, weight: .heavy, design: .rounded)

    /// Extra small caption
    static let caption = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - View Modifier for Typography

extension View {
    /// Applies typography style with appropriate line spacing
    func typography(_ style: Font) -> some View {
        self.font(style)
    }
}

// MARK: - Gradient Text Modifier

struct GradientTextModifier: ViewModifier {
    let gradient: LinearGradient

    func body(content: Content) -> some View {
        content
            .foregroundStyle(gradient)
    }
}

extension View {
    /// Applies a gradient to text
    func gradientForeground(_ colors: [Color], startPoint: UnitPoint = .leading, endPoint: UnitPoint = .trailing) -> some View {
        self.foregroundStyle(
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
        )
    }
}

// MARK: - Glow Text Modifier

struct GlowTextModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.5), radius: radius)
            .shadow(color: color.opacity(0.3), radius: radius * 1.5)
    }
}

extension View {
    /// Adds a neon glow effect
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowTextModifier(color: color, radius: radius))
    }
}

// MARK: - Text Extensions

extension Text {
    /// Creates styled display text
    func displayStyle(_ size: DisplaySize = .large) -> Text {
        switch size {
        case .large:
            return self.font(LGTypography.displayLarge)
        case .medium:
            return self.font(LGTypography.displayMedium)
        case .small:
            return self.font(LGTypography.displaySmall)
        }
    }

    /// Creates styled headline text
    func headlineStyle(_ size: HeadlineSize = .large) -> Text {
        switch size {
        case .large:
            return self.font(LGTypography.headlineLarge)
        case .medium:
            return self.font(LGTypography.headlineMedium)
        case .small:
            return self.font(LGTypography.headlineSmall)
        }
    }

    /// Creates styled body text
    func bodyStyle(_ size: BodySize = .large) -> Text {
        switch size {
        case .large:
            return self.font(LGTypography.bodyLarge)
        case .medium:
            return self.font(LGTypography.bodyMedium)
        case .small:
            return self.font(LGTypography.bodySmall)
        }
    }

    /// Creates styled label text
    func labelStyle(_ size: LabelSize = .large) -> Text {
        switch size {
        case .large:
            return self.font(LGTypography.labelLarge)
        case .medium:
            return self.font(LGTypography.labelMedium)
        case .small:
            return self.font(LGTypography.labelSmall)
        }
    }
}

// MARK: - Size Enums

enum DisplaySize {
    case large, medium, small
}

enum HeadlineSize {
    case large, medium, small
}

enum BodySize {
    case large, medium, small
}

enum LabelSize {
    case large, medium, small
}
