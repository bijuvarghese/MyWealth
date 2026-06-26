import SwiftUI

public struct MetricRow<Trailing: View>: View {
    private let title: String
    private let value: String
    private let subtitle: String?
    private let tint: Color
    private let trailing: Trailing

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        tint: Color = DesignTokens.ColorToken.brandPrimary,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.tint = tint
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.standard) {
            Circle()
                .fill(tint)
                .frame(width: DesignTokens.Icon.statusSize, height: DesignTokens.Icon.statusSize)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.inlineXS) {
                Text(title)
                    .font(DesignTokens.Typography.subheadlineSemibold)
                    .foregroundStyle(DesignTokens.ColorToken.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.textSecondary)
                }
            }

            Spacer(minLength: DesignTokens.Spacing.standard)

            Text(value)
                .font(DesignTokens.Typography.subheadlineMonospacedDigit)
                .foregroundStyle(DesignTokens.ColorToken.textPrimary)

            trailing
        }
    }
}

public extension MetricRow where Trailing == EmptyView {
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        tint: Color = DesignTokens.ColorToken.brandPrimary
    ) {
        self.init(title: title, value: value, subtitle: subtitle, tint: tint) {
            EmptyView()
        }
    }
}
