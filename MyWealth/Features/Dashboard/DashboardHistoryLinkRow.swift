import SwiftUI

struct DashboardHistoryLinkRow: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("View Full History")
                    .font(WealthMapDesignTokens.Typography.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(WealthMapDesignTokens.Typography.caption)
                    .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
            }
            .foregroundStyle(WealthMapDesignTokens.ColorToken.brandPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}
