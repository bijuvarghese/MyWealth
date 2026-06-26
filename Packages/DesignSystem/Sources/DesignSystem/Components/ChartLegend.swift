import SwiftUI

public struct ChartLegend: View {
    private let title: String
    private let color: Color

    public init(_ title: String, color: Color) {
        self.title = title
        self.color = color
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.inlineS) {
            Circle()
                .fill(color)
                .frame(width: DesignTokens.Icon.statusSize, height: DesignTokens.Icon.statusSize)

            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.textSecondary)
        }
    }
}
