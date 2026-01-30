//
//  LGSpacing.swift
//  Imposter
//
//  Spacing constants for consistent layout throughout the app.
//

import SwiftUI

// MARK: - LGSpacing

/// Spacing constants for consistent margins, padding, and gaps.
enum LGSpacing {
    /// Extra small spacing (4pt)
    static let extraSmall: CGFloat = 4

    /// Small spacing (8pt) - for tight layouts
    static let small: CGFloat = 8

    /// Medium spacing (16pt) - default padding
    static let medium: CGFloat = 16

    /// Large spacing (24pt) - section spacing
    static let large: CGFloat = 24

    /// Extra large spacing (32pt) - major sections
    static let extraLarge: CGFloat = 32

    /// Huge spacing (48pt) - screen padding
    static let huge: CGFloat = 48
}

// MARK: - Corner Radius

extension LGSpacing {
    /// Small corner radius for buttons
    static let cornerRadiusSmall: CGFloat = 12

    /// Medium corner radius for cards
    static let cornerRadiusMedium: CGFloat = 20

    /// Large corner radius for sheets/modals
    static let cornerRadiusLarge: CGFloat = 28
}

// MARK: - Touch Targets

extension LGSpacing {
    /// Minimum touch target size (44pt per HIG)
    static let minTouchTarget: CGFloat = 44

    /// Standard button height
    static let buttonHeight: CGFloat = 50

    /// Large button height (for primary actions)
    static let buttonHeightLarge: CGFloat = 56
}
