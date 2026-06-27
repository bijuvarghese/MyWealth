import SwiftUI
import Charts

struct LiabilityAllocationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartProgress = 0.0

    let rows: [LiabilityAllocationRow]
    let currencyCode: String
    @Binding var hasAnimatedEntrance: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Debt Breakdown")
                .font(WealthMapDesignTokens.Typography.headline)

            Chart(rows) { row in
                SectorMark(
                    angle: .value("Amount", row.amount),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", row.category.localizedName))
            }
            .opacity(chartProgress)
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .leading)
            .onAppear {
                animateChart()
            }

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    HStack(spacing: 10) {
                        Image(systemName: row.category.icon)
                            .frame(width: 22)
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        Text(row.category.localizedName)
                        Spacer()
                        Text(row.percentage, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                        Text(row.amount, format: .currency(code: currencyCode))
                            .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                            .monospacedDigit()
                    }
                    .font(WealthMapDesignTokens.Typography.subheadline)
                }
            }
        }
    }

    private func animateChart() {
        guard !hasAnimatedEntrance else {
            chartProgress = 1
            return
        }

        hasAnimatedEntrance = true
        chartProgress = reduceMotion ? 1 : 0

        guard !reduceMotion else {
            return
        }

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.85)) {
                chartProgress = 1
            }
        }
    }
}
