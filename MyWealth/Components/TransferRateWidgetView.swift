import SwiftUI

struct TransferRateWidgetView: View {
    let rows: [TransferRateRow]
    let baseCurrency: Asset.CurrencyType

    var body: some View {
        if rows.isEmpty {
            unavailableState
        } else {
            VStack(alignment: .leading, spacing: 12) {
                header

                ForEach(rows) { row in
                    TransferRateRowView(row: row)

                    if row.id != rows.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
            Text("Transfer Rates")
                .font(WealthMapDesignTokens.Typography.headline)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
            Spacer()
        }
    }

    private var unavailableState: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right")
                .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
                .frame(width: 25)

            VStack(alignment: .leading, spacing: 3) {
                Text("Transfer Rates")
                    .font(WealthMapDesignTokens.Typography.headline)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                Text("Add display currencies in Settings")
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct TransferRateRowView: View {
    let row: TransferRateRow

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(row.baseCurrency.rawValue)
                    Image(systemName: "arrow.right")
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                    Text(row.targetCurrency.rawValue)
                }
                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                Text(row.targetCurrency.name)
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("1 \(row.baseCurrency.rawValue)")
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
                if let rate = row.rate {
                    Text("\(rate, format: .number.precision(.significantDigits(4...6))) \(row.targetCurrency.rawValue)")
                        .font(WealthMapDesignTokens.Typography.headline)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                } else {
                    Text("Unavailable")
                        .font(WealthMapDesignTokens.Typography.caption)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }
            }
        }
    }
}

