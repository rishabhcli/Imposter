# Phase 2: Design System – Agent Prompt

## Objective
Implement the Liquid Glass design system with colors, typography, spacing, materials, and reusable components.

## Context
- Read `CLAUDE.md` for design requirements
- Load `.claude/skills/liquid-glass/` for Liquid Glass patterns
- Reference `Implementation Plan.md` Section 5 for specifications

## Tasks

### 1. Color System (`DesignSystem/LiquidGlass/LGColors.swift`)

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
    static let textInverse   = Color(uiColor: .systemBackground)
    
    // Accents
    static let accentPrimary   = Color(uiColor: .systemBlue)
    static let accentSecondary = Color(uiColor: .systemBlue).opacity(0.7)
    
    // Status
    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemYellow)
    static let error   = Color(uiColor: .systemRed)
    
    // Player colors
    static func playerColor(_ color: PlayerColor) -> Color { ... }
}
```

### 2. Typography (`DesignSystem/LiquidGlass/LGTypography.swift`)

Define font constants using SwiftUI Font styles that scale with Dynamic Type:
- Display: large (40pt), medium (34pt), small (28pt)
- Headline: large, medium, small (using .title variants)
- Body: large, medium, small
- Label: large, medium, small

### 3. Spacing (`DesignSystem/LiquidGlass/LGSpacing.swift`)

```swift
enum LGSpacing {
    static let small: CGFloat      = 8
    static let medium: CGFloat     = 16
    static let large: CGFloat      = 24
    static let extraLarge: CGFloat = 32
}
```

### 4. Materials (`DesignSystem/LiquidGlass/LGMaterials.swift`)

- Elevation constants (1, 2, 3)
- Shadow function returning color, radius, y-offset
- Corner radius constants

### 5. Components (`DesignSystem/LiquidGlass/LGComponents/`)

#### LGCard.swift
- Generic container with `.glassEffect(.regular, in: shape)`
- Configurable corner radius
- Subtle border stroke
- Shadow based on elevation

#### LGButton.swift
- Three styles: primary, secondary, tertiary
- Primary: tinted glass with accent color
- Secondary: clear glass
- Tertiary: text only
- All with appropriate foreground colors

#### LGBadge.swift (optional)
- Small badge for winner/status indicators

### 6. Extensions (`DesignSystem/Extensions/`)

#### View+Extensions.swift
```swift
extension View {
    func glassBackground(cornerRadius: CGFloat = 20) -> some View { ... }
}
```

## Acceptance Criteria
- [ ] All color tokens defined and tested in Light/Dark mode
- [ ] Typography scales correctly with Dynamic Type
- [ ] LGCard renders with visible glass effect
- [ ] LGButton works in all three styles
- [ ] Components handle Reduce Transparency gracefully

## Testing Focus
- Create SwiftUI Previews for each component
- Preview in Light and Dark mode
- Preview at different Dynamic Type sizes
- Verify glass effect visibility

## Next Phase
After completion, proceed to **Phase 3: Core Flow**.

---

## Ralph Loop Checklist
- [ ] Read skill: `.claude/skills/liquid-glass/`
- [ ] Implement color tokens
- [ ] Implement typography
- [ ] Build LGCard component
- [ ] Build LGButton component
- [ ] Create previews for all
- [ ] Test Light/Dark modes
- [ ] Update `TASKS.md`
