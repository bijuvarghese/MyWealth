import SwiftUI
import Charts

struct AssetVsLiabilityTrendChartView: View {
    let portfolioRows: [PortfolioTrendRow]
    let netWorthRows: [NetWorthTrendRow]
    let currencyCode: String

    private var useSplitData: Bool { !portfolioRows.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Net Worth")
                    .font(WealthMapDesignTokens.Typography.headline)
                Spacer()
                if useSplitData, let latest = portfolioRows.last {
                    Text(latest.assetTotal - latest.liabilityTotal,
                         format: .currency(code: currencyCode))
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                } else if let latest = netWorthRows.last {
                    Text(latest.amount, format: .currency(code: currencyCode))
                        .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                }
            }

            if useSplitData {
                Chart {
                    ForEach(portfolioRows) { row in
                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.assetTotal),
                            series: .value("Series", "Assets")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.success)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.assetTotal),
                            series: .value("Series", "Assets")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.success.opacity(0.10))

                        if portfolioRows.count == 1 {
                            PointMark(
                                x: .value("Date", row.recordedAt),
                                y: .value("Amount", row.assetTotal)
                            )
                            .symbolSize(70)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.success)
                        }

                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.liabilityTotal),
                            series: .value("Series", "Liabilities")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.danger)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.liabilityTotal),
                            series: .value("Series", "Liabilities")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(WealthMapDesignTokens.ColorToken.danger.opacity(0.10))

                        if portfolioRows.count == 1 {
                            PointMark(
                                x: .value("Date", row.recordedAt),
                                y: .value("Amount", row.liabilityTotal)
                            )
                            .symbolSize(70)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.danger)
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Assets": WealthMapDesignTokens.ColorToken.success,
                    "Liabilities": WealthMapDesignTokens.ColorToken.danger
                ])
                .frame(height: 150)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .chartYAxis { AxisMarks(position: .leading) }
            } else {
                Chart(netWorthRows) { row in
                    if netWorthRows.count == 1 {
                        PointMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Net Worth", row.amount)
                        )
                        .symbolSize(70)
                        .foregroundStyle(.blue)
                    } else {
                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Net Worth", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Net Worth", row.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.blue.opacity(0.12))
                    }
                }
                .frame(height: 150)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .chartYAxis { AxisMarks(position: .leading) }
            }
        }
    }
}
