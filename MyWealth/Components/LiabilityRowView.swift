import SwiftUI

struct LiabilityRowView: View {
    let liability: Liability

    var body: some View {
        HStack {
            Image(systemName: liability.displayCategory.icon)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.danger)
                .frame(width: 25)

            VStack(alignment: .leading) {
                Text(liability.displayName)
                    .font(WealthMapDesignTokens.Typography.headline)

                HStack {
                    Text(liability.displayAmount, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                    Text(liability.displayCurrency.rawValue)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                }

                Text(liability.displayCategory.localizedName)
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.inactive)
            }

            Spacer()
        }
    }
}
