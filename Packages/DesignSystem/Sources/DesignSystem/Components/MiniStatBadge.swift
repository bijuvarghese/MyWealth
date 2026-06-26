import SwiftUI

public struct MiniStatBadge: View {
    private let title: String
    private let value: String
    private let tint: Color

    public init(
        title: String,
        value: String,
        tint: Color = DesignTokens.ColorToken.brandPrimary
    ) {
        self.title = title
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.inlineXS) {
            Text(title)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.ColorToken.textSecondary)

            Text(value)
                .font(DesignTokens.Typography.captionMonospacedDigit.weight(.semibold))
                .foregroundStyle(tint)
        }
        .padding(.horizontal, DesignTokens.Spacing.compact)
        .padding(.vertical, DesignTokens.Spacing.inlineS)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: DesignTokens.Shape.compactRadius, style: .continuous))
    }
}
