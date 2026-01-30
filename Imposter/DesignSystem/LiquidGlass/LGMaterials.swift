//
//  LGMaterials.swift
//  Imposter
//
//  Material effects, shadows, and elevation for Liquid Glass design.
//

import SwiftUI

// MARK: - LGMaterials

/// Material effects and shadow definitions for depth hierarchy.
enum LGMaterials {

    // MARK: - Elevation Levels

    /// Lowest elevation - subtle depth
    static let elevation1: CGFloat = 1

    /// Medium elevation - cards and panels
    static let elevation2: CGFloat = 3

    /// Highest elevation - modals and popovers
    static let elevation3: CGFloat = 5

    // MARK: - Shadow Properties

    /// Returns shadow properties for a given elevation level
    static func shadow(for elevation: CGFloat) -> ShadowProperties {
        switch elevation {
        case elevation3:
            return ShadowProperties(
                color: .black.opacity(0.2),
                radius: 20,
                x: 0,
                y: 8
            )
        case elevation2:
            return ShadowProperties(
                color: .black.opacity(0.15),
                radius: 12,
                x: 0,
                y: 5
            )
        default:
            return ShadowProperties(
                color: .black.opacity(0.1),
                radius: 6,
                x: 0,
                y: 3
            )
        }
    }

    // MARK: - Glass Tint Colors

    /// Tint color for success states
    static let successTint = Color.green.opacity(0.1)

    /// Tint color for error states
    static let errorTint = Color.red.opacity(0.1)

    /// Tint color for warning states
    static let warningTint = Color.yellow.opacity(0.1)

    /// Tint color for info states
    static let infoTint = Color.blue.opacity(0.1)
}

// MARK: - Shadow Properties

/// Encapsulates shadow parameters
struct ShadowProperties: Sendable {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifier for Shadows

extension View {
    /// Applies shadow based on elevation level
    func lgShadow(_ elevation: CGFloat = LGMaterials.elevation1) -> some View {
        let props = LGMaterials.shadow(for: elevation)
        return self.shadow(
            color: props.color,
            radius: props.radius,
            x: props.x,
            y: props.y
        )
    }
}

// MARK: - Animation Constants

extension LGMaterials {
    /// Standard spring animation for Liquid Glass interactions
    static let springAnimation = Animation.spring(
        response: 0.4,
        dampingFraction: 0.7,
        blendDuration: 0
    )

    /// Bouncy spring animation for playful interactions
    static let bouncyAnimation = Animation.spring(
        response: 0.5,
        dampingFraction: 0.6,
        blendDuration: 0
    )

    /// Quick animation for micro-interactions
    static let quickAnimation = Animation.easeInOut(duration: 0.2)

    /// Slow animation for dramatic reveals
    static let slowAnimation = Animation.easeInOut(duration: 0.5)
}
