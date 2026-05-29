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
                    .font(.headline)
                Spacer()
                if useSplitData, let latest = portfolioRows.last {
                    Text(latest.assetTotal - latest.liabilityTotal,
                         format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if let latest = netWorthRows.last {
                    Text(latest.amount, format: .currency(code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.green)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.assetTotal),
                            series: .value("Series", "Assets")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.green.opacity(0.10))

                        if portfolioRows.count == 1 {
                            PointMark(
                                x: .value("Date", row.recordedAt),
                                y: .value("Amount", row.assetTotal)
                            )
                            .symbolSize(70)
                            .foregroundStyle(.green)
                        }

                        LineMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.liabilityTotal),
                            series: .value("Series", "Liabilities")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red)

                        AreaMark(
                            x: .value("Date", row.recordedAt),
                            y: .value("Amount", row.liabilityTotal),
                            series: .value("Series", "Liabilities")
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.red.opacity(0.10))

                        if portfolioRows.count == 1 {
                            PointMark(
                                x: .value("Date", row.recordedAt),
                                y: .value("Amount", row.liabilityTotal)
                            )
                            .symbolSize(70)
                            .foregroundStyle(.red)
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Assets": Color.green,
                    "Liabilities": Color.red
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
