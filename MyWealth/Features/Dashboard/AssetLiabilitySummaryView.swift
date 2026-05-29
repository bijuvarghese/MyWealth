import SwiftUI

struct AssetLiabilitySummaryView: View {
    let assetTotal: Double?
    let liabilityTotal: Double?
    let netWorthTotal: Double?
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                SummaryMetricView(
                    title: "Assets",
                    systemImage: "plus.circle.fill",
                    amount: assetTotal,
                    currencyCode: currencyCode,
                    tint: .green
                )

                Divider()
                    .frame(height: 42)

                SummaryMetricView(
                    title: "Liabilities",
                    systemImage: "minus.circle.fill",
                    amount: liabilityTotal,
                    currencyCode: currencyCode,
                    tint: .red
                )
            }
            .padding(.horizontal, 12)

            HStack(alignment: .center, spacing: 2) {
                Text("Net Worth")
                Spacer()
                amountText(netWorthTotal)
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.yellow)
            .clipShape(.rect(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
        }
    }

    @ViewBuilder
    private func amountText(_ amount: Double?) -> some View {
        if let amount {
            Text(amount, format: .currency(code: currencyCode))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        } else {
            Text("Unavailable")
                .foregroundStyle(.secondary)
        }
    }
}
