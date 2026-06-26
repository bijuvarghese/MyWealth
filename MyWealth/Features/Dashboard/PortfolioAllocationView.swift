import SwiftUI
import Charts

struct PortfolioAllocationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chartProgress = 0.0

    let rows: [CategoryAllocationRow]
    let portfolioTotal: Double?
    let currencyCode: String
    let totalCurrencyCode: String
    @Binding var hasAnimatedEntrance: Bool
    var onCategoryTap: ((Asset.CategoryType) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Portfolio")
                    .font(WealthMapDesignTokens.Typography.headline)

                Spacer()
            }

            Chart(rows) { row in
                SectorMark(
                    angle: .value("Amount", row.amount),
                    innerRadius: .ratio(0.62),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", row.category.rawValue))
            }
            .opacity(chartProgress)
            .frame(height: 180)
            .chartLegend(position: .bottom, alignment: .leading)
            .onAppear {
                animateChart()
            }

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    Button {
                        onCategoryTap?(row.category)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: row.category.icon)
                                .frame(width: 22)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            Text(row.category.rawValue)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                            Spacer()
                            Text(row.percentage, format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textSecondary)
                            Text(row.amount, format: .currency(code: currencyCode))
                                .font(WealthMapDesignTokens.Typography.subheadlineSemibold)
                                .monospacedDigit()
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(WealthMapDesignTokens.Typography.caption)
                                .foregroundStyle(WealthMapDesignTokens.ColorToken.textTertiary)
                        }
                        .font(WealthMapDesignTokens.Typography.subheadline)
                    }
                    .buttonStyle(.plain)
                    .disabled(onCategoryTap == nil)
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
