# Imposter

A local-only social deduction party game for iOS 26+ built with SwiftUI and Liquid Glass design.

## Game Overview

**3-10 players** share one device in pass-and-play mode. One player is secretly the **Imposter** who doesn't know the secret word. Players give clues and vote to identify the Imposter.

## Tech Stack

- **iOS 26.0+** with Swift 6
- **SwiftUI** + Observation framework
- **Liquid Glass** design system
- **ImagePlayground** for AI-generated images
- **Unidirectional data flow** (Redux-like architecture)

---

## Agentic AI Scaffold

This repository is structured for **AI-assisted development**. An AI coding agent can autonomously implement features phase-by-phase using the provided planning artifacts.

### Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | **Start here.** Tech stack, architecture, rules, phase roadmap |
| `TASKS.md` | Phase-scoped task tracker with checkboxes |
| `Implementation Plan.md` | Full 2500-line specification document |
| `prompts/phase-*.md` | Phase-specific agent prompts |
| `.claude/skills/*/` | Domain knowledge loaded on-demand |

### Directory Structure

```
Imposter/
├── CLAUDE.md              # Agent instructions (read first!)
├── TASKS.md               # Task tracker
├── Implementation Plan.md # Full specification
├── README.md              # This file
│
├── prompts/               # Phase-specific prompts
│   ├── phase-0-foundation.md
│   ├── phase-1-domain.md
│   ├── phase-2-design-system.md
│   ├── phase-3-core-flow.md
│   ├── phase-4-role-reveal.md
│   ├── phase-5-gameplay.md
│   ├── phase-6-ai.md
│   ├── phase-7-polish.md
│   ├── phase-8-testing.md
│   └── phase-9-release.md
│
├── .claude/skills/        # Domain knowledge
│   ├── liquid-glass/      # Liquid Glass UI patterns
│   ├── swiftui-ios26/     # iOS 26 SwiftUI + @Observable
│   ├── foundation-models/ # ImagePlayground AI integration
│   ├── game-logic/        # Reducer, state machine, scoring
│   └── accessibility/     # VoiceOver, localization, a11y
│
└── Imposter/              # Xcode project source
    ├── App/
    ├── Domain/
    ├── Store/
    ├── Features/
    ├── DesignSystem/
    ├── Resources/
    └── Utilities/
```

### Workflow for AI Agent

1. **Read `CLAUDE.md`** at session start
2. **Check `TASKS.md`** for current phase and pending tasks
3. **Load relevant skill** from `.claude/skills/` when working on that domain
4. **Follow phase prompt** from `prompts/phase-*.md`
5. **Update `TASKS.md`** as tasks complete
6. **Iterate** using the Ralph Loop (Read → Analyze → Implement → Verify → Test)

---

## Implementation Phases

| Phase | Name | Description |
|-------|------|-------------|
| 0 | Foundation | Xcode setup, folder structure, API research |
| 1 | Domain Layer | Models, Actions, Reducer, GameStore |
| 2 | Design System | Liquid Glass colors, typography, components |
| 3 | Core Flow | HomeView, PlayerSetupView, navigation |
| 4 | Role Reveal | Pass-and-play secret role distribution |
| 5 | Gameplay | Clue, Voting, Reveal, Summary screens |
| 6 | AI Integration | ImagePlayground for custom word images |
| 7 | Polish | Persistence, accessibility, localization |
| 8 | Testing | Unit tests, UI tests, performance |
| 9 | Release | App Store assets and submission |

---

## Quick Start (Human Developer)

```bash
# Open in Xcode
open Imposter.xcodeproj

# Build for iOS 26 simulator
xcodebuild -scheme Imposter -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run tests
xcodebuild test -scheme Imposter -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

---

## Features

- 🎮 **Local Multiplayer**: 3-10 players, one device
- 🪟 **Liquid Glass UI**: Beautiful iOS 26 design
- 🤖 **AI Images**: Generate images for custom words
- 🔒 **Privacy-First**: Fully offline, no data collection
- ♿ **Accessible**: VoiceOver, Dynamic Type, localization
- 🌍 **Multilingual**: EN, ES, FR, DE, JA

---

## License

MIT License - See LICENSE file for details.
