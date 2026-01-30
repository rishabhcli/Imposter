//
//  LGTextField.swift
//  Imposter
//
//  Liquid Glass styled text field components and modifiers.
//

import SwiftUI

// MARK: - Liquid Glass TextField Style

/// A custom TextFieldStyle that applies Liquid Glass appearance
struct LGTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, LGSpacing.medium)
            .padding(.vertical, LGSpacing.small + 4)
            .glassEffect(
                .regular.interactive(),
                in: .rect(cornerRadius: LGSpacing.cornerRadiusSmall, style: .continuous)
            )
    }
}

extension TextFieldStyle where Self == LGTextFieldStyle {
    /// Liquid Glass text field style
    static var liquidGlass: LGTextFieldStyle { LGTextFieldStyle() }
}

// MARK: - LGTextField

/// A text field with Liquid Glass styling and optional icon
struct LGTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    var isFocused: FocusState<Bool>.Binding?

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isFocused = nil
    }

    init(_ placeholder: String, text: Binding<String>, icon: String? = nil, isFocused: FocusState<Bool>.Binding) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isFocused = isFocused
    }

    var body: some View {
        HStack(spacing: LGSpacing.small) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.body)
            }

            textField
        }
        .padding(.horizontal, LGSpacing.medium)
        .padding(.vertical, LGSpacing.small + 4)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: LGSpacing.cornerRadiusSmall, style: .continuous)
        )
    }

    @ViewBuilder
    private var textField: some View {
        if let isFocused = isFocused {
            TextField(placeholder, text: $text)
                .font(LGTypography.bodyMedium)
                .focused(isFocused)
        } else {
            TextField(placeholder, text: $text)
                .font(LGTypography.bodyMedium)
        }
    }
}

// MARK: - LGTextEditor

/// A multi-line text editor with Liquid Glass styling
struct LGTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat

    init(_ placeholder: String, text: Binding<String>, minHeight: CGFloat = 100) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(LGTypography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, LGSpacing.small)
                    .padding(.vertical, LGSpacing.small)
            }

            TextEditor(text: $text)
                .font(LGTypography.bodyMedium)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(LGSpacing.small)
        .glassEffect(
            .regular.interactive(),
            in: .rect(cornerRadius: LGSpacing.cornerRadiusSmall, style: .continuous)
        )
    }
}

// MARK: - Preview

#Preview("LGTextField") {
    ZStack {
        LGColors.darkBackground
            .ignoresSafeArea()

        VStack(spacing: LGSpacing.large) {
            LGTextField("Enter your name...", text: .constant(""))

            LGTextField("Search...", text: .constant("Hello"), icon: "magnifyingglass")

            LGTextEditor("Enter a description...", text: .constant(""))
        }
        .padding()
    }
}
