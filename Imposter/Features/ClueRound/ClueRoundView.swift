//
//  ClueRoundView.swift
//  Imposter
//
//  Discussion phase view - players discuss and try to identify the imposter.
//

import SwiftUI

// MARK: - ClueRoundView

/// Simple discussion view - shows first player and slide-to-end control
struct ClueRoundView: View {
    @Environment(GameStore.self) private var store
    @State private var currentPlayerScale: CGFloat = 1.0
    @State private var motionManager = MotionManager.shared
    
    var body: some View {
        ZStack {
            // Background
            AnimatedBackground(style: .gameplay)
            
            VStack(spacing: LGSpacing.extraLarge) {
                Spacer()
                
                // Header
                headerSection
                
                // First player indicator
                firstPlayerSection
                
                // Instructions
                instructionsSection
                
                Spacer()
                
                // Slide to end control
                SlideToEndControl {
                    HapticManager.roundCompleted()
                    store.dispatch(.completeVoting)
                }
                .padding(.horizontal, LGSpacing.large)
                .padding(.bottom, LGSpacing.extraLarge)
            }
            .padding(LGSpacing.large)
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: LGSpacing.small) {
            Text("DISCUSS")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Find the Imposter")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
    
    private var firstPlayerSection: some View {
        VStack(spacing: LGSpacing.medium) {
            if let firstPlayer = store.currentClueGiver {
                // "Goes first" label
                Text("GOES FIRST")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(LGColors.accentPrimary)
                    .padding(.horizontal, LGSpacing.medium)
                    .padding(.vertical, LGSpacing.extraSmall)
                    .background {
                        Capsule()
                            .fill(.clear)
                            .glassEffect(
                                .regular.tint(LGColors.accentPrimary.opacity(0.3)),
                                in: .capsule
                            )
                    }
                
                // Player avatar with gyro effects
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    LGColors.playerColor(firstPlayer.color).opacity(0.4),
                                    LGColors.playerColor(firstPlayer.color).opacity(0.1),
                                    Color.clear
                                ],
                                center: UnitPoint(
                                    x: 0.5 + motionManager.roll * 0.3,
                                    y: 0.5 + motionManager.pitch * 0.3
                                ),
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                    
                    // Pulse ring
                    Circle()
                        .stroke(LGColors.playerColor(firstPlayer.color).opacity(0.3), lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .scaleEffect(currentPlayerScale)
                    
                    // Avatar glass
                    Circle()
                        .fill(.clear)
                        .glassEffect(
                            .regular.tint(LGColors.playerColor(firstPlayer.color).opacity(0.4)),
                            in: .circle
                        )
                        .frame(width: 120, height: 120)
                    
                    // Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear
                                ],
                                center: UnitPoint(
                                    x: 0.3 + motionManager.roll * 0.4,
                                    y: 0.3 + motionManager.pitch * 0.4
                                ),
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 10)
                    
                    Text(firstPlayer.emoji)
                        .font(.system(size: 70))
                }
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.4)
                                ],
                                startPoint: UnitPoint(x: 0.5 - motionManager.roll * 0.3, y: 0),
                                endPoint: UnitPoint(x: 0.5 + motionManager.roll * 0.3, y: 1)
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                }
                .rotation3DEffect(
                    .degrees(motionManager.pitch * 8),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.4
                )
                .rotation3DEffect(
                    .degrees(-motionManager.roll * 8),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.4
                )
                .shadow(
                    color: LGColors.playerColor(firstPlayer.color).opacity(0.5),
                    radius: 25,
                    x: CGFloat(motionManager.roll * 10),
                    y: CGFloat(motionManager.pitch * 8) + 10
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        currentPlayerScale = 1.15
                    }
                }
                
                // Player name
                Text(firstPlayer.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
    
    private var instructionsSection: some View {
        VStack(spacing: LGSpacing.medium) {
            // Category hint
            HStack(spacing: LGSpacing.small) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                Text(displayCategory)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, LGSpacing.medium)
            .padding(.vertical, LGSpacing.small)
            .glassEffect(.regular, in: .capsule)
            
            // Instructions
            Text("Take turns giving one-word clues.\nTry to identify who doesn't know the word!")
                .font(LGTypography.bodyMedium)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayCategory: String {
        if store.settings.wordSource == .customPrompt {
            return store.state.roundState?.imposterHint ?? store.state.roundState?.categoryHint ?? "Custom"
        } else {
            return store.state.roundState?.categoryHint ?? "Mixed"
        }
    }
}

// MARK: - Slide to End Control

/// iOS 26 style slide-to-action control with liquid glass styling
struct SlideToEndControl: View {
    let onComplete: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var hasCompleted = false
    @GestureState private var gestureOffset: CGFloat = 0
    
    private let trackHeight: CGFloat = 64
    private let thumbSize: CGFloat = 52
    private let horizontalPadding: CGFloat = 6
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxOffset = trackWidth - thumbSize - (horizontalPadding * 2)
            let progress = min(dragOffset / maxOffset, 1.0)
            
            ZStack(alignment: .leading) {
                // Track background with glass effect
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)
                    .frame(height: trackHeight)
                
                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                LGColors.imposter.opacity(0.3 * progress),
                                LGColors.imposter.opacity(0.5 * progress)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: thumbSize + dragOffset + horizontalPadding, height: trackHeight)
                    .animation(.none, value: dragOffset)
                
                // Center text
                HStack {
                    Spacer()
                    HStack(spacing: LGSpacing.small) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Slide to End Game")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.5 * (1 - progress)))
                    Spacer()
                }
                
                // Draggable thumb
                Circle()
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(LGColors.imposter.opacity(0.4)),
                        in: .circle
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: LGColors.imposter.opacity(0.5), radius: 10)
                    .offset(x: horizontalPadding + dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !hasCompleted else { return }
                                isDragging = true
                                let newOffset = max(0, min(value.translation.width, maxOffset))
                                dragOffset = newOffset
                                
                                // Haptic feedback at intervals
                                if Int(newOffset) % 50 == 0 {
                                    HapticManager.selectionChanged()
                                }
                            }
                            .onEnded { value in
                                isDragging = false
                                
                                if dragOffset >= maxOffset * 0.85 {
                                    // Complete the action
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = maxOffset
                                    }
                                    hasCompleted = true
                                    HapticManager.imposterCaught()
                                    
                                    // Delay to show completion state
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onComplete()
                                    }
                                } else {
                                    // Spring back
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2), value: isDragging)
            }
        }
        .frame(height: trackHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Slide to end game")
        .accessibilityHint("Swipe right to reveal the imposter")
    }
}

// MARK: - Preview

#Preview {
    ClueRoundView()
        .environment(GameStore.previewInGame)
}
