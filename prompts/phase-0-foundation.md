# Phase 0: Foundation – Agent Prompt

## Objective
Set up the Xcode project, configure build settings, and complete initial research on iOS 26 APIs.

## Context
- Read `CLAUDE.md` for project overview and tech stack
- This phase establishes the development environment before any feature work

## Tasks

### 1. Xcode Project Setup
- [ ] Verify existing project targets iOS 26.0
- [ ] Configure Swift 6 language version in build settings
- [ ] Enable strict concurrency checking (complete)
- [ ] Add ImagePlayground.framework to Frameworks & Libraries
- [ ] Disable Bitcode (deprecated)

### 2. Folder Structure
Create the following directories in `Imposter/`:
```
App/
Domain/Models/
Domain/Actions/
Domain/Logic/
Store/
Features/Home/
Features/Setup/
Features/RoleReveal/
Features/ClueRound/
Features/Voting/
Features/Reveal/
Features/Summary/
DesignSystem/LiquidGlass/
DesignSystem/LiquidGlass/LGComponents/
DesignSystem/Extensions/
Resources/WordPacks/
Utilities/
```

### 3. Research Documentation
Document findings in `.claude/skills/` for:
- Liquid Glass `.glassEffect` API usage
- `@Observable` macro behavior in iOS 26
- `ImagePlayground` framework capabilities
- Swift 6 `Sendable` requirements

### 4. Git Setup
- [ ] Verify `.gitignore` includes Xcode artifacts
- [ ] Initial commit with project structure

## Acceptance Criteria
- [ ] Project builds for iOS 26 simulator without errors
- [ ] Folder structure matches architecture diagram in `CLAUDE.md`
- [ ] All research notes documented in skills files

## Next Phase
After completion, proceed to **Phase 1: Domain Layer** to implement core models and reducer.

---

## Ralph Loop Checklist
- [ ] Read requirements above
- [ ] Analyze current project state
- [ ] Implement changes
- [ ] Verify build succeeds
- [ ] Update `TASKS.md` with completed items
