import SwiftUI

struct AssetHistoryListView: View {
    let rows: [AssetHistoryRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Values")
                .font(WealthMapDesignTokens.Typography.headline)

            VStack(spacing: 10) {
                ForEach(rows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.assetName.isEmpty ? "Unnamed Asset" : row.assetName)
                                .font(WealthMapDesignTokens.Typography.subheadlineMedium)
                            Text(row.recordedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(row.amount, format: .currency(code: row.currencyCode.isEmpty ? "USD" : row.currencyCode))
                                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                                .monospacedDigit()
                            Text(row.categoryName)
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
