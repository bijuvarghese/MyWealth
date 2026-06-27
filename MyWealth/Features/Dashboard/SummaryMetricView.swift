import SwiftUI

struct SummaryMetricView: View {
    let title: String
    let systemImage: String
    let amount: Double?
    let currencyCode: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(AppLocalization.string(title, fallback: title))
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)

                if let amount {
                    Text(amount, format: .currency(code: currencyCode))
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                } else {
                    Text("Unavailable")
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
