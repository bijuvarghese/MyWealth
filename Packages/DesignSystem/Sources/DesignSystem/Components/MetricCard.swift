import SwiftUI

public struct MetricCard<Accessory: View>: View {
    private let title: String
    private let value: String
    private let subtitle: String?
    private let tint: Color
    private let accessory: Accessory

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        tint: Color = DesignTokens.ColorToken.brandPrimary,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.tint = tint
        self.accessory = accessory()
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
                HStack(spacing: DesignTokens.Spacing.standard) {
                    Text(title)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.textSecondary)

                    Spacer(minLength: DesignTokens.Spacing.standard)
                    accessory
                }

                Text(value)
                    .font(DesignTokens.Typography.amountProminent)
                    .foregroundStyle(tint)
                    .monospacedDigit()

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.textSecondary)
                }
            }
        }
    }
}

public extension MetricCard where Accessory == EmptyView {
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
