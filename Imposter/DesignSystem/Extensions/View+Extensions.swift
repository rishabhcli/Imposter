//
//  View+Extensions.swift
//  Imposter
//
//  SwiftUI View extensions for the Liquid Glass design system.
//

import SwiftUI

// MARK: - Glass Background Modifier

extension View {
    /// Applies a Liquid Glass background to the view
    /// - Parameters:
    ///   - cornerRadius: The corner radius of the glass effect
    ///   - tint: Optional tint color for the glass
    ///   - interactive: Whether the glass should respond to touch (default: false)
    /// - Returns: A view with glass background applied
    func glassBackground(
        cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return self
            .background {
                shape
                    .fill(.clear)
                    .glassEffect(
                        {
                            var effect = Glass.regular
                            if let tint = tint {
                                effect = effect.tint(tint)
                            }
                            if interactive {
                                effect = effect.interactive()
                            }
                            return effect
                        }(),
                        in: .rect(cornerRadius: cornerRadius, style: .continuous)
                    )
            }
            .clipShape(shape)
    }

    /// Applies a subtle glass border overlay
    func glassBorder(cornerRadius: CGFloat = LGSpacing.cornerRadiusMedium) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self.overlay {
            shape.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally applies one of two modifiers
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
}

// MARK: - Accessibility Extensions

extension View {
    /// Applies standard accessibility modifiers for a button
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint ?? "")
            }
            .accessibilityAddTraits(.isButton)
    }

    /// Applies standard accessibility modifiers for a card
    func accessibleCard(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }

    /// Hides content from VoiceOver (for decorative elements)
    func accessibilityHiddenFromVoiceOver() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Animation Extensions

extension View {
    /// Applies the standard Liquid Glass spring animation
    func lgAnimation() -> some View {
        self.animation(LGMaterials.springAnimation, value: UUID())
    }

    /// Applies a bouncy animation for playful interactions
    func bouncyAnimation() -> some View {
        self.animation(LGMaterials.bouncyAnimation, value: UUID())
    }
}

// MARK: - Frame Extensions

extension View {
    /// Ensures minimum touch target size for accessibility
    func minTouchTarget() -> some View {
        self.frame(minWidth: LGSpacing.minTouchTarget, minHeight: LGSpacing.minTouchTarget)
    }

    /// Centers the view in a full-width container
    func centeredHorizontally() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
}

// MARK: - Loading State

extension View {
    /// Overlays a loading indicator
    func loading(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        }
    }
}

// MARK: - Shake Animation

extension View {
    /// Applies a shake animation (for error states)
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.05).repeatCount(5, autoreverses: true)) {
                        shakeOffset = 10
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(300))
                        shakeOffset = 0
                    }
                }
            }
    }
}

// MARK: - Read Size

extension View {
    /// Reads the size of the view and calls the provided closure
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
