# Phase 9: Release – Agent Prompt

## Objective
Prepare App Store assets and submit the app for review.

## Context
- Reference `Implementation Plan.md` Section 12

## Tasks

### 1. App Icon

- Design 1024x1024 icon
- Theme: glassy question mark (Liquid Glass style)
- Add to Assets.xcassets/AppIcon

### 2. Launch Screen

- Simple launch screen with app title
- Or LaunchScreen.storyboard with gradient background
- Match home screen aesthetic

### 3. Screenshots

Capture for all required device sizes:
- iPhone 16 Pro Max (6.9")
- iPhone 16 Pro (6.3")
- iPad Pro 13" (if supporting iPad)

Screenshot ideas:
1. Home screen with gradient
2. Player setup with names
3. Role reveal (informed player)
4. Clue round in progress
5. Voting screen
6. Summary with winner

Tips:
- Use clean test data
- Show the Liquid Glass design
- Highlight AI-generated image feature

### 4. App Store Metadata

**App Name**: Imposter

**Subtitle**: Party Game for Friends

**Category**: Games > Party

**Age Rating**: 4+

**Description**:
```
Imposter is a fun social deduction party game for 3-10 players!

One player is secretly the "Imposter" and doesn't know the secret word. Everyone gives clues, and the group votes to find the Imposter. Can you blend in, or will you be caught?

Features:
• Beautiful Liquid Glass design for iOS 26
• Pass-and-play local multiplayer
• AI-generated images for custom words
• Multiple word categories and difficulties
• Supports 3-10 players
• No internet required - fully offline

Perfect for parties, family game nights, or hanging out with friends!
```

**Keywords**: party game, social deduction, multiplayer, imposter, word game, family game, local multiplayer

**Privacy Policy URL**: (if required)

### 5. App Privacy

**Data Collection**: None

The app:
- Does not collect any data
- Does not transmit any data
- Uses on-device AI only
- No analytics or tracking

### 6. Build Preparation

- [ ] Remove all debug logging
- [ ] Verify no placeholder text
- [ ] Verify all assets included
- [ ] Test Release build on device
- [ ] Increment version/build number

### 7. Archive & Upload

```bash
# Archive in Xcode
Product → Archive

# Upload to App Store Connect
Distribute App → App Store Connect
```

### 8. TestFlight

- [ ] Upload build to TestFlight
- [ ] Internal testing
- [ ] External testing (optional)
- [ ] Address any feedback

### 9. App Store Review

- [ ] Submit for review
- [ ] Monitor review status
- [ ] Respond to any issues
- [ ] Celebrate approval! 🎉

## Acceptance Criteria
- [ ] App icon displays correctly
- [ ] Launch screen appears
- [ ] All screenshots captured
- [ ] App Store metadata complete
- [ ] Privacy disclosure accurate
- [ ] TestFlight build works
- [ ] App submitted for review
- [ ] App approved and live

## Post-Launch

- Monitor crash reports
- Respond to user reviews
- Plan future updates
- Consider additional languages/features

---

## Ralph Loop Checklist
- [ ] Create app icon
- [ ] Set up launch screen
- [ ] Capture screenshots
- [ ] Write App Store description
- [ ] Complete privacy disclosure
- [ ] Archive Release build
- [ ] Upload to TestFlight
- [ ] Test thoroughly
- [ ] Submit for review
- [ ] Update `TASKS.md` - DONE! 🎉
