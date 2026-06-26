import SwiftUI

public struct StatusBadgeStyle: Sendable {
    public let foreground: Color
    public let background: Color
    public let border: Color
    public let borderWidth: CGFloat
    public let font: Font

    public init(
        foreground: Color,
        background: Color,
        border: Color,
        borderWidth: CGFloat = 1,
        font: Font = DesignTokens.Typography.footnote.weight(.semibold)
    ) {
        self.foreground = foreground
        self.background = background
        self.border = border
        self.borderWidth = borderWidth
        self.font = font
    }
}

public extension StatusBadgeStyle {
    static let accent = StatusBadgeStyle(
        foreground: DesignTokens.ColorToken.brandPrimary,
        background: DesignTokens.ColorToken.brandPrimary.opacity(0.15),
        border: DesignTokens.ColorToken.brandPrimary.opacity(0.25)
    )

    static let success = StatusBadgeStyle(
        foreground: DesignTokens.ColorToken.success,
        background: DesignTokens.ColorToken.success.opacity(0.15),
        border: DesignTokens.ColorToken.success.opacity(0.25)
    )

    static let warning = StatusBadgeStyle(
        foreground: DesignTokens.ColorToken.warning,
        background: DesignTokens.ColorToken.warning.opacity(0.15),
        border: DesignTokens.ColorToken.warning.opacity(0.25)
    )

    static let danger = StatusBadgeStyle(
        foreground: DesignTokens.ColorToken.danger,
        background: DesignTokens.ColorToken.danger.opacity(0.15),
        border: DesignTokens.ColorToken.danger.opacity(0.25)
    )
}

public struct StatusBadge: View {
    private let title: String
    private let style: StatusBadgeStyle

    public init(
        _ title: String,
        style: StatusBadgeStyle = .accent
    ) {
        self.title = title
        self.style = style
    }

    public var body: some View {
        Text(title)
            .font(style.font)
            .foregroundStyle(style.foreground)
            .lineLimit(1)
            .padding(.horizontal, DesignTokens.Spacing.pillHorizontalPadding)
            .padding(.vertical, DesignTokens.Spacing.pillVerticalPadding)
            .background(
                Capsule(style: .continuous)
                    .fill(style.background)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(style.border, lineWidth: style.borderWidth)
            )
    }
}
