//
//  PlayerRowView.swift
//  Imposter
//
//  Individual player row in the setup list.
//

import SwiftUI

// MARK: - PlayerRowView

/// A row displaying a single player with name editing and color selection
struct PlayerRowView: View {
    @Environment(GameStore.self) private var store
    let player: Player
    var shouldFocus: Bool = false

    @State private var name: String
    @State private var showColorPicker = false
    @FocusState private var isNameFocused: Bool

    init(player: Player, shouldFocus: Bool = false) {
        self.player = player
        self.shouldFocus = shouldFocus
        _name = State(initialValue: player.name)
    }

    var body: some View {
        HStack(spacing: LGSpacing.medium) {
            // Color indicator with emoji (tappable) - LARGER
            colorButton

            // Name field
            nameField

            // Delete button (if more than 3 players)
            if store.players.count > 3 {
                deleteButton
            }
        }
        .padding(.vertical, LGSpacing.small)
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(currentColor: player.color) { newColor in
                updatePlayer(color: newColor)
            }
        }
        .onChange(of: shouldFocus) { _, newValue in
            if newValue {
                isNameFocused = true
            }
        }
        .onAppear {
            if shouldFocus {
                // Small delay to allow view to appear
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(100))
                    isNameFocused = true
                }
            }
        }
    }

    // MARK: - Subviews

    private var colorButton: some View {
        Button {
            showColorPicker = true
        } label: {
            ZStack {
                // Background color circle - LARGER
                Circle()
                    .fill(LGColors.playerColor(player.color))
                    .frame(width: 56, height: 56)

                // Emoji overlay - LARGER
                Text(player.emoji)
                    .font(.system(size: 32))
            }
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Player avatar: \(player.emoji), color: \(player.color.displayName)")
        .accessibilityHint("Double tap to change color")
    }

    private var nameField: some View {
        TextField("Player Name", text: $name)
            .font(LGTypography.headlineMedium)  // LARGER font
            .textFieldStyle(.liquidGlass)
            .focused($isNameFocused)
            .onSubmit {
                updatePlayer(name: name)
            }
            .onChange(of: isNameFocused) { _, focused in
                if !focused && name != player.name {
                    updatePlayer(name: name)
                }
            }
            .accessibilityIdentifier("playerNameField_\(player.id)")
    }

    private var deleteButton: some View {
        Button {
            store.dispatch(.removePlayer(id: player.id))
        } label: {
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(LGColors.error)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(player.name)")
    }

    // MARK: - Actions

    private func updatePlayer(name: String? = nil, color: PlayerColor? = nil) {
        let newName = name ?? player.name
        let newColor = color ?? player.color
        store.dispatch(.updatePlayer(id: player.id, name: newName, color: newColor))
    }
}

// MARK: - Color Picker Sheet

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentColor: PlayerColor
    let onSelect: (PlayerColor) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: LGSpacing.large) {
                Text("Choose a Color")
                    .font(LGTypography.headlineLarge)
                    .padding(.top, LGSpacing.large)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: LGSpacing.large
                ) {
                    ForEach(PlayerColor.allCases, id: \.self) { color in
                        colorOption(color)
                    }
                }
                .padding(LGSpacing.large)

                Spacer()
            }
            .navigationTitle("Player Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func colorOption(_ color: PlayerColor) -> some View {
        Button {
            onSelect(color)
            dismiss()
        } label: {
            VStack(spacing: LGSpacing.small) {
                Circle()
                    .fill(LGColors.playerColor(color))
                    .frame(width: 64, height: 64)
                    .overlay {
                        if color == currentColor {
                            Image(systemName: "checkmark")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                color == currentColor ? Color.white : Color.white.opacity(0.3),
                                lineWidth: color == currentColor ? 3 : 2
                            )
                    }
                    .shadow(color: LGColors.playerColor(color).opacity(0.4), radius: 8)

                Text(color.displayName)
                    .font(LGTypography.labelMedium)
                    .foregroundStyle(color == currentColor ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.displayName)\(color == currentColor ? ", selected" : "")")
    }
}

// MARK: - Preview

#Preview {
    LGCard {
        VStack(spacing: LGSpacing.medium) {
            PlayerRowView(player: Player(name: "Alice", color: .crimson))
            Divider()
            PlayerRowView(player: Player(name: "Bob", color: .azure))
        }
    }
    .padding()
    .background(LGColors.glassBackground)
    .environment(GameStore.preview)
}
