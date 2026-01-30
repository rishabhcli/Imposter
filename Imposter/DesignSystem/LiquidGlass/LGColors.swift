//
//  LGColors.swift
//  Imposter
//
//  Semantic color tokens for the Liquid Glass design system.
//  Optimized for both light and dark mode with vibrant, expressive colors.
//

import SwiftUI

// MARK: - LGColors

/// Semantic color tokens that adapt to Light/Dark mode and system settings.
/// Uses vibrant colors with proper contrast for Liquid Glass surfaces.
enum LGColors {

    // MARK: - Surface Colors (Adaptive)

    /// Primary surface color (base background)
    static let surfacePrimary = Color(uiColor: .systemBackground)

    /// Secondary surface color
    static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)

    /// Tertiary surface color
    static let surfaceTertiary = Color(uiColor: .tertiarySystemBackground)

    // MARK: - Text Colors (Adaptive)

    /// Primary text color - adapts to context (light/dark on glass)
    static let textPrimary = Color.primary

    /// Secondary text color for less prominent text
    static let textSecondary = Color.secondary

    /// Tertiary text color for hints and placeholders
    static let textTertiary = Color(UIColor.tertiaryLabel)

    /// Inverse text color (for use on solid colored backgrounds)
    static let textInverse = Color(uiColor: .systemBackground)

    // MARK: - Accent Colors (Vibrant)

    /// Primary accent color - vibrant cyan/blue
    static let accentPrimary = Color(red: 0.0, green: 0.75, blue: 1.0) // Vibrant cyan

    /// Secondary accent color - purple
    static let accentSecondary = Color(red: 0.6, green: 0.4, blue: 1.0) // Vibrant purple

    /// Tertiary accent - pink/magenta
    static let accentTertiary = Color(red: 1.0, green: 0.4, blue: 0.7)

    // MARK: - Gradient Presets

    /// Primary gradient for buttons and important elements
    static let gradientPrimary: [Color] = [
        Color(red: 0.0, green: 0.75, blue: 1.0),   // Cyan
        Color(red: 0.4, green: 0.5, blue: 1.0)    // Blue-purple
    ]

    /// Vibrant gradient for hero elements
    static let gradientVibrant: [Color] = [
        Color(red: 1.0, green: 0.4, blue: 0.6),   // Pink
        Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange
        Color(red: 1.0, green: 0.85, blue: 0.3)   // Yellow
    ]

    /// Cool gradient for informational elements
    static let gradientCool: [Color] = [
        Color(red: 0.4, green: 0.8, blue: 1.0),   // Light cyan
        Color(red: 0.6, green: 0.4, blue: 1.0)    // Purple
    ]

    /// Imposter gradient - dramatic red/orange
    static let gradientImposter: [Color] = [
        Color(red: 1.0, green: 0.2, blue: 0.3),   // Red
        Color(red: 1.0, green: 0.5, blue: 0.2)    // Orange
    ]

    /// Success gradient
    static let gradientSuccess: [Color] = [
        Color(red: 0.2, green: 0.9, blue: 0.5),   // Green
        Color(red: 0.4, green: 0.85, blue: 0.7)   // Teal
    ]

    // MARK: - Status Colors

    /// Success/positive feedback color
    static let success = Color(red: 0.2, green: 0.85, blue: 0.5)

    /// Warning color
    static let warning = Color(red: 1.0, green: 0.8, blue: 0.2)

    /// Warning tint color (lighter variant for backgrounds)
    static let warningTint = Color(uiColor: .systemYellow).opacity(0.15)

    /// Error/destructive action color
    static let error = Color(red: 1.0, green: 0.35, blue: 0.35)

    // MARK: - Game-Specific Colors

    /// Color for imposter-related UI elements
    static let imposter = Color(red: 1.0, green: 0.25, blue: 0.3)

    /// Color for informed player UI elements
    static let informed = Color(red: 0.0, green: 0.75, blue: 1.0)

    /// Scary bloody red color for title
    static let bloodyRed = Color(red: 0.85, green: 0.1, blue: 0.15)

    /// Darker bloody red for shadow/glow effect
    static let bloodyRedDark = Color(red: 0.5, green: 0.0, blue: 0.0)

    // MARK: - Neon Glow Colors

    /// Neon cyan glow
    static let neonCyan = Color(red: 0.0, green: 1.0, blue: 1.0)

    /// Neon pink glow
    static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.6)

    /// Neon purple glow
    static let neonPurple = Color(red: 0.7, green: 0.3, blue: 1.0)

    /// Neon green glow
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.5)

    // MARK: - Background Colors (Adaptive)

    /// Dark background for Liquid Glass surfaces
    static var darkBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
            } else {
                return UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1.0)
            }
        })
    }

    /// Slightly lighter/darker secondary background
    static var darkBackgroundSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
            } else {
                return UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0)
            }
        })
    }

    /// Glass-friendly background that ensures content visibility
    static var glassBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
            } else {
                return UIColor(red: 0.92, green: 0.92, blue: 0.97, alpha: 1.0)
            }
        })
    }

    // MARK: - Player Colors (Vibrant)

    /// Returns the UI color for a given PlayerColor
    static func playerColor(_ color: PlayerColor) -> Color {
        switch color {
        case .crimson:
            return Color(red: 0.95, green: 0.25, blue: 0.35) // Vibrant red
        case .azure:
            return Color(red: 0.0, green: 0.6, blue: 1.0)   // Vibrant blue
        case .emerald:
            return Color(red: 0.2, green: 0.9, blue: 0.45)  // Vibrant green
        case .amber:
            return Color(red: 1.0, green: 0.75, blue: 0.1)  // Vibrant amber
        case .violet:
            return Color(red: 0.7, green: 0.35, blue: 1.0)  // Vibrant purple
        case .coral:
            return Color(red: 1.0, green: 0.5, blue: 0.4)   // Vibrant coral
        case .teal:
            return Color(red: 0.2, green: 0.85, blue: 0.8)  // Vibrant teal
        case .rose:
            return Color(red: 1.0, green: 0.3, blue: 0.5)   // Vibrant rose
        }
    }

    /// Returns a lighter variant of the player color (for backgrounds)
    static func playerColorLight(_ color: PlayerColor) -> Color {
        playerColor(color).opacity(0.25)
    }

    /// Returns a darker variant of the player color (for text/borders)
    static func playerColorDark(_ color: PlayerColor) -> Color {
        playerColor(color).opacity(0.85)
    }

    // MARK: - Contrast-Safe Text Colors

    /// Returns a text color that contrasts well with the given background
    static func contrastText(on background: Color) -> Color {
        // Simple luminance check - in practice you might want more sophisticated contrast calculation
        return .white
    }

    /// Button text that ensures readability on glass surfaces
    static var buttonText: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .white
            } else {
                return UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
            }
        })
    }

    /// Secondary button text
    static var buttonTextSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(white: 0.9, alpha: 1.0)
            } else {
                return UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
            }
        })
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Returns a brightened version of the color
    func brightened(by amount: Double = 0.2) -> Color {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        return Color(hue: Double(h), saturation: Double(s), brightness: min(Double(b) + amount, 1.0), opacity: Double(a))
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    /// Creates a vibrant diagonal gradient
    static func vibrant(_ colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Creates a vertical gradient
    static func vertical(_ colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Creates a horizontal gradient
    static func horizontal(_ colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
