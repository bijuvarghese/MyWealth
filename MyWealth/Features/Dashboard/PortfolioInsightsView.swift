import SwiftUI

struct PortfolioInsightsView: View {
    let rows: [PortfolioInsightRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Insights")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: row.systemImage)
                            .foregroundStyle(sentimentColor(row.sentiment))
                            .frame(width: 22)

                        Text(row.message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(sentimentColor(row.sentiment).opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func sentimentColor(_ sentiment: PortfolioInsightRow.Sentiment) -> Color {
        switch sentiment {
        case .positive: return .green
        case .warning:  return .orange
        case .neutral:  return .accent
        }
    }
}
