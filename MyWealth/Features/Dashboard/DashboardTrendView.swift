import SwiftUI

struct DashboardTrendView: View {
    let portfolioRows: [PortfolioTrendRow]
    let netWorthRows: [NetWorthTrendRow]
    let currencyCode: String
    let onViewFullHistory: () -> Void

    var body: some View {
        VStack {
            AssetVsLiabilityTrendChartView(
                portfolioRows: portfolioRows,
                netWorthRows: netWorthRows,
                currencyCode: currencyCode
            )
            Divider()
            DashboardHistoryLinkRow(onTap: onViewFullHistory)
        }
    }
}
