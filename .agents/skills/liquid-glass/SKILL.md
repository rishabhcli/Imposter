# Liquid Glass Design Skill

## When to Load
Load this skill when:
- Implementing any UI component with glass effects
- Creating or modifying `LGCard`, `LGButton`, or other design system components
- Applying `.glassEffect` modifier
- Working with translucent materials and depth

## Key Concepts

### Glass Effect Variants
```swift
.glassEffect(.regular, in: shape)    // Default translucent glass
.glassEffect(.clear, in: shape)      // Less opaque, for busy backgrounds
.glassEffect(.identity, in: shape)   // No effect (transparent)
```

### Tinting and Interactivity
```swift
.glassEffect(.regular.tint(color), in: shape)  // Colored glass
.glassEffect(.regular.interactive(), in: shape) // Adds touch effects
```

### Built-in Button Styles
```swift
.buttonStyle(.glass)          // Translucent secondary button
.buttonStyle(.glassProminent) // Opaque primary button
```

### GlassEffectContainer
Wrap multiple glass elements for optimized rendering and morphing transitions:
```swift
GlassEffectContainer {
    // Multiple glass views here
}
```

## Design Principles

1. **Semantic Colors**: Use `.primary`, `.secondary`, system colors
2. **Adaptive**: Glass auto-adjusts for Light/Dark mode
3. **Reduce Transparency**: Falls back to solid when accessibility setting enabled
4. **Soft Shadows**: Use subtle shadows (glass provides inherent depth)
5. **Large Corners**: Use 20-28pt corner radius for panels

## Critical Research Notes (Section 14 & Appendix A)

### Color System
- Glass components auto-adapt based on environment
- Text on glass uses "vibrant" versions of semantic colors
- Always use `.label`, `.systemBackground` etc. for automatic contrast
- Player colors should be bright and distinct for visibility on glass

### Typography on Glass
- Use **bolder text** for legibility on translucent backgrounds
- SF typeface can dynamically adjust weight/width
- Default SwiftUI Dynamic Type styles respond automatically

### Depth & Elevation
- Glass provides inherent depth via blur and specular highlights
- Keep shadows subtle (radius 6-20, opacity 0.1-0.2)
- 3 elevation levels: 1 (cards), 2 (modals), 3 (alerts)

### Corner Radius Conventions
- 12pt: Small elements (badges, chips)
- 20pt: Cards and panels
- 28-34pt: Full-screen sheets (match device corners)
- Use `.containerConcentric` for nested containers

### Animation
- Use `.spring()` with low damping for bouncy effects
- iOS 26 has `.bouncy` shorthand curve
- `.interactive()` adds built-in touch ripple effects
- Specular highlights move with device tilt (automatic)

### Touch Targets
- Minimum 44x44pt for all interactive elements
- Color picker circles need larger hit area (wrap in 44pt frame)

## Reference Implementation

See `reference.md` in this folder for copy-paste code patterns.
