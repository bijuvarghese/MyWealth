import SwiftUI

struct CurrencySummaryView: View {
    let currency: Asset.CurrencyType

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(currency.rawValue)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
            Text(currency.name)
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
        }
    }
}
