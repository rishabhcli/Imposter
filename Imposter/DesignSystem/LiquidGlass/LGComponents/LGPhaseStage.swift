//
//  LGPhaseStage.swift
//  Imposter
//
//  Shared gameplay phase shell for consistent Liquid Glass staging.
//

import SwiftUI

// MARK: - LGPhaseStage

/// A reusable shell for gameplay phase screens.
struct LGPhaseStage<Content: View, Footer: View>: View {
    let phase: String
    let title: String
    let subtitle: String?
    let icon: String
    let style: AnimatedBackground.BackgroundStyle
    let accentColor: Color
    let content: Content
    let footer: Footer
    let showsFooter: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(
        phase: String,
        title: String,
        subtitle: String? = nil,
        icon: String,
        style: AnimatedBackground.BackgroundStyle = .gameplay,
        accentColor: Color = LGColors.accentPrimary,
        showsFooter: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.phase = phase
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.accentColor = accentColor
        self.content = content()
        self.footer = footer()
        self.showsFooter = showsFooter
    }

    var body: some View {
        ZStack {
            AnimatedBackground(style: style)

            ScrollView {
                VStack(spacing: LGSpacing.extraLarge) {
                    header
                    content
                }
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LGSpacing.large)
                .padding(.top, LGSpacing.extraLarge)
                .padding(.bottom, LGSpacing.huge)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsFooter {
                footerBar
            }
        }
    }

    private var header: some View {
        VStack(spacing: LGSpacing.medium) {
            iconShell

            VStack(spacing: LGSpacing.small) {
                Text(phase.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(LGTypography.displaySmall)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)

                if let subtitle {
                    Text(subtitle)
                        .font(LGTypography.bodyMedium)
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, LGSpacing.medium)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var iconShell: some View {
        ZStack {
            if reduceTransparency {
                Circle()
                    .fill(accentColor.opacity(0.28))
            } else {
                Circle()
                    .fill(.clear)
                    .glassEffect(.regular.tint(accentColor.opacity(0.28)), in: .circle)
            }

            Image(systemName: icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 76, height: 76)
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .lgShadow(LGMaterials.elevation2)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var footerBar: some View {
        footer
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LGSpacing.large)
            .padding(.top, LGSpacing.medium)
            .padding(.bottom, LGSpacing.medium)
            .background {
                if reduceTransparency {
                    Rectangle()
                        .fill(LGColors.darkBackground.opacity(0.96))
                } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(.white.opacity(0.14))
                                .frame(height: 1)
                        }
                }
            }
    }

    private var headerAccessibilityLabel: String {
        if let subtitle {
            return "\(phase). \(title). \(subtitle)"
        }
        return "\(phase). \(title)"
    }
}

extension LGPhaseStage where Footer == EmptyView {
    init(
        phase: String,
        title: String,
        subtitle: String? = nil,
        icon: String,
        style: AnimatedBackground.BackgroundStyle = .gameplay,
        accentColor: Color = LGColors.accentPrimary,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            phase: phase,
            title: title,
            subtitle: subtitle,
            icon: icon,
            style: style,
            accentColor: accentColor,
            showsFooter: false,
            content: content,
            footer: { EmptyView() }
        )
    }
}
