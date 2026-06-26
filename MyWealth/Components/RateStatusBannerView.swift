import SwiftUI

struct RateStatusBannerView: View {
    let status: RateStatusModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.systemImage)
                .font(WealthMapDesignTokens.Typography.compactLabel)
                .foregroundStyle(iconColor)

            Text(status.message)
                .font(WealthMapDesignTokens.Typography.caption)
                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var iconColor: Color {
        switch status.style {
        case .loading:
            WealthMapDesignTokens.ColorToken.brandPrimary
        case .neutral:
            WealthMapDesignTokens.ColorToken.textSecondary
        case .warning:
            WealthMapDesignTokens.ColorToken.warning
        }
    }
}
