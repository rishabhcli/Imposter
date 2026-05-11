# Liquid Glass Reference Code

## LGCard Component

```swift
import SwiftUI

struct LGCard<Content: View>: View {
    let content: Content
    let shape: RoundedRectangle

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        self.content = content()
    }

    var body: some View {
        content
            .padding(.all, 16)
            .background {
                shape.fill(.clear)
                     .glassEffect(.regular, in: shape)
            }
            .overlay {
                shape.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}
```

## LGButton Component

```swift
struct LGButton: View {
    enum Style { case primary, secondary, tertiary }
    let title: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.bold())
                .foregroundStyle(foregroundStyle)
                .frame(minWidth: 100)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(backgroundView)
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private var backgroundView: some View {
        let shape = RoundedRectangle(cornerRadius: 20)
        switch style {
        case .primary:
            shape.fill(Color.accentColor)
                 .glassEffect(.regular.tint(Color.accentColor), in: shape)
        case .secondary:
            shape.fill(Color.white.opacity(0.2))
                 .glassEffect(.regular, in: shape)
        case .tertiary:
            Color.clear
        }
    }

    private var foregroundStyle: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .primary
        case .tertiary: return .accentColor
        }
    }
}
```

## Color Tokens

```swift
enum LGColors {
    // Surfaces
    static let surfacePrimary   = Color(uiColor: .systemBackground)
    static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    static let surfaceTertiary  = Color(uiColor: .tertiarySystemBackground)

    // Text
    static let textPrimary   = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary  = Color(UIColor.tertiaryLabel)

    // Accents
    static let accentPrimary   = Color(uiColor: .systemBlue)
    static let accentSecondary = Color(uiColor: .systemBlue).opacity(0.7)

    // Status
    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemYellow)
    static let error   = Color(uiColor: .systemRed)
}
```

## Typography Scale

```swift
enum LGTypography {
    // Display
    static let displayLarge  = Font.system(size: 40, weight: .bold)
    static let displayMedium = Font.system(size: 34, weight: .bold)
    static let displaySmall  = Font.system(size: 28, weight: .bold)

    // Headlines
    static let headlineLarge  = Font.title.bold()
    static let headlineMedium = Font.title2.bold()
    static let headlineSmall  = Font.title3.bold()

    // Body
    static let bodyLarge  = Font.body
    static let bodyMedium = Font.subheadline
    static let bodySmall  = Font.footnote

    // Labels
    static let labelLarge  = Font.body.bold()
    static let labelMedium = Font.subheadline
    static let labelSmall  = Font.caption
}
```

## Spacing Constants

```swift
enum LGSpacing {
    static let small: CGFloat      = 8
    static let medium: CGFloat     = 16
    static let large: CGFloat      = 24
    static let extraLarge: CGFloat = 32
}
```

## Materials & Shadows

```swift
enum LGMaterials {
    static let elevation1: CGFloat = 1
    static let elevation2: CGFloat = 3
    static let elevation3: CGFloat = 5

    static func shadow(elevation: CGFloat) -> (color: Color, radius: CGFloat, y: CGFloat) {
        switch elevation {
        case elevation3: return (.black.opacity(0.2), 20, 8)
        case elevation2: return (.black.opacity(0.15), 12, 5)
        default:         return (.black.opacity(0.1), 6, 3)
        }
    }
}
```

## View Modifier for Glass Background

```swift
extension View {
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background {
                shape.fill(.clear).glassEffect(.regular, in: shape)
            }
            .clipShape(shape)
    }
}
```
