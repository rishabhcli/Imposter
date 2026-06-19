//
//  SoftFadedImageEdges.swift
//  Imposter
//
//  A reusable modifier that gives an image rounded, blurred edges that fade
//  smoothly into whatever sits behind it (e.g. a liquid-glass card).
//

import SwiftUI

// MARK: - SoftFadedImageEdges

/// Masks content with an inset, blurred rounded rectangle. Blurring the mask
/// converts its crisp rounded edge into a gradual alpha falloff, so the content
/// dissolves into the background instead of ending on a hard line.
///
/// The mask is inset and the blur radius reserves room inside the bounds for the
/// falloff, guaranteeing the edges reach full transparency before the frame edge
/// (so the fade is never clipped).
struct SoftFadedImageEdges: ViewModifier {
    /// Corner radius of the opaque core, before blurring softens it.
    var cornerRadius: CGFloat = 28
    /// How far the opaque core is inset from the bounds. Larger values leave a
    /// wider transparent margin for the fade.
    var inset: CGFloat = 12
    /// Blur radius applied to the mask. Larger values produce a softer, more
    /// gradual fade.
    var softness: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .mask {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: inset)
                    .fill(Color.black)
                    .blur(radius: softness)
            }
    }
}

extension View {
    /// Gives the view rounded, blurred edges that fade smoothly into the
    /// background. Ideal for AI-generated artwork resting on a glass card.
    /// - Parameters:
    ///   - cornerRadius: Corner radius of the opaque core before blurring.
    ///   - inset: Transparent margin reserved for the fade.
    ///   - softness: Blur radius of the mask; higher means a more gradual fade.
    func softFadedImageEdges(
        cornerRadius: CGFloat = 28,
        inset: CGFloat = 12,
        softness: CGFloat = 22
    ) -> some View {
        modifier(
            SoftFadedImageEdges(
                cornerRadius: cornerRadius,
                inset: inset,
                softness: softness
            )
        )
    }
}
